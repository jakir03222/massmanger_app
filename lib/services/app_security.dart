import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-level security: screenshot block (Android), idle session lock.
class AppSecurity with WidgetsBindingObserver {
  AppSecurity._();
  static final AppSecurity instance = AppSecurity._();

  static const _channel = MethodChannel('massmanager/security');
  static const _prefsLastActive = 'security_last_active_ms';

  /// After this idle time, force re-auth (default 30 minutes).
  static const idleTimeout = Duration(minutes: 30);

  bool _observing = false;
  VoidCallback? _onSessionExpired;

  Future<void> init({VoidCallback? onSessionExpired}) async {
    _onSessionExpired = onSessionExpired;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    await enableScreenProtection();
    await touchActivity();
  }

  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
  }

  /// Blocks screenshots / recent-apps preview on Android release builds.
  Future<void> enableScreenProtection() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'enabled': !kDebugMode});
    } on MissingPluginException {
      // Platform channel not wired (e.g. tests) — ignore.
    } catch (_) {}
  }

  Future<void> touchActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefsLastActive,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<bool> isSessionExpired() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_prefsLastActive);
    if (last == null) {
      await touchActivity();
      return false;
    }
    final idle = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(last),
    );
    return idle > idleTimeout;
  }

  Future<void> lockIfIdle() async {
    if (!await isSessionExpired()) {
      await touchActivity();
      return;
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _onSessionExpired?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(lockIfIdle());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(touchActivity());
    }
  }
}
