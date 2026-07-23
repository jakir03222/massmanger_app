import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'l10n/app_locale.dart';
import 'l10n/app_strings.dart';
import 'l10n/locale_controller.dart';
import 'models/app_user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/mess_setup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_security.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'theme/theme_controller.dart';
import 'widgets/splash_background.dart';
import 'widgets/splash_loading_indicator.dart';

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
  await AppSecurity.instance.init();
  final localeController = LocaleController();
  final themeController = ThemeController();
  await Future.wait([
    localeController.load(),
    themeController.load(),
  ]);
  AppLocale.bind(localeController);
  runApp(MassManagerApp(
    localeController: localeController,
    themeController: themeController,
  ));
}

class MassManagerApp extends StatelessWidget {
  const MassManagerApp({
    super.key,
    required this.localeController,
    required this.themeController,
  });

  final LocaleController localeController;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([localeController, themeController]),
      builder: (context, _) {
        final isBn = localeController.isBengali;
        return LocaleScope(
          controller: localeController,
          child: ThemeScope(
            controller: themeController,
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
              theme: themeController.buildThemeData(isBengali: isBn),
              builder: (context, child) {
                final p = themeController.palette;
                // Remount when language/theme changes so every screen
                // picks up matching text + colors (const routes otherwise stay stale).
                final appearanceKey =
                    '${localeController.locale.languageCode}-'
                    '${themeController.themeId.name}-'
                    '${themeController.customPrimary.toARGB32()}-'
                    '${themeController.customDark}';
                return KeyedSubtree(
                  key: ValueKey(appearanceKey),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: p.textDark,
                      decoration: TextDecoration.none,
                    ),
                    child: IconTheme(
                      data: IconThemeData(color: p.textDark),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
              home: const AppEntry(),
            ),
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
  bool _checkingOnboarding = true;
  bool _showOnboarding = false;
  String? _notifUid;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _ensureNotifications(String uid) async {
    if (_notifUid == uid) return;
    _notifUid = uid;
    await _notificationService.initForUser(uid);
  }

  Future<void> _afterSplash() async {
    final done = await OnboardingScreen.isDone();
    if (!mounted) return;
    setState(() {
      _showSplash = false;
      _checkingOnboarding = false;
      _showOnboarding = !done;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onFinished: () {
          unawaited(_afterSplash());
        },
      );
    }

    if (_checkingOnboarding) {
      return _BrandedLoading(message: AppStrings.of(context).loadingApp);
    }

    if (_showOnboarding) {
      return OnboardingScreen(
        onFinished: () {
          if (mounted) setState(() => _showOnboarding = false);
        },
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => unawaited(AppSecurity.instance.touchActivity()),
      child: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return _BrandedLoading(
                message: AppStrings.of(context).checkingSession);
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
                return _BrandedLoading(
                  message: AppStrings.of(context).loadingProfile,
                );
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
      ),
    );
  }
}

class _BrandedLoading extends StatelessWidget {
  const _BrandedLoading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SplashBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SplashLoadingIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                style: appFont(
                  context: context,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
