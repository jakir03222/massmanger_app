import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/mess_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MassManagerApp());
}

class MassManagerApp extends StatelessWidget {
  const MassManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'মেস ম্যানেজার',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.pageBackground,
        textTheme: GoogleFonts.notoSansBengaliTextTheme(),
        useMaterial3: true,
      ),
      home: const AppEntry(),
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
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSplash = false);
    });
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
          return const LoginScreen();
        }

        // Ensure Firestore user doc, then route by messId.
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
