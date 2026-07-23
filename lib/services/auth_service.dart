import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize(serverClientId: kGoogleServerClientId);
    _googleInitialized = true;
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthException(
          _t(
            'গুগল লগইন ব্যর্থ হয়েছে। অ্যাপে গুগল লগইন সেটআপ সম্পূর্ণ আছে কি?',
            'Google sign-in failed. Is Google Sign-In set up in the app?',
          ),
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthException(
          _t('লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
              'Sign-in failed. Please try again.'),
        );
      }

      return await _userService.ensureUserDoc(user);
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException(
          _t('গুগল লগইন বাতিল করা হয়েছে।', 'Google sign-in was cancelled.'),
        );
      }
      throw AuthException(
        _t(
          'গুগল লগইন ব্যর্থ: ${e.description ?? e.code.name}',
          'Google sign-in failed: ${e.description ?? e.code.name}',
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirestoreError(e));
    } catch (_) {
      throw AuthException(
        _t('কিছু ভুল হয়েছে। আবার চেষ্টা করুন।',
            'Something went wrong. Please try again.'),
      );
    }
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw AuthException(
          _t('লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
              'Sign-in failed. Please try again.'),
        );
      }
      return await _userService.ensureUserDoc(user);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirestoreError(e));
    } catch (_) {
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
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw AuthException(
          _t('রেজিস্ট্রেশন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
              'Registration failed. Please try again.'),
        );
      }

      await user.updateDisplayName(name.trim());
      return await _userService.ensureUserDoc(user, name: name.trim());
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirestoreError(e));
    } catch (_) {
      throw AuthException(
        _t('কিছু ভুল হয়েছে। আবার চেষ্টা করুন।',
            'Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      throw AuthException(
        _t('সঠিক ইমেইল দিন।', 'Enter a valid email.'),
      );
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
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out failures; still clear Firebase session.
    }
    await _auth.signOut();
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
          'এই ইমেইলে কোনো অ্যাকাউন্ট নেই।',
          'No account found for this email.',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return _t('ইমেইল বা পাসওয়ার্ড ভুল।', 'Wrong email or password.');
      case 'email-already-in-use':
        return _t(
          'এই ইমেইলে ইতিমধ্যে অ্যাকাউন্ট আছে।',
          'An account already exists for this email.',
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
          'এই লগইন পদ্ধতি চালু নেই। অ্যাডমিন সেটিংস চেক করুন।',
          'This sign-in method is disabled. Check admin settings.',
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
