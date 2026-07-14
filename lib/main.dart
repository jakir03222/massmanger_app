import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'l10n/locale_controller.dart';
import 'models/app_user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/mess_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  final localeController = LocaleController();
  await localeController.load();
  runApp(MassManagerApp(localeController: localeController));
}

class MassManagerApp extends StatelessWidget {
  const MassManagerApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final isBn = localeController.isBengali;
        return LocaleScope(
          controller: localeController,
          child: MaterialApp(
            title: isBn ? 'ম্যাস ম্যানেজার' : 'Mass Manager',
            debugShowCheckedModeBanner: false,
            locale: localeController.locale,
            supportedLocales: LocaleController.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryGreen,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: AppColors.pageBackground,
              textTheme: isBn
                  ? GoogleFonts.notoSansBengaliTextTheme()
                  : GoogleFonts.interTextTheme(),
              useMaterial3: true,
            ),
            home: const AppEntry(),
          ),
        );
      },
    );
  }
}

/// Routing after Google / Email login:
/// - signed out → LoginScreen
/// - signed in, no mess → MessSetupScreen (create / join)
/// - signed in, already in a mess → HomeScreen
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  final _authService = AuthService();
  final _userService = UserService();
  final _notificationService = NotificationService();
  bool _showSplash = true;
  String? _notifUid;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  Future<void> _ensureNotifications(String uid) async {
    if (_notifUid == uid) return;
    _notifUid = uid;
    await _notificationService.initForUser(uid);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onFinished: () {});
    }

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        final user = authSnapshot.data;
        if (user == null) {
          _notifUid = null;
          return const LoginScreen();
        }

        return FutureBuilder<AppUser>(
          key: ValueKey('ensure-${user.uid}'),
          future: _userService.ensureUserDoc(user),
          builder: (context, ensureSnapshot) {
            if (ensureSnapshot.connectionState != ConnectionState.done) {
              return const _LoadingScaffold();
            }

            if (ensureSnapshot.hasError || ensureSnapshot.data == null) {
              return const MessSetupScreen();
            }

            return StreamBuilder<AppUser?>(
              stream: _userService.watchUser(user.uid),
              builder: (context, userSnapshot) {
                final appUser = userSnapshot.data ?? ensureSnapshot.data!;
                unawaited(_ensureNotifications(user.uid));

                if (!appUser.hasMess) {
                  return const MessSetupScreen();
                }

                return const HomeScreen();
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );
  }
}
