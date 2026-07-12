import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_sign_in_config.dart';
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
          'গুগল লগইন ব্যর্থ হয়েছে। অ্যাপে গুগল লগইন সেটআপ সম্পূর্ণ আছে কি?',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthException('লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।');
      }

      return await _userService.ensureUserDoc(user);
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('গুগল লগইন বাতিল করা হয়েছে।');
      }
      throw AuthException('গুগল লগইন ব্যর্থ: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirestoreError(e));
    } catch (_) {
      throw AuthException('কিছু ভুল হয়েছে। আবার চেষ্টা করুন।');
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
        throw AuthException('লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।');
      }
      return await _userService.ensureUserDoc(user);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirestoreError(e));
    } catch (_) {
      throw AuthException('কিছু ভুল হয়েছে। আবার চেষ্টা করুন।');
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
        throw AuthException('রেজিস্ট্রেশন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।');
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
      throw AuthException('কিছু ভুল হয়েছে। আবার চেষ্টা করুন।');
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
        return 'ইমেইল ঠিকানা সঠিক নয়।';
      case 'user-disabled':
        return 'এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে।';
      case 'user-not-found':
        return 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই।';
      case 'wrong-password':
      case 'invalid-credential':
        return 'ইমেইল বা পাসওয়ার্ড ভুল।';
      case 'email-already-in-use':
        return 'এই ইমেইলে ইতিমধ্যে অ্যাকাউন্ট আছে।';
      case 'weak-password':
        return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।';
      case 'network-request-failed':
        return 'ইন্টারনেট সংযোগ নেই। আবার চেষ্টা করুন।';
      case 'too-many-requests':
        return 'অনেকবার চেষ্টা হয়েছে। একটু পরে আবার চেষ্টা করুন।';
      case 'operation-not-allowed':
        return 'এই লগইন পদ্ধতি চালু নেই। অ্যাডমিন সেটিংস চেক করুন।';
      default:
        return e.message ?? 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
      case 'permission-denied':
        return 'ডেটাবেস চালু নেই বা অনুমতি নেই। একটু পরে আবার চেষ্টা করুন।';
      default:
        return 'ডেটাবেস সংযোগ ব্যর্থ। একটু পরে আবার চেষ্টা করুন।';
    }
  }
}
