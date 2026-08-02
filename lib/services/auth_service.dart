import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_sign_in_config.dart';
import '../l10n/app_locale.dart';
import '../models/app_user.dart';
import 'user_service.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    UserService? userService,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService(),
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final UserService _userService;
  final GoogleSignIn _googleSignIn;

  bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String _t(String bn, String en) => AppLocale.pick(bn, en);

  /// Best-effort profile sync. Auth already succeeded — don't block login.
  Future<AppUser> _ensureProfile(User user, {String? name}) async {
    try {
      return await _userService.ensureUserDoc(user, name: name);
    } catch (e, st) {
      debugPrint('ensureUserDoc failed after auth: $e\n$st');
      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
        name: name ?? user.displayName,
        photoUrl: user.photoURL,
        authProvider: UserService.detectAuthProvider(user),
      );
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    // Web OAuth client (client_type: 3) as serverClientId — required on Android
    // so Firebase receives a valid ID token.
    await _googleSignIn.initialize(
      serverClientId: kGoogleServerClientId,
      clientId: kIsWeb ? kGoogleServerClientId : null,
    );
    _googleInitialized = true;
  }

  Future<AppUser> signInWithGoogle() async {
    debugPrint('[GoogleAuth] ===== START =====');
    try {
      // Web: Firebase popup avoids google_sign_in_web renderButton requirement.
      if (kIsWeb) {
        debugPrint('[GoogleAuth] web → signInWithPopup');
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        final userCredential = await _auth.signInWithPopup(provider);
        final user = userCredential.user;
        if (user == null) {
          throw AuthException(
            _t('লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
                'Sign-in failed. Please try again.'),
          );
        }
        final profile = await _ensureProfile(user);
        debugPrint('[GoogleAuth] ===== SUCCESS (web) =====');
        return profile;
      }

      await _ensureGoogleInitialized();

      // Clear stale Google session so account picker always shows.
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('[GoogleAuth] signOut ignored: $e');
      }

      debugPrint('[GoogleAuth] authenticate()…');
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final idToken = account.authentication.idToken;
      debugPrint(
        '[GoogleAuth] account=${account.email} '
        'idToken=${idToken == null ? "NULL" : "len=${idToken.length}"}',
      );

      if (idToken == null || idToken.isEmpty) {
        throw AuthException(
          _t(
            'গুগল আইডি টোকেন পাওয়া যায়নি। Firebase Authentication → Google '
            'চালু আছে কি এবং Debug SHA-1 যোগ করা আছে কি?',
            'No Google ID token. Enable Google in Firebase Authentication and '
            'add your Debug SHA-1.',
          ),
        );
      }

      // accessToken is optional for Firebase Auth; request scopes best-effort.
      String? accessToken;
      try {
        final authz = await account.authorizationClient.authorizationForScopes(
          const ['email', 'profile'],
        );
        accessToken = authz?.accessToken;
        accessToken ??= (await account.authorizationClient.authorizeScopes(
          const ['email', 'profile'],
        ))
            .accessToken;
      } catch (e) {
        debugPrint('[GoogleAuth] accessToken skipped: $e');
      }

      debugPrint('[GoogleAuth] Firebase signInWithCredential…');
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthException(
          _t('লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
              'Sign-in failed. Please try again.'),
        );
      }

      final profile = await _ensureProfile(user);
      debugPrint(
        '[GoogleAuth] OK uid=${user.uid} messId=${profile.messId}',
      );
      debugPrint('[GoogleAuth] ===== SUCCESS =====');
      return profile;
    } on AuthException catch (e) {
      debugPrint('[GoogleAuth] AuthException: ${e.message}');
      rethrow;
    } on GoogleSignInException catch (e) {
      debugPrint(
        '[GoogleAuth] GoogleSignInException code=${e.code} '
        'desc=${e.description}',
      );
      throw AuthException(_mapGoogleSignInException(e));
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[GoogleAuth] FirebaseAuthException code=${e.code} '
        'message=${e.message}',
      );
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      debugPrint(
        '[GoogleAuth] FirebaseException code=${e.code} message=${e.message}',
      );
      throw AuthException(_mapFirestoreError(e));
    } catch (e, st) {
      debugPrint('[GoogleAuth] unexpected: $e\n$st');
      throw AuthException(
        _t(
          'গুগল লগইন ব্যর্থ। আবার চেষ্টা করুন অথবা ইমেইল দিয়ে লগইন করুন।',
          'Google sign-in failed. Try again or use email login.',
        ),
      );
    }
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw AuthException(_t('সঠিক ইমেইল দিন।', 'Enter a valid email.'));
    }
    if (password.isEmpty) {
      throw AuthException(_t('পাসওয়ার্ড দিন।', 'Enter your password.'));
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw AuthException(
          _t('লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
              'Sign-in failed. Please try again.'),
        );
      }
      return await _ensureProfile(user);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirestoreError(e));
    } catch (e, st) {
      debugPrint('Email sign-in unexpected error: $e\n$st');
      throw AuthException(
        _t('কিছু ভুল হয়েছে। আবার চেষ্টা করুন।',
            'Something went wrong. Please try again.'),
      );
    }
  }

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw AuthException(_t('নাম দিন।', 'Enter your name.'));
    }
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw AuthException(_t('সঠিক ইমেইল দিন।', 'Enter a valid email.'));
    }
    if (password.length < 6) {
      throw AuthException(
        _t(
          'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।',
          'Password must be at least 6 characters.',
        ),
      );
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw AuthException(
          _t('রেজিস্ট্রেশন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
              'Registration failed. Please try again.'),
        );
      }

      try {
        await user.updateDisplayName(trimmedName);
      } catch (_) {}

      return await _ensureProfile(user, name: trimmedName);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirestoreError(e));
    } catch (e, st) {
      debugPrint('Email register unexpected error: $e\n$st');
      throw AuthException(
        _t('কিছু ভুল হয়েছে। আবার চেষ্টা করুন।',
            'Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      throw AuthException(_t('সঠিক ইমেইল দিন।', 'Enter a valid email.'));
    }
    try {
      await _auth.sendPasswordResetEmail(email: trimmed);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (_) {
      throw AuthException(
        _t('রিসেট ইমেইল পাঠানো ব্যর্থ। আবার চেষ্টা করুন।',
            'Could not send reset email. Please try again.'),
      );
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }

  String _mapGoogleSignInException(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return _t(
          'গুগল লগইন বাতিল করা হয়েছে।',
          'Google sign-in was cancelled.',
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
        return _t(
          'গুগল লগইন কনফিগ ভুল (SHA-1/package)। '
          'Package: com.example.massmanager — Firebase-এ Debug SHA-1 '
          'যোগ করে নতুন google-services.json ডাউনলোড করুন।',
          'Google Sign-In config error (SHA-1/package). '
          'Package must be com.example.massmanager — add Debug SHA-1 in '
          'Firebase and re-download google-services.json.',
        );
      case GoogleSignInExceptionCode.providerConfigurationError:
        return _t(
          'Firebase Authentication → Sign-in method → Google চালু করুন।',
          'Enable Google under Firebase Authentication → Sign-in method.',
        );
      default:
        final detail = e.description?.trim();
        if (detail != null && detail.isNotEmpty) {
          return _t(
            'গুগল লগইন ব্যর্থ: $detail',
            'Google sign-in failed: $detail',
          );
        }
        return _t(
          'গুগল লগইন ব্যর্থ। ইমেইল দিয়ে চেষ্টা করুন।',
          'Google sign-in failed. Try email login.',
        );
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return _t('ইমেইল ঠিকানা সঠিক নয়।', 'Invalid email address.');
      case 'user-disabled':
        return _t(
          'এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে।',
          'This account has been disabled.',
        );
      case 'user-not-found':
        return _t(
          'এই ইমেইলে কোনো অ্যাকাউন্ট নেই। আগে রেজিস্টার করুন।',
          'No account for this email. Please register first.',
        );
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return _t('ইমেইল বা পাসওয়ার্ড ভুল।', 'Wrong email or password.');
      case 'email-already-in-use':
        return _t(
          'এই ইমেইলে ইতিমধ্যে অ্যাকাউন্ট আছে। লগইন করুন।',
          'An account already exists for this email. Please sign in.',
        );
      case 'weak-password':
        return _t(
          'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।',
          'Password must be at least 6 characters.',
        );
      case 'network-request-failed':
        return _t(
          'ইন্টারনেট সংযোগ নেই। আবার চেষ্টা করুন।',
          'No internet connection. Please try again.',
        );
      case 'too-many-requests':
        return _t(
          'অনেকবার চেষ্টা হয়েছে। একটু পরে আবার চেষ্টা করুন।',
          'Too many attempts. Please try again later.',
        );
      case 'operation-not-allowed':
        return _t(
          'এই লগইন পদ্ধতি Firebase-এ চালু নেই। Authentication → Sign-in method চেক করুন।',
          'This sign-in method is disabled. Enable it in Firebase Authentication → Sign-in method.',
        );
      case 'account-exists-with-different-credential':
        return _t(
          'এই ইমেইলে অন্য পদ্ধতিতে অ্যাকাউন্ট আছে (Google/ইমেইল)।',
          'An account exists with a different sign-in method for this email.',
        );
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return _t(
          'গুগল লগইন বাতিল করা হয়েছে।',
          'Google sign-in was cancelled.',
        );
      default:
        return e.message ??
            _t('কিছু ভুল হয়েছে। আবার চেষ্টা করুন।',
                'Something went wrong. Please try again.');
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
      case 'permission-denied':
        return _t(
          'ডেটাবেস চালু নেই বা অনুমতি নেই। একটু পরে আবার চেষ্টা করুন।',
          'Database unavailable or permission denied. Try again later.',
        );
      default:
        return _t(
          'ডেটাবেস সংযোগ ব্যর্থ। একটু পরে আবার চেষ্টা করুন।',
          'Database connection failed. Please try again later.',
        );
    }
  }
}
