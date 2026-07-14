import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background/terminated: OS shows notification payload if present.
}

/// FCM token + in-app notification inbox + local banners.
class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inboxSub;
  StreamSubscription<String>? _tokenSub;
  String? _uid;
  final Set<String> _seenIds = {};

  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  Future<void> initForUser(String uid) async {
    if (_uid == uid) return;
    await dispose();
    _uid = uid;

    await _initLocalPlugin();
    await _requestPermission();
    await _saveToken(uid);
    _tokenSub = _messaging.onTokenRefresh.listen((token) {
      _persistToken(uid, token);
    });

    FirebaseMessaging.onMessage.listen((msg) {
      final title = msg.notification?.title ?? msg.data['title'] ?? 'Mass Manager';
      final body = msg.notification?.body ?? msg.data['body'] ?? '';
      if (body.toString().isNotEmpty) {
        _showLocal(title.toString(), body.toString());
      }
    });

    // In-app + cross-device inbox (works without Cloud Functions).
    _inboxSub = _inbox(uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final id = change.doc.id;
        if (_seenIds.contains(id)) continue;
        _seenIds.add(id);
        final data = change.doc.data();
        if (data == null) continue;
        // Skip stale docs from first snapshot burst older than 2 minutes.
        final created = data['createdAt'];
        if (created is Timestamp) {
          final age = DateTime.now().difference(created.toDate());
          if (age > const Duration(minutes: 2)) continue;
        }
        final title = (data['title'] as String?) ?? 'Mass Manager';
        final body = (data['body'] as String?) ?? '';
        if (body.isNotEmpty) {
          _showLocal(title, body);
        }
      }
    });
  }

  Future<void> dispose() async {
    await _inboxSub?.cancel();
    await _tokenSub?.cancel();
    _inboxSub = null;
    _tokenSub = null;
    _uid = null;
    _seenIds.clear();
  }

  Future<void> _initLocalPlugin() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    if (!kIsWeb && Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'mass_manager',
          'Mass Manager',
          description: 'Meal, market and bill updates',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (!kIsWeb && Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _saveToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _persistToken(uid, token);
      }
    } catch (_) {
      // Emulator / missing Push entitlement — ignore.
    }
  }

  Future<void> _persistToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showLocal(String title, String body) async {
    await _local.show(
      id: title.hashCode ^ body.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'mass_manager',
          'Mass Manager',
          channelDescription: 'Meal, market and bill updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Write inbox docs for recipients (live on their devices).
  Future<void> notifyUsers({
    required List<String> uids,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    final unique = uids.toSet().where((u) => u.isNotEmpty).toList();
    if (unique.isEmpty) return;
    final batch = _firestore.batch();
    for (final uid in unique) {
      final ref = _inbox(uid).doc();
      batch.set(ref, {
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> notifyAdminsOfMess({
    required String messId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    final snap = await _firestore
        .collection('messes')
        .doc(messId)
        .collection('members')
        .get();
    final adminUids = snap.docs
        .where((d) {
          final role = d.data()['role'] as String? ?? 'member';
          return role == 'admin' || role == 'super_admin';
        })
        .map((d) => d.id)
        .toList();
    await notifyUsers(
      uids: adminUids,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }
}
