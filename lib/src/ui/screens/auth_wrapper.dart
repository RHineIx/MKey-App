import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/services/auth_service.dart';
import 'package:rhineix_mkey_app/src/services/fcm_service.dart';
import 'package:rhineix_mkey_app/src/services/firestore_service.dart';
import 'package:rhineix_mkey_app/src/ui/screens/login_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/main_shell.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to auth changes to save the FCM token upon login
    context.watch<AuthService>().addListener(_handleAuthStateChange);
  }

  @override
  void dispose() {
    context.read<AuthService>().removeListener(_handleAuthStateChange);
    super.dispose();
  }

  void _handleAuthStateChange() {
    final authService = context.read<AuthService>();
    if (authService.currentUser != null) {
      // User has just logged in, get the token and save it.
      _saveTokenForUser(authService.currentUser!.uid);
    }
  }

  Future<void> _saveTokenForUser(String uid) async {
    final fcmService = context.read<FCMService>();
    // Use a FirestoreService instance that is guaranteed to have the correct UID
    final firestoreService = FirestoreService(uid);

    final token = await fcmService.getFCMToken();
    if (token != null && firestoreService.isReady) {
      await firestoreService.saveUserFCMToken(token);
      fcmService.onTokenRefresh(firestoreService.saveUserFCMToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // Show a loading indicator until the auth state is initialized
    if (!authService.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authService.currentUser != null) {
      return const MainShell();
    } else {
      return const LoginScreen();
    }
  }
}