import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uni_ride/LogIn.dart';

import 'UserProfile.dart';
import 'app_storage.dart';
import 'saved_places_page.dart';
import 'ride_history_page.dart';
import 'PersonalInfo.dart';
import 'upcoming_reserve_page.dart';
import 'help_support_page.dart';
import 'report_problem_page.dart';
import 'theme_settings_page.dart';
import 'RideSelection.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class SettingsPage extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;

  const SettingsPage({
    super.key,
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String displayName = "User Name";
  String displayEmail = "user@email.com";
  String? userPhotoUrl;
  String? userPhotoPath;
  double userRating = 5.0;

  @override
  void initState() {
    super.initState();
    _initGoogle();
    _loadUserData();
  }

  // ✅ NEW (GoogleSignIn initialize)
  Future<void> _initGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    final data = await AppStorage.getUserData();

    if (!mounted) return;

    setState(() {
      displayName =
      (widget.userName != null && widget.userName!.trim().isNotEmpty)
          ? widget.userName!
          : (data['name'] ?? 'User Name');

      displayEmail =
      (widget.userEmail != null && widget.userEmail!.trim().isNotEmpty)
          ? widget.userEmail!
          : (data['email'] ?? 'user@email.com');

      userPhotoUrl =
      (widget.userPhotoUrl != null && widget.userPhotoUrl!.trim().isNotEmpty)
          ? widget.userPhotoUrl
          : null;

      userPhotoPath = data['photoPath'];
      userRating = (data['rating'] ?? 5.0).toDouble();
    });
  }

  // ✅ FIXED
  Future<void> _logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    await AppStorage.clearSession();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const UniRideLogin(),
      ),
          (route) => false,
    );
  }

  ImageProvider? _getProfileImage() {
    if (userPhotoPath != null && userPhotoPath!.trim().isNotEmpty) {
      final file = File(userPhotoPath!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    if (userPhotoUrl != null && userPhotoUrl!.trim().isNotEmpty) {
      return NetworkImage(userPhotoUrl!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? profileImage = _getProfileImage();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.text),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---- SAME UI (unchanged) ----
            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UniRideProfilePage(
                      userName: displayName,
                      userRating: userRating,
                    ),
                  ),
                );
                _loadUserData();
              },
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: AppColors.inputFill,
                      backgroundImage: profileImage,
                      child: profileImage == null
                          ? const Icon(Icons.person,
                          size: 45, color: AppColors.mutedText)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName),
                          Text(displayEmail),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Sign out",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}