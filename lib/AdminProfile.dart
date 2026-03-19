import 'package:flutter/material.dart';
import 'LogIn.dart';
import 'UserProfile.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  late Future<UserProfileModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchUserProfile();
  }

  Future<UserProfileModel> _fetchUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 800));

    // ================= BACKEND READY =================
    // Later replace this whole method with:
    // final response = await yourApiService.getUserProfile();
    // return UserProfileModel.fromJson(response.data);

    return UserProfileModel(
      id: "usr_1001",
      fullName: "Admin Name",
      email: "admin@uniride.com",
      phone: "+8801XXXXXXXXX",
      userType: "Student", // Student / Faculty / Staff
      gender: "Male",
      joinedDate: "14 Mar 2026",
      profileImageUrl: "",
      isVerified: true,
      roles: const ["passenger", "admin"], // passenger, rider, admin
    );
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = _fetchUserProfile();
    });
    await _profileFuture;
  }

  Future<void> _showSwitchPassengerDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: AppColors.softPrimary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.switch_account_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Switch to Passenger Profile?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "You are about to switch from Admin to Passenger mode.\n\n"
                      "⚠️ Once you switch, you will not be able to return to the Admin profile directly.\n"
                      "To access the Admin panel again, you will need to log out and log in again.\n\n"
                      "Do you want to continue?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.text,
                          side: BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const UniRideProfilePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          "Profile",
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<UserProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ProfileLoadingView();
          }

          if (snapshot.hasError) {
            return _ProfileErrorView(
              onRetry: () {
                setState(() {
                  _profileFuture = _fetchUserProfile();
                });
              },
            );
          }

          if (!snapshot.hasData) {
            return _ProfileErrorView(
              onRetry: () {
                setState(() {
                  _profileFuture = _fetchUserProfile();
                });
              },
            );
          }

          final profile = snapshot.data!;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  _buildProfileHeader(profile),
                  const SizedBox(height: 18),
                  _buildRoleCard(profile),
                  const SizedBox(height: 16),
                  _buildBasicInfoCard(profile),
                  const SizedBox(height: 16),
                  _buildAccountInfoCard(profile),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UniRideLogin(),
                          ),
                              (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProfileModel profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 104,
                width: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withOpacity(0.18),
                ),
                child: ClipOval(
                  child: profile.profileImageUrl.isNotEmpty
                      ? Image.network(
                    profile.profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _defaultAvatar(profile.fullName),
                  )
                      : _defaultAvatar(profile.fullName),
                ),
              ),
              if (profile.isVerified)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text(
              profile.roleDisplayText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(UserProfileModel profile) {
    return _sectionCard(
      title: "Roles",
      icon: Icons.badge_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: profile.roles.map((role) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.softPrimary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.18)),
            ),
            child: Text(
              role.toDisplayRole(),
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBasicInfoCard(UserProfileModel profile) {
    return _sectionCard(
      title: "Basic Information",
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _infoTile("Full Name", profile.fullName),
          _divider(),
          _infoTile("Phone Number", profile.phone),
          _divider(),
          _infoTile("User Type", profile.userType),
          _divider(),
          _infoTile("Gender", profile.gender),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(UserProfileModel profile) {
    return _sectionCard(
      title: "Account Information",
      icon: Icons.manage_accounts_outlined,
      child: Column(
        children: [
          _infoTile("User ID", profile.id),
          _divider(),
          _infoTile("Email", profile.email),
          _divider(),
          _infoTile("Joined Date", profile.joinedDate),
          _divider(),
          _infoTile(
            "Verification",
            profile.isVerified ? "Verified" : "Not Verified",
            valueColor:
            profile.isVerified ? AppColors.success : AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return _sectionCard(
      title: "Quick Actions",
      icon: Icons.flash_on_outlined,
      child: Column(
        children: [
          _actionTile(
            icon: Icons.switch_account_rounded,
            title: "Switch to as a Passenger",
            subtitle: "Open your passenger profile to request a ride",
            onTap: _showSwitchPassengerDialog,
          ),
          _divider(),
          _actionTile(
            icon: Icons.edit_outlined,
            title: "Edit Profile",
            subtitle: "Update your personal information",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Edit Profile clicked")),
              );
            },
          ),
          _divider(),
          _actionTile(
            icon: Icons.lock_outline_rounded,
            title: "Change Password",
            subtitle: "Keep your account secure",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Change Password clicked")),
              );
            },
          ),
          _divider(),
          _actionTile(
            icon: Icons.notifications_none_rounded,
            title: "Notification Settings",
            subtitle: "Manage your alert preferences",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notification Settings clicked")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.softPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.circle,
                  color: Colors.transparent,
                ),
              ),
              Container(
                transform: Matrix4.translationValues(-40, 0, 0),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(-28, 0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(
      String title,
      String value, {
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.softPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border.withOpacity(0.85),
    );
  }

  Widget _defaultAvatar(String name) {
    final initials = _getInitials(name);
    return Container(
      color: Colors.white.withOpacity(0.16),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts =
    name.trim().split(' ').where((element) => element.isNotEmpty).toList();

    if (parts.isEmpty) return "A";
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }
}

class UserProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String userType;
  final String gender;
  final String joinedDate;
  final String profileImageUrl;
  final bool isVerified;
  final List<String> roles;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.userType,
    required this.gender,
    required this.joinedDate,
    required this.profileImageUrl,
    required this.isVerified,
    required this.roles,
  });

  String get roleDisplayText {
    return roles.map((e) => e.toDisplayRole()).join(" + ");
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      userType: json['userType']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      joinedDate: json['joinedDate']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((e) => e.toString().toLowerCase())
          .toList(),
    );
  }
}

extension RoleDisplayExtension on String {
  String toDisplayRole() {
    switch (toLowerCase()) {
      case 'passenger':
        return 'Passenger';
      case 'rider':
        return 'Rider';
      case 'admin':
        return 'Admin';
      default:
        return this;
    }
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: List.generate(
        4,
            (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: index == 0 ? 240 : 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),
            const Text(
              "Failed to load profile",
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please try again.",
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color softPrimary = Color(0xFFECFEFF);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
}