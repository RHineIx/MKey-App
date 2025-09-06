import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isInitialized = false;

  User? get currentUser => _user;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    _isInitialized = true;
    notifyListeners();
  }

  Future<String?> signInWithUsernameOrEmail(String usernameOrEmail, String password) async {
    try {
      String email;

      if (usernameOrEmail.contains('@')) {
        // Input is treated as an email
        email = usernameOrEmail;
      } else {
        // Input is treated as a username, look up the email in Firestore
        final querySnapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: usernameOrEmail)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          return "اسم المستخدم غير صحيح.";
        }

        final userData = querySnapshot.docs.first.data();
        email = userData['email'];
      }

      // Proceed to sign in with the determined email and provided password
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        return "البيانات المدخلة غير صحيحة.";
      }
      return e.message ?? "حدث خطأ غير معروف.";
    } catch (e) {
      return "حدث خطأ أثناء محاولة تسجيل الدخول.";
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}