import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LogIn.dart';

class LogoutHelper {

  static Future<void> logout(BuildContext context) async {
    await _doLogout();
  }

  static Future<void> logoutWithConfirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _doLogout();
  }

  static Future<void> _doLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint("Prefs clear error: $e");
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint("Google signOut error: $e");
    }

    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: UniRideLogin(),
      ),
    );
  }
}