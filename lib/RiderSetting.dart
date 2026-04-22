import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uni_ride/LogIn.dart';

import 'services/auth_api_service.dart';

import 'RiderProfile.dart';
import 'app_storage.dart';
import 'saved_places_page.dart';
import 'ride_history_page.dart';
import 'PersonalInfo.dart';
import 'upcoming_reserve_page.dart';
import 'help_support_page.dart';
import 'report_problem_page.dart';
import 'RideSelection.dart';
import 'RegisteredVehicles.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class RiderSettingsPage extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;

  const RiderSettingsPage({
    super.key,
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
  });

  @override
  State<RiderSettingsPage> createState() => _RiderSettingsPageState();
}

class _RiderSettingsPageState extends State<RiderSettingsPage> {
  String displayName = "User Name";
  String displayEmail = "user@email.com";
  String? userPhotoUrl;
  String? userPhotoPath;
  final AuthApiService _authApiService = AuthApiService();
  bool isLoading = true;
  double userRating = 5.0;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
    _loadUserData();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final localData = await AppStorage.getUserData();
      final response = await _authApiService.getRiderSettingsSummary();
      final backendData = response['data'] ?? {};

      if (!mounted) return;

      setState(() {
        displayName =
        (widget.userName != null && widget.userName!.trim().isNotEmpty)
            ? widget.userName!
            : ((backendData['fullName'] ?? localData['name']) ?? 'User Name');

        displayEmail =
        (widget.userEmail != null && widget.userEmail!.trim().isNotEmpty)
            ? widget.userEmail!
            : ((backendData['email'] ?? localData['email']) ?? 'user@email.com');

        userPhotoUrl =
        (widget.userPhotoUrl != null && widget.userPhotoUrl!.trim().isNotEmpty)
            ? widget.userPhotoUrl
            : backendData['profilePicture'];

        userPhotoPath = localData['photoPath'];

        final ratingValue = backendData['rating'] ?? localData['rating'] ?? 5.0;
        userRating = (ratingValue as num).toDouble();

        isLoading = false;
      });
    } catch (_) {
      final localData = await AppStorage.getUserData();

      if (!mounted) return;

      setState(() {
        displayName =
        (widget.userName != null && widget.userName!.trim().isNotEmpty)
            ? widget.userName!
            : (localData['name'] ?? 'User Name');

        displayEmail =
        (widget.userEmail != null && widget.userEmail!.trim().isNotEmpty)
            ? widget.userEmail!
            : (localData['email'] ?? 'user@email.com');

        userPhotoUrl =
        (widget.userPhotoUrl != null && widget.userPhotoUrl!.trim().isNotEmpty)
            ? widget.userPhotoUrl
            : null;

        userPhotoPath = localData['photoPath'];
        userRating = ((localData['rating'] ?? 5.0) as num).toDouble();
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authApiService.logout();
    } catch (_) {}

    try {
      await AppStorage.clearSession();
    } catch (_) {}

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const UniRideLogin(),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RiderProfile(
                      userName: displayName,
                      userRating: userRating,
                    ),
                  ),
                );

                _loadUserData();
              },
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Rating: ${userRating.toStringAsFixed(1)}",
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 0.8, color: AppColors.border),
            _buildSettingItem(
              icon: Icons.edit_outlined,
              title: "Edit profile",
              subtitle: "Update your personal information",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalInformationPage(),
                  ),
                );
                _loadUserData();
              },
            ),
            _buildSettingItem(
              icon: Icons.directions_bike_outlined,
              title: "Add another vehicle",
              subtitle: "Register a new vehicle as rider",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UniRideSelectionScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.two_wheeler_outlined,
              title: "See Registered Vehicle",
              subtitle: "View your registered vehicles",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisteredVehiclesPage(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.home_outlined,
              title: "Saved places",
              subtitle: "Home, Campus, Hall",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavedPlacesPage(
                      googleApiKey: 'AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI',
                      initialPosition: const LatLng(23.8103, 90.4125),
                    ),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.history,
              title: "Ride history",
              subtitle: "See your completed rides",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RideHistoryPage(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.calendar_today_outlined,
              title: "Upcoming reserve",
              subtitle: "Manage active booking / upcoming reserve",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpcomingReservePage(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.help_outline,
              title: "Help & support",
              subtitle: "Get help for your problems",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportPage(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.report_problem_outlined,
              title: "Report a problem",
              subtitle: "Tell us what went wrong",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportProblemPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Sign out",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.primary,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}