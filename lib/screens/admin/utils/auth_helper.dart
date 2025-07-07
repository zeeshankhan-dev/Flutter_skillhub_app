import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/login_screen.dart';


Future<void> logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();

  // Navigate to login screen and remove previous screens
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
  );
}
