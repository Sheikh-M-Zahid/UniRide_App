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
import 'CoRideSearchPage.dart';
import 'SharingCaringPage.dart';
import 'NotificationsPage.dart';
import 'ActiveRideTrackingPage.dart';
import 'package:geolocator/geolocator.dart';

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

  int offerCount = 0;
  int unreadNotificationCount = 0;
  bool isLoadingHome = true;
  Map<String, dynamic>? _activeRideRequest;
  double? _activeRideDistanceKm;
  Timer? _activeRideRefreshTimer;

  static const String _googleApiKey =
      'AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI';

  @override
  void initState() {
    super.initState();
    _loadHomeSummary();
    _startAdAutoSlide();
    _startActiveRideAutoRefresh();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _adPageController.dispose();
    _activeRideRefreshTimer?.cancel();
    super.dispose();
  }

  // ✅ প্রতি ৫ সেকেন্ডে active ride card রিফ্রেশ করা (status/location আপডেট রাখতে)
  void _startActiveRideAutoRefresh() {
    _activeRideRefreshTimer?.cancel();
    _activeRideRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
          if (!mounted) return;
          try {
            final activeRideRes =
            await _authApiService.getPassengerActiveRideRequest();
            final rideData = activeRideRes['data'];
            if (!mounted) return;
            setState(() {
              _activeRideRequest = (rideData != null && rideData is Map)
                  ? Map<String, dynamic>.from(rideData)
                  : null;
            });
            _computeActiveRideDistance();
          } catch (_) {}
        });
  }

  void _computeActiveRideDistance() {
    final d = _activeRideRequest;
    if (d == null) {
      _activeRideDistanceKm = null;
      return;
    }
    final riderLat = d['riderLat'];
    final riderLng = d['riderLng'];
    final destLat = d['destinationLat'];
    final destLng = d['destinationLng'];
    if (riderLat != null && riderLng != null && destLat != null && destLng != null) {
      final meters = Geolocator.distanceBetween(
        double.tryParse('$riderLat') ?? 0,
        double.tryParse('$riderLng') ?? 0,
        double.tryParse('$destLat') ?? 0,
        double.tryParse('$destLng') ?? 0,
      );
      _activeRideDistanceKm = meters / 1000;
    } else {
      _activeRideDistanceKm = null;
    }
  }

  Future<void> _cancelActiveRide() async {
    final d = _activeRideRequest;
    if (d == null) return;
    final requestId = (d['requestId'] ?? '').toString();
    if (requestId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride?'),
        content: const Text(
            'Are you sure you want to cancel this ride? The rider will be notified immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _authApiService.cancelActiveRideAsPassenger(requestId: requestId);
      if (!mounted) return;
      setState(() {
        _activeRideRequest = null;
        _activeRideDistanceKm = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride cancelled successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _loadHomeSummary() async {
    // রিফ্রেশের সময় loading state reset করো
    if (mounted) setState(() => isLoadingHome = true);

    // Step 1: Summary
    try {
      final summaryResponse =
      await _authApiService.getServicesSummaryPublic();
      final data = summaryResponse['data'] ?? {};
      if (mounted) {
        setState(() {
          offerCount = data['hasAdminOffer'] == true ? 1 : 0;
        });
      }
    } catch (_) {
      if (mounted) setState(() => offerCount = 0);
    }

    // Step 2: Notifications
    try {
      final notifResponse = await _authApiService.getNotifications();
      dynamic rawData = notifResponse['data'];
      List rawList = [];

      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map && rawData['notifications'] is List) {
        rawList = rawData['notifications'];
      } else if (rawData is Map && rawData['items'] is List) {
        rawList = rawData['items'];
      }

      int unread = 0;
      for (var item in rawList) {
        if (item is Map) {
          final isRead =
              item['isRead'] == true || item['is_read'] == true;
          if (!isRead) unread++;
        }
      }

      if (mounted) {
        setState(() {
          unreadNotificationCount = unread;
        });
      }
    } catch (_) {
      if (mounted) setState(() => unreadNotificationCount = 0);
    }

    // Step 3: Active ride request check
    try {
      final activeRideRes =
      await _authApiService.getPassengerActiveRideRequest();
      final rideData = activeRideRes['data'];
      if (mounted) {
        setState(() {
          _activeRideRequest =
          (rideData != null && rideData is Map)
              ? Map<String, dynamic>.from(rideData)
              : null;
        });
        _computeActiveRideDistance();
      }
    } catch (_) {
      if (mounted) setState(() => _activeRideRequest = null);
    }

    // Step 4: Loading শেষ
    if (mounted) {
      setState(() => isLoadingHome = false);
    }
  }

  void _startAdAutoSlide() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_showAds ||
          !_adPageController.hasClients ||
          _adImages.isEmpty) return;

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
            Icon(Icons.directions_car, color: AppColors.primary),
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
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(
                      userRole: UserRole.passenger,
                    ),
                  ),
                );
              },
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_none,
                        color: AppColors.text,
                        size: 28,
                      ),
                    ),
                    if (!isLoadingHome && unreadNotificationCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
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
                              unreadNotificationCount > 99
                                  ? '99+'
                                  : unreadNotificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── body ──
      body: Stack(
        children: [
          // ── Pull-to-Refresh + Main scroll content ──
          RefreshIndicator(
            onRefresh: _loadHomeSummary,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            strokeWidth: 2.5,
            displacement: 40,
            child: SingleChildScrollView(
              // physics জরুরি — না থাকলে overscroll কাজ না-ও করতে পারে
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    GestureDetector(
                      onTap: () {
                        if (_googleApiKey.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                              Text('Google Maps API key is missing'),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlanYourRidePage(
                              googleApiKey: _googleApiKey,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 15),
                        height: 55,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search,
                                color: AppColors.secondary),
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
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Google Maps API key is missing'),
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlanYourRidePage(
                                    googleApiKey: _googleApiKey,
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
                                  builder: (context) =>
                                  const ReserveRide(),
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
                                  builder: (context) =>
                                  const SendItemForm(),
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
                                  builder: (context) =>
                                  const SharingCaringPage(),
                                ),
                              );
                            },
                            child: const _SuggestionBox(
                              icon: Icons.volunteer_activism,
                              title: "Co Ride",
                            ),
                          ),
                          const SizedBox(width: 15),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const CoRideSearchPage(),
                                ),
                              );
                            },
                            child: const _SuggestionBox(
                              icon: Icons.search_rounded,
                              title: "Find CoRide",
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

                    // ✅ Active Ride Card — শুধু active ride থাকলেই দেখাবে
                    if (!isLoadingHome && _activeRideRequest != null) ...[
                      const SizedBox(height: 20),
                      _ActiveRideCard(
                        rideData: _activeRideRequest!,
                        distanceKm: _activeRideDistanceKm,
                        onCancel: _cancelActiveRide,
                        onTrack: () {
                          final d = _activeRideRequest!;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveRideTrackingPage(
                                requestId: (d['requestId'] ?? '').toString(),
                                riderName: (d['riderName'] ?? 'Rider').toString(),
                                riderPhone: (d['riderPhone'] ?? '').toString(),
                                riderPhoto: d['riderPhoto']?.toString(),
                                destination: (d['destination'] ?? '').toString(),
                                initialRiderLat: d['riderLat'] != null
                                    ? double.tryParse('${d['riderLat']}')
                                    : null,
                                initialRiderLng: d['riderLng'] != null
                                    ? double.tryParse('${d['riderLng']}')
                                    : null,
                                pickupLat: d['pickupLat'] != null
                                    ? double.tryParse('${d['pickupLat']}')
                                    : null,
                                pickupLng: d['pickupLng'] != null
                                    ? double.tryParse('${d['pickupLng']}')
                                    : null,
                                destinationLat: d['destinationLat'] != null
                                    ? double.tryParse('${d['destinationLat']}')
                                    : null,
                                destinationLng: d['destinationLng'] != null
                                    ? double.tryParse('${d['destinationLng']}')
                                    : null,
                              ),
                            ),
                          ).then((_) => _loadHomeSummary());
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
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
              MaterialPageRoute(
                  builder: (context) => const ServicesPage()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const ActivityPage()),
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

// ── Ads Slider ──
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

// ── Active Ride Card (Suggestions ব্লকের নিচে) ──
class _ActiveRideCard extends StatelessWidget {
  final Map<String, dynamic> rideData;
  final double? distanceKm;
  final VoidCallback onCancel;
  final VoidCallback onTrack;

  const _ActiveRideCard({
    required this.rideData,
    required this.distanceKm,
    required this.onCancel,
    required this.onTrack,
  });

  String _statusLabel(String stage) {
    switch (stage) {
      case 'ongoing':
        return 'On the way';
      case 'completed':
        return 'Completed';
      case 'waiting_for_pickup':
      default:
        return 'Waiting for pickup';
    }
  }

  Color _statusColor(String stage) {
    switch (stage) {
      case 'ongoing':
        return const Color(0xFF14B8A6);
      case 'completed':
        return const Color(0xFF6B7280);
      case 'waiting_for_pickup':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderName = (rideData['riderName'] ?? 'Rider').toString();
    final destination = (rideData['destination'] ?? '').toString();
    final stage = (rideData['rideStage'] ?? 'waiting_for_pickup').toString();
    final canCancel = rideData['canCancel'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  riderName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(stage).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(stage),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(stage),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 16, color: AppColors.mutedText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                ),
              ),
            ],
          ),
          if (distanceKm != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.social_distance_rounded,
                    size: 16, color: AppColors.mutedText),
                const SizedBox(width: 6),
                Text(
                  '${distanceKm!.toStringAsFixed(1)} km away from destination',
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (canCancel) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel Ride'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: onTrack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Track Ride'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Suggestion Box ──
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
          Icon(icon, size: 35, color: AppColors.primary),
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