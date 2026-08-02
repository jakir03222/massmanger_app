import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local reminders for meal cutoff, bazaar duty, and month-end settle-up.
class ReminderService {
  ReminderService() : _plugin = FlutterLocalNotificationsPlugin();

  static const _prefsEnabled = 'reminders_enabled_v1';
  static const _channelId = 'mass_manager_reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    } catch (_) {
      // Fall back to already-initialized local/UTC.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Reminders',
        description: 'Meal, bazaar and settle-up reminders',
        importance: Importance.defaultImportance,
      ),
    );
    _ready = true;
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, value);
    if (!value) {
      await _plugin.cancelAll();
    } else {
      await scheduleDefaults();
    }
  }

  Future<void> scheduleDefaults() async {
    if (kIsWeb) return;
    await init();
    if (!await isEnabled()) return;

    // Daily meal request reminder at 17:30 local.
    await _plugin.zonedSchedule(
      id: 1001,
      title: 'Mass Manager',
      body: 'Meal request reminder — add tonight’s meals if needed.',
      scheduledDate: _nextInstanceOf(17, 30),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Reminders',
          channelDescription: 'Meal, bazaar and settle-up reminders',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Month-end settle reminder on day 28 at 10:00.
    await _plugin.zonedSchedule(
      id: 1002,
      title: 'Mass Manager',
      body: 'Settle-up reminder — check payments for this month.',
      scheduledDate: _nextMonthDay(28, 10, 0),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Reminders',
          channelDescription: 'Meal, bazaar and settle-up reminders',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    // Morning bazaar-duty nudge at 08:00.
    await _plugin.zonedSchedule(
      id: 1003,
      title: 'Mass Manager',
      body: 'Bazaar duty reminder — check today’s bazaar schedule.',
      scheduledDate: _nextInstanceOf(8, 0),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Reminders',
          channelDescription: 'Meal, bazaar and settle-up reminders',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextMonthDay(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled =
          tz.TZDateTime(tz.local, now.year, now.month + 1, day, hour, minute);
    }
    return scheduled;
  }
}
