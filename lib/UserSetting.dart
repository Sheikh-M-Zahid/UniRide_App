import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'UserProfile.dart';
import 'app_storage.dart';
import 'saved_places_page.dart';
import 'RideSelection.dart';
import 'WalletPage.dart';
import 'help_support_page.dart';
import 'report_problem_page.dart';
import 'services/auth_api_service.dart';
import 'logout_helper.dart';
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
  String riderStatus = 'no';
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
        final firstName = (data['first_name'] ?? '').toString().trim();
        final lastName = (data['last_name'] ?? '').toString().trim();
        final apiFullName = (data['name'] ?? '').toString().trim();
        final combinedName = '$firstName $lastName'.trim();

        displayName = apiFullName.isNotEmpty
            ? apiFullName
            : (combinedName.isNotEmpty
            ? combinedName
            : ((widget.userName ?? '').trim().isNotEmpty
            ? widget.userName!.trim()
            : 'User Name'));

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

        riderStatus = (data['rider'] ?? 'no').toString().toLowerCase();

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
    await LogoutHelper.logoutWithConfirm(context);
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = AppColors.primary,
    VoidCallback? onTap,
    Color textColor = AppColors.text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildRiderStatusCard() {
    final bool isRider = riderStatus == 'yes';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: isRider
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.verified_user, color: AppColors.secondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rider Account Already Created',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'You have already created a rider account. If you want to share rides, please log out from the passenger profile and log in again as a rider.',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
            ),
          ),
        ],
      )
          : InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UniRideSelectionScreen(),
            ),
          );
        },
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.two_wheeler, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign Up as a Rider',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create your rider account to start sharing rides.',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                              fontSize: 14,
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            children: [
                              const Icon(Icons.star, size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                userRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildSettingsItem(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'View and update your profile',
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
            ),
            _buildRiderStatusCard(),

            _buildSettingsItem(
              icon: Icons.place_outlined,
              title: 'Saved Places',
              subtitle: 'Home, Campus, Hostel locations',
              onTap: _openSavedPlaces,
            ),

            _buildSettingsItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet',
              subtitle: 'View due balance and payment info',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WalletPage(
                      userRole: WalletUserRole.passenger,
                    ),
                  ),
                );
              },
            ),

            _buildSettingsItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help or submit your issue',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportPage(),
                  ),
                );
              },
            ),

            _buildSettingsItem(
              icon: Icons.report_problem_outlined,
              title: 'Report Problem',
              subtitle: 'Send a report to admin',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportProblemPage(),
                  ),
                );
              },
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                onTap: () async {
                  await _logout();
                },
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sign out',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
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
}