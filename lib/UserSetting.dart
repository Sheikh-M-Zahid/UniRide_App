import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uni_ride/LogIn.dart';

import 'UserProfile.dart';
import 'app_storage.dart';
import 'saved_places_page.dart';
import 'services/auth_api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  static const String googleApiKey = "AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI";

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
  final AuthApiService _authApiService = AuthApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initGoogle();
    _loadUserData();
  }

  Future<void> _initGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authApiService.getSettingsSummary();
      final data = response['data'] ?? {};

      if (!mounted) return;

      setState(() {
        displayName = ((data['name'] ?? '').toString().trim().isNotEmpty)
            ? data['name'].toString().trim()
            : ((widget.userName ?? '').trim().isNotEmpty
            ? widget.userName!.trim()
            : 'User Name');

        displayEmail = ((data['email'] ?? '').toString().trim().isNotEmpty)
            ? data['email'].toString().trim()
            : ((widget.userEmail ?? '').trim().isNotEmpty
            ? widget.userEmail!.trim()
            : 'user@email.com');

        final profilePicture = (data['profile_picture'] ?? '').toString().trim();

        userPhotoUrl = profilePicture.isNotEmpty
            ? _authApiService.getFullImageUrl(profilePicture)
            : ((widget.userPhotoUrl ?? '').trim().isNotEmpty
            ? widget.userPhotoUrl!.trim()
            : null);

        userPhotoPath = null;

        final dynamic ratingValue = data['rating'];
        if (ratingValue is num) {
          userRating = ratingValue.toDouble();
        } else {
          userRating = double.tryParse(ratingValue.toString()) ?? 5.0;
        }

        _isLoading = false;
      });
    } catch (e) {
      final data = await AppStorage.getUserData();

      if (!mounted) return;

      setState(() {
        displayName =
        ((data['name'] ?? '').toString().trim().isNotEmpty)
            ? data['name'].toString().trim()
            : 'User Name';

        displayEmail =
        ((data['email'] ?? '').toString().trim().isNotEmpty)
            ? data['email'].toString().trim()
            : 'user@email.com';

        userPhotoUrl =
        ((data['photoUrl'] ?? '').toString().trim().isNotEmpty)
            ? data['photoUrl'].toString().trim()
            : null;

        userPhotoPath =
        ((data['photoPath'] ?? '').toString().trim().isNotEmpty)
            ? data['photoPath'].toString().trim()
            : null;

        final dynamic ratingValue = data['rating'];
        if (ratingValue is num) {
          userRating = ratingValue.toDouble();
        } else {
          userRating = 5.0;
        }

        _isLoading = false;
      });
    }
  }

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

  Future<void> _openSavedPlaces() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedPlacesPage(
          googleApiKey: "AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI",
          initialPosition: const LatLng(23.8103, 90.4125),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (userPhotoPath != null && userPhotoPath!.isNotEmpty) {
      final file = File(userPhotoPath!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    if (userPhotoUrl != null && userPhotoUrl!.isNotEmpty) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
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
                await _loadUserData();
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
                          ? const Icon(
                        Icons.person,
                        size: 45,
                        color: AppColors.mutedText,
                      )
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