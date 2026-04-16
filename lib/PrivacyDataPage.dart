import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'PersonalInfo.dart';

class PrivacyDataPage extends StatefulWidget {
  const PrivacyDataPage({super.key});

  @override
  State<PrivacyDataPage> createState() => _PrivacyDataPageState();
}

/* =========================
   THEME COLORS
========================= */
class _AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
  static const Color card = Colors.white;
}

/* =========================
   MODEL
========================= */
class PrivacyDataModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool canDownloadData;
  final String locationAccess; // never, during_ride, always
  final String profileVisibility; // matched_only, university_only, admin_only
  final String phonePrivacy; // hidden, after_accept, always_visible

  const PrivacyDataModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.canDownloadData,
    required this.locationAccess,
    required this.profileVisibility,
    required this.phonePrivacy,
  });

  factory PrivacyDataModel.fromJson(Map<String, dynamic> json) {
    return PrivacyDataModel(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      canDownloadData: json['canDownloadData'] ?? true,
      locationAccess: json['locationAccess'] ?? 'during_ride',
      profileVisibility: json['profileVisibility'] ?? 'matched_only',
      phonePrivacy: json['phonePrivacy'] ?? 'after_accept',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'canDownloadData': canDownloadData,
      'locationAccess': locationAccess,
      'profileVisibility': profileVisibility,
      'phonePrivacy': phonePrivacy,
    };
  }

  PrivacyDataModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    bool? canDownloadData,
    String? locationAccess,
    String? profileVisibility,
    String? phonePrivacy,
  }) {
    return PrivacyDataModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      canDownloadData: canDownloadData ?? this.canDownloadData,
      locationAccess: locationAccess ?? this.locationAccess,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      phonePrivacy: phonePrivacy ?? this.phonePrivacy,
    );
  }
}

/* =========================
   SERVICE
   Node.js + PostgreSQL ready
========================= */
class PrivacyDataService {
  // এখানে তোমার backend base url বসাবে
  static const String baseUrl = 'https://your-api-domain.com/api';

  // auth token থাকলে এখানে বসাতে পারো
  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer YOUR_TOKEN',
    };
  }

  // GET privacy settings
  static Future<PrivacyDataModel> fetchPrivacyData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/privacy-data'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PrivacyDataModel.fromJson(data);
    } else {
      throw Exception('Failed to load privacy data');
    }
  }

  // PATCH location access
  static Future<void> updateLocationAccess(String value) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/privacy-data/location-access'),
      headers: _headers(),
      body: jsonEncode({'locationAccess': value}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update location access');
    }
  }

  // PATCH profile visibility
  static Future<void> updateProfileVisibility(String value) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/privacy-data/profile-visibility'),
      headers: _headers(),
      body: jsonEncode({'profileVisibility': value}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile visibility');
    }
  }

  // PATCH phone privacy
  static Future<void> updatePhonePrivacy(String value) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/privacy-data/phone-privacy'),
      headers: _headers(),
      body: jsonEncode({'phonePrivacy': value}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update phone number privacy');
    }
  }

  // POST download request
  static Future<String> requestDataDownload() async {
    final response = await http.post(
      Uri.parse('$baseUrl/privacy-data/download'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Your data download request has been submitted.';
    } else {
      throw Exception('Failed to request data download');
    }
  }
}

/* =========================
   UI
========================= */
class _PrivacyDataPageState extends State<PrivacyDataPage> {
  late Future<PrivacyDataModel> _privacyFuture;
  PrivacyDataModel? _privacyData;

  bool _savingLocation = false;
  bool _savingVisibility = false;
  bool _savingPhonePrivacy = false;
  bool _downloadingData = false;

  @override
  void initState() {
    super.initState();
    _privacyFuture = _loadPrivacyData();
  }

  Future<PrivacyDataModel> _loadPrivacyData() async {
    final data = await PrivacyDataService.fetchPrivacyData();
    _privacyData = data;
    return data;
  }

  Future<void> _refreshData() async {
    setState(() {
      _privacyFuture = _loadPrivacyData();
    });
    await _privacyFuture;
  }

  String _locationLabel(String value) {
    switch (value) {
      case 'never':
        return 'Never';
      case 'always':
        return 'Always';
      case 'during_ride':
      default:
        return 'Only during ride';
    }
  }

  String _visibilityLabel(String value) {
    switch (value) {
      case 'university_only':
        return 'University community only';
      case 'admin_only':
        return 'Admin only';
      case 'matched_only':
      default:
        return 'Matched ride users only';
    }
  }

  String _phonePrivacyLabel(String value) {
    switch (value) {
      case 'hidden':
        return 'Hidden';
      case 'always_visible':
        return 'Always visible';
      case 'after_accept':
      default:
        return 'Show after ride accepted';
    }
  }

  Future<void> _updateLocationAccess(String value) async {
    if (_privacyData == null) return;

    final oldValue = _privacyData!.locationAccess;

    setState(() {
      _savingLocation = true;
      _privacyData = _privacyData!.copyWith(locationAccess: value);
    });

    try {
      await PrivacyDataService.updateLocationAccess(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data control updated')),
      );
    } catch (e) {
      setState(() {
        _privacyData = _privacyData!.copyWith(locationAccess: oldValue);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update location setting: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingLocation = false;
        });
      }
    }
  }

  Future<void> _updateProfileVisibility(String value) async {
    if (_privacyData == null) return;

    final oldValue = _privacyData!.profileVisibility;

    setState(() {
      _savingVisibility = true;
      _privacyData = _privacyData!.copyWith(profileVisibility: value);
    });

    try {
      await PrivacyDataService.updateProfileVisibility(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile visibility updated')),
      );
    } catch (e) {
      setState(() {
        _privacyData = _privacyData!.copyWith(profileVisibility: oldValue);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile visibility: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingVisibility = false;
        });
      }
    }
  }

  Future<void> _updatePhonePrivacy(String value) async {
    if (_privacyData == null) return;

    final oldValue = _privacyData!.phonePrivacy;

    setState(() {
      _savingPhonePrivacy = true;
      _privacyData = _privacyData!.copyWith(phonePrivacy: value);
    });

    try {
      await PrivacyDataService.updatePhonePrivacy(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number privacy updated')),
      );
    } catch (e) {
      setState(() {
        _privacyData = _privacyData!.copyWith(phonePrivacy: oldValue);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update phone number privacy: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPhonePrivacy = false;
        });
      }
    }
  }

  Future<void> _downloadMyData() async {
    setState(() {
      _downloadingData = true;
    });

    try {
      final message = await PrivacyDataService.requestDataDownload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request data download: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _AppColors.text),
        title: const Text(
          'Privacy & Data',
          style: TextStyle(
            color: _AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<PrivacyDataModel>(
        future: _privacyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _privacyData == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: _AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError && _privacyData == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 54,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load privacy data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${
                          snapshot.error
                      }',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _refreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = _privacyData ?? snapshot.data!;

          return RefreshIndicator(
            color: _AppColors.primary,
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _buildHeaderCard(data),
                const SizedBox(height: 18),

                _buildSectionTitle('Manage'),
                const SizedBox(height: 10),

                _buildActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Manage Personal Data',
                  subtitle:
                  'View and manage your personal information. Your university email cannot be changed.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalInformationPage(),
                      ),
                    );
                  },
                ),

                _buildActionTile(
                  icon: Icons.download_rounded,
                  title: 'Download My Data',
                  subtitle:
                  'Request a copy of your account, ride, and privacy-related data.',
                  loading: _downloadingData,
                  onTap: data.canDownloadData ? _downloadMyData : null,
                ),

                const SizedBox(height: 18),
                _buildSectionTitle('Privacy Controls'),
                const SizedBox(height: 10),

                _buildChoiceCard(
                  icon: Icons.location_on_outlined,
                  title: 'Location Data Control',
                  subtitle:
                  'Choose when UniRide can use your location information.',
                  value: data.locationAccess,
                  valueLabel: _locationLabel(data.locationAccess),
                  loading: _savingLocation,
                  onTap: () => _showLocationBottomSheet(data.locationAccess),
                ),

                _buildChoiceCard(
                  icon: Icons.visibility_outlined,
                  title: 'Profile Visibility',
                  subtitle:
                  'Control who can see your profile details in the app.',
                  value: data.profileVisibility,
                  valueLabel: _visibilityLabel(data.profileVisibility),
                  loading: _savingVisibility,
                  onTap: () =>
                      _showProfileVisibilityBottomSheet(data.profileVisibility),
                ),

                _buildChoiceCard(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number Privacy',
                  subtitle:
                  'Control when your phone number becomes visible to others.',
                  value: data.phonePrivacy,
                  valueLabel: _phonePrivacyLabel(data.phonePrivacy),
                  loading: _savingPhonePrivacy,
                  onTap: () => _showPhonePrivacyBottomSheet(data.phonePrivacy),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: _AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: _AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Your university email address is required for account verification and cannot be changed from Privacy & Data settings.',
                          style: TextStyle(
                            color: _AppColors.mutedText,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(PrivacyDataModel data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _AppColors.primary.withOpacity(0.14),
            _AppColors.secondary.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _AppColors.primary.withOpacity(0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: _AppColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy that stays clear',
                  style: TextStyle(
                    color: _AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage how your personal data, location, profile visibility, and phone number are used in UniRide.',
                  style: TextStyle(
                    color: _AppColors.text.withOpacity(0.78),
                    fontSize: 14.2,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.alternate_email_rounded,
                      size: 16,
                      color: _AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.email,
                        style: const TextStyle(
                          color: _AppColors.text,
                          fontSize: 13.8,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _AppColors.text,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: _AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _AppColors.secondary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _AppColors.text,
            fontSize: 15.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: _AppColors.mutedText,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ),
        trailing: loading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.3,
            color: _AppColors.primary,
          ),
        )
            : const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: _AppColors.mutedText,
        ),
        onTap: loading ? null : onTap,
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String valueLabel,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: _AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _AppColors.text,
                    fontSize: 15.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _AppColors.mutedText,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    valueLabel,
                    style: const TextStyle(
                      color: _AppColors.secondary,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          loading
              ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: _AppColors.primary,
            ),
          )
              : IconButton(
            onPressed: onTap,
            icon: const Icon(
              Icons.edit_outlined,
              color: _AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationBottomSheet(String currentValue) {
    _showOptionsBottomSheet(
      title: 'Location Data Control',
      currentValue: currentValue,
      options: const [
        {'value': 'never', 'label': 'Never'},
        {'value': 'during_ride', 'label': 'Only during ride'},
        {'value': 'always', 'label': 'Always'},
      ],
      onSelect: _updateLocationAccess,
    );
  }

  void _showProfileVisibilityBottomSheet(String currentValue) {
    _showOptionsBottomSheet(
      title: 'Profile Visibility',
      currentValue: currentValue,
      options: const [
        {'value': 'matched_only', 'label': 'Matched ride users only'},
        {'value': 'university_only', 'label': 'University community only'},
        {'value': 'admin_only', 'label': 'Admin only'},
      ],
      onSelect: _updateProfileVisibility,
    );
  }

  void _showPhonePrivacyBottomSheet(String currentValue) {
    _showOptionsBottomSheet(
      title: 'Phone Number Privacy',
      currentValue: currentValue,
      options: const [
        {'value': 'hidden', 'label': 'Hidden'},
        {'value': 'after_accept', 'label': 'Show after ride accepted'},
        {'value': 'always_visible', 'label': 'Always visible'},
      ],
      onSelect: _updatePhonePrivacy,
    );
  }

  void _showOptionsBottomSheet({
    required String title,
    required String currentValue,
    required List<Map<String, String>> options,
    required Future<void> Function(String value) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: _AppColors.border,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: _AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map(
                      (option) {
                    final value = option['value']!;
                    final label = option['label']!;
                    final selected = value == currentValue;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? _AppColors.primary
                              : _AppColors.border,
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          label,
                          style: const TextStyle(
                            color: _AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                          Icons.check_circle_rounded,
                          color: _AppColors.primary,
                        )
                            : const Icon(
                          Icons.circle_outlined,
                          color: _AppColors.mutedText,
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          if (value != currentValue) {
                            await onSelect(value);
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}