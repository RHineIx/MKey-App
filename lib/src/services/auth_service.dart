import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _initialized = false;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  User? get currentUser => _currentUser;
  bool get isInitialized => _initialized;

  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    _initialized = true;
    notifyListeners();
  }

  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      } else {
        return 'حدث خطأ غير متوقع.';
      }
    } catch (e) {
      return 'حدث خطأ غير متوقع.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}