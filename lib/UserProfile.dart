import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_api_service.dart';
import 'UserHome.dart';
import 'UserSetting.dart';
import 'UserOffer.dart';
import 'UserActivity.dart';
import 'UserServices.dart';
import 'PersonalInfo.dart';
import 'WalletPage.dart';
import 'HelpSupport.dart';
import 'SafetyPage.dart';
import 'SecurityPage.dart';
import 'PrivacyDataPage.dart';

void main() => runApp(
  const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UniRideProfilePage(),
  ),
);

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class UniRideProfilePage extends StatefulWidget {
  final String? userName;
  final double userRating;

  const UniRideProfilePage({
    super.key,
    this.userName,
    this.userRating = 5.0,
  });

  @override
  State<UniRideProfilePage> createState() => _UniRideProfilePageState();
}

class _UniRideProfilePageState extends State<UniRideProfilePage> {
  int _selectedIndex = 4;
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  final AuthApiService _authApiService = AuthApiService();

  String _displayName = "User Name";
  double _displayRating = 5.0;

  int _profileCompletion = 0;

  String? _gender;
  String? _emergencyContactNumber;
  String? _universityEmail;
  String? _dateOfBirth;
  String? _secondaryPhoneNumber;

  DateTime? _profileCompletedAt;
  bool _isProfileDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeProfilePage();
  }

  bool _isFilled(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> _loadBasicUserInfoFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString('user_name') ?? '';
    final savedImagePath = prefs.getString('profile_image_path');

    if (savedName.trim().isNotEmpty) {
      _displayName = savedName.trim();
    }

    if (savedImagePath != null && savedImagePath.isNotEmpty) {
      final file = File(savedImagePath);
      if (file.existsSync()) {
        _profileImage = file;
      }
    }
  }

  Future<void> _initializeProfilePage() async {
    await _loadBasicUserInfoFromPrefs();
    await _fetchProfileFromDatabase();
    await _loadProfileCompletionData();
  }

  Future<void> _fetchProfileFromDatabase() async {
    try {
      final response = await _authApiService.getMyProfile();
      final data = response['data'] ?? {};

      final fullName = (data['fullName'] ?? '').toString().trim();
      final firstName = (data['firstName'] ?? '').toString().trim();
      final lastName = (data['lastName'] ?? '').toString().trim();
      final combinedName = ('$firstName $lastName').trim();

      if (!mounted) return;

      setState(() {
        _displayName = fullName.isNotEmpty
            ? fullName
            : (combinedName.isNotEmpty ? combinedName : _displayName);
        _displayRating = double.tryParse('${data['rating'] ?? 5}') ?? 5.0;

        final profilePicture = data['profilePicture']?.toString();
        _profileImageUrl = (profilePicture != null && profilePicture.isNotEmpty)
            ? _authApiService.getFullImageUrl(profilePicture)
            : null;

        _gender = data['gender']?.toString();
        _emergencyContactNumber = data['emergencyContactNumber']?.toString();
        _universityEmail = data['universityEmail']?.toString();
        _dateOfBirth = data['dateOfBirth']?.toString();
        _secondaryPhoneNumber = data['secondaryPhoneNumber']?.toString();
        final completedAtRaw = data['profileCompletedAt']?.toString();
        _profileCompletedAt =
        (completedAtRaw != null && completedAtRaw.isNotEmpty)
            ? DateTime.tryParse(completedAtRaw)
            : null;
        _profileCompletion = int.tryParse('${data['profileCompletion'] ?? 0}') ?? 0;
      });
    } catch (e) {
      debugPrint('Failed to load profile from database: $e');
    }
  }

  int _calculateProfileCompletion(String displayName) {
    int score = 0;

    // Name = 15%
    if (displayName.trim().isNotEmpty && displayName != "User Name") {
      score += 15;
    }

    // Profile photo = 20%
    if (_profileImage != null) {
      score += 20;
    }

    // Gender = 10%
    if (_isFilled(_gender)) {
      score += 10;
    }

    // Emergency Contact = 15%
    if (_isFilled(_emergencyContactNumber)) {
      score += 15;
    }

    // University Email = 15%
    if (_isFilled(_universityEmail)) {
      score += 15;
    }

    // Date of Birth = 15%
    if (_isFilled(_dateOfBirth)) {
      score += 15;
    }

    // Secondary Phone Number = 10%
    if (_isFilled(_secondaryPhoneNumber)) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  Future<void> _loadProfileCompletionData() async {
    final prefs = await SharedPreferences.getInstance();

    final imagePath = prefs.getString('profile_image_path');
    final completedAtMillis = prefs.getInt('profile_completed_at');

    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        _profileImage = file;
      }
    }

    if (completedAtMillis != null) {
      _profileCompletedAt =
          DateTime.fromMillisecondsSinceEpoch(completedAtMillis);
    }

    if (_profileCompletion == 0) {
      _profileCompletion = _calculateProfileCompletion(_displayName);
    }

    if (_profileCompletion < 100) {
      _profileCompletedAt = null;
    }

    if (mounted) {
      setState(() {
        _isProfileDataLoaded = true;
      });
    }
  }

  Future<void> _saveProfileCompletionData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('profile_gender', _gender ?? '');
    await prefs.setString(
      'profile_emergency_contact',
      _emergencyContactNumber ?? '',
    );
    await prefs.setString('profile_university_email', _universityEmail ?? '');
    await prefs.setString('profile_dob', _dateOfBirth ?? '');
    await prefs.setString(
      'profile_secondary_phone',
      _secondaryPhoneNumber ?? '',
    );

    if (_profileImage != null) {
      await prefs.setString('profile_image_path', _profileImage!.path);
    } else {
      await prefs.remove('profile_image_path');
    }

    if (_profileCompletion == 0) {
      _profileCompletion = _calculateProfileCompletion(_displayName);
    }

    if (_profileCompletion == 100) {
      _profileCompletedAt ??= DateTime.now();
      await prefs.setInt(
        'profile_completed_at',
        _profileCompletedAt!.millisecondsSinceEpoch,
      );
    } else {
      _profileCompletedAt = null;
      await prefs.remove('profile_completed_at');
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool get _shouldShowCompleteProfileCard {
    if (!_isProfileDataLoaded) return false;

    if (_profileCompletion < 100) return true;

    if (_profileCompletedAt == null) return true;

    final daysPassed = DateTime.now().difference(_profileCompletedAt!).inDays;
    return daysPassed < 30;
  }

  String get _profileSubtitle {
    if (_profileCompletion >= 100) {
      final int remainingDays = _profileCompletedAt == null
          ? 30
          : (30 - DateTime.now().difference(_profileCompletedAt!).inDays)
          .clamp(0, 30);

      return "Your profile is fully completed. This message will disappear in $remainingDays day${remainingDays == 1 ? '' : 's'}.";
    }

    return "Complete your personal information and profile photo to enjoy a better UniRide experience.";
  }

  Future<void> _pickProfileImage() async {
    try {
      PermissionStatus status;

      if (Platform.isIOS) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }

      if (status.isGranted || status.isLimited) {
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          setState(() {
            _profileImage = File(pickedFile.path);
          });
          await _saveProfileCompletionData();
        }
      } else if (status.isPermanentlyDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gallery permission permanently denied. Please enable it from app settings.',
            ),
          ),
        );
        await openAppSettings();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery permission denied.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
        ),
      );
    }
  }

  Future<void> _openPersonalInfoPage() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalInformationPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _gender = result['gender']?.toString();
        _emergencyContactNumber =
            result['emergencyContactNumber']?.toString();
        _universityEmail = result['universityEmail']?.toString();
        _dateOfBirth = result['dateOfBirth']?.toString();
        _secondaryPhoneNumber =
            result['secondaryPhoneNumber']?.toString();
      });

      await _saveProfileCompletionData();
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UniRideHomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ServicesPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ActivityPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OffersPage(),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _displayName;
    final double displayRating = _displayRating;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),

              // ================= PROFILE IMAGE =================
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.inputFill,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!) as ImageProvider
                        : null),
                    child: _profileImage == null
                        ? const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.mutedText,
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 15),

              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  Text(
                    " ${displayRating.toStringAsFixed(1)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // ================= SCROLLABLE OPTION ROW =================
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      child: _buildSquareTile(Icons.settings, "Settings"),
                    ),
                    GestureDetector(
                      onTap: _openPersonalInfoPage,
                      child: _buildSquareTile(Icons.person, "Personal info"),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SecurityPage(
                              userRole: WalletUserRole.passenger,
                            ),
                          ),
                        );
                      },
                      child: _buildSquareTile(Icons.security, "Security"),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyDataPage(),
                          ),
                        );
                      },
                      child: _buildSquareTile(Icons.lock, "Privacy & data"),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SafetyPage(),
                          ),
                        );
                      },
                      child: _buildSquareTile(Icons.safety_check, "Safety"),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportPage(),
                          ),
                        );
                      },
                      child: _buildSquareTile(Icons.help, "Help"),
                    ),
                    GestureDetector(
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
                      child: _buildSquareTile(
                        Icons.account_balance_wallet,
                        "Wallet",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ================= COMPLETE PROFILE CARD =================
              if (_shouldShowCompleteProfileCard)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Complete Profile",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$_profileCompletion% completed",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _profileCompletion / 100,
                          minHeight: 9,
                          backgroundColor: AppColors.inputFill,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 28,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _profileSubtitle,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _openPersonalInfoPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.inputFill,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          _profileCompletion == 100
                              ? "View profile"
                              : "Complete now",
                          style: const TextStyle(color: AppColors.text),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ================= ABOUT UNIRIDE CARD =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "About UniRide",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "UniRide connects students, faculty, staff and alumni through a smarter campus ride-sharing experience. From daily rides to advance reservations and item delivery, UniRide is built to make university travel safer, easier and more connected.",
                      style: TextStyle(
                        color: AppColors.mutedText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedText,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildSquareTile(IconData icon, String label) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}