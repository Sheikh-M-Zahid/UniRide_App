import 'dart:async';

import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

import 'UserProfile.dart';
import 'RideSearch.dart';
import 'UserOffer.dart';
import 'UserActivity.dart';
import 'UserServices.dart';
import 'ReserveRide.dart';
import 'SendItem.dart';
import 'SharingCaringPage.dart';
import 'NotificationsPage.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class UniRideHomePage extends StatefulWidget {
  const UniRideHomePage({super.key});

  @override
  State<UniRideHomePage> createState() => _UniRideHomePageState();
}

class _UniRideHomePageState extends State<UniRideHomePage> {
  final AuthApiService _authApiService = AuthApiService();

  final PageController _adPageController = PageController();
  Timer? _adTimer;

  bool _showAds = true;
  int _currentAdIndex = 0;

  final List<String> _adImages = [
    'images/ADS/RideRequest_System.png',
    'images/ADS/Ride_Enjoying.png',
    'images/ADS/CoRide_System.png',
    'images/ADS/Delivery_System.png',
  ];

  @override
  void dispose() {
    _adTimer?.cancel();
    _adPageController.dispose();
    super.dispose();
  }

  int offerCount = 0;
  bool isLoadingHome = true;
  static const String _googleApiKey = 'AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI';

  @override
  void initState() {
    super.initState();
    _loadHomeSummary();
    _startAdAutoSlide();
  }

  Future<void> _loadHomeSummary() async {
    try {
      final response = await _authApiService.getServicesSummaryPublic();
      final data = response['data'] ?? {};

      if (!mounted) return;

      setState(() {
        offerCount = data['hasAdminOffer'] == true ? 1 : 0;
        isLoadingHome = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        offerCount = 0;
        isLoadingHome = false;
      });
    }
  }

  void _startAdAutoSlide() {
    _adTimer?.cancel();

    _adTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_showAds || !_adPageController.hasClients || _adImages.isEmpty) return;

      _currentAdIndex++;

      if (_currentAdIndex >= _adImages.length) {
        _currentAdIndex = 0;
      }

      _adPageController.animateToPage(
        _currentAdIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _closeAds() {
    _adTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _showAds = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.directions_car,
              color: AppColors.primary,
            ),
            SizedBox(width: 8),
            Text(
              "UniRide",
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: AppColors.text,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(
                          userRole: UserRole.passenger,
                        ),
                      ),
                    );
                  },
                ),
                !isLoadingHome && offerCount > 0
                    ? Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        offerCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                    : const SizedBox(),
              ],
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (_googleApiKey.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Maps API key is missing'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlanYourRidePage(
                        googleApiKey: 'AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  height: 55,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Where do you want to go?",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Suggestions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 15),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_googleApiKey.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Google Maps API key is missing'),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlanYourRidePage(
                              googleApiKey: 'AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI',
                            ),
                          ),
                        );
                      },
                      child: const _SuggestionBox(
                        icon: Icons.directions_car,
                        title: "Ride",
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReserveRide(),
                          ),
                        );
                      },
                      child: const _SuggestionBox(
                        icon: Icons.calendar_today,
                        title: "Reserve",
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SendItemForm(),
                          ),
                        );
                      },
                      child: const _SuggestionBox(
                        icon: Icons.inventory,
                        title: "Send Item",
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SharingCaringPage(),
                          ),
                        );
                      },
                      child: const _SuggestionBox(
                        icon: Icons.volunteer_activism,
                        title: "Co Ride",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (_showAds)
                _HomeAdsSlider(
                  controller: _adPageController,
                  adImages: _adImages,
                  onPageChanged: (index) {
                    _currentAdIndex = index;
                    _startAdAutoSlide();
                  },
                  onClose: _closeAds,
                ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedText,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ServicesPage()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ActivityPage()),
            );
          }
          if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const UniRideProfilePage(),
              ),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const OffersPage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: "Services",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: "Offers",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Account",
          ),
        ],
      ),
    );
  }
}

class _HomeAdsSlider extends StatelessWidget {
  final PageController controller;
  final List<String> adImages;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onClose;

  const _HomeAdsSlider({
    required this.controller,
    required this.adImages,
    required this.onPageChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.width * 1,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PageView.builder(
              controller: controller,
              itemCount: adImages.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    adImages[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                );
              },
            ),
          ),
        ),

        /// ❌ Close Button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionBox extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SuggestionBox({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 35,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}