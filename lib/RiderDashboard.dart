import 'dart:async';

import 'package:flutter/material.dart';
import 'ActiveRidesPage.dart';
import 'RideRequestModel.dart';
import 'RideRequestService.dart';
import 'RiderRideHistory.dart';
import 'RiderActivityPage.dart';
import 'RiderMap.dart';
import 'RiderProfile.dart';
import 'RiderDelivery.dart';
import 'EarningsPage.dart';
import 'NotificationsPage.dart';
import 'RiderOffers.dart';
import 'services/auth_api_service.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  int _selectedIndex = 0;
  bool isOnline = true;

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

  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Timer? _dashboardRefreshTimer;
  bool _isUpdatingStatus = false;
  bool _isCancellingRide = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _startAutoRefresh();
    _startAdAutoSlide();
    RideRequestService.setupRealtime();
  }

  @override
  void dispose() {
    _dashboardRefreshTimer?.cancel();
    _adTimer?.cancel();
    _adPageController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool showLoader = true}) async {
    try {
      if (showLoader && mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final response = await _authApiService.getRiderDashboardSummary();
      final data = response['data'] ?? response;

      if (!mounted) return;

      setState(() {
        _dashboardData = data;
        isOnline = data['isOnline'] == true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (showLoader) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _startAutoRefresh() {
    _dashboardRefreshTimer?.cancel();
    _dashboardRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadDashboard(showLoader: false);
      }
    });
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ActivityPage(),
        ),
      );
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MapPage(),
        ),
      );
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RiderProfile(),
        ),
      );
    }
  }

  Future<void> _cancelActiveRide() async {
    final confirmedRides = RideRequestService.getConfirmedRides();
    String? requestId;

    if (confirmedRides.isNotEmpty) {
      requestId = confirmedRides.first.requestId;
    } else {
      requestId = _dashboardData?['activeRide']?['requestId']?.toString();
    }

    if (requestId == null || requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find active ride to cancel.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride?'),
        content: const Text(
          'Are you sure you want to cancel this confirmed ride? The passenger will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancellingRide = true);

    final result = await RideRequestService.rejectConfirmedRide(requestId);

    if (!mounted) return;
    setState(() => _isCancellingRide = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626),
      ),
    );

    if (result.success) {
      _loadDashboard(showLoader: false);
    }
  }

  Future<void> _updateOnlineStatus(bool value) async {
    if (_isUpdatingStatus) return;

    try {
      setState(() {
        _isUpdatingStatus = true;
      });

      await _authApiService.updateRiderStatus(isOnline: value);

      if (!mounted) return;

      setState(() {
        isOnline = value;
        _isUpdatingStatus = false;
      });

      _loadDashboard(showLoader: false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? "You are now Online" : "You are now Offline",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        elevation: 0,
        title: const Text(
          "Rider Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Status",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        isOnline ? "Online" : "Offline",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isOnline,
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF0F766E),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white54,
                        onChanged: _isUpdatingStatus
                            ? null
                            : (value) {
                          _updateOnlineStatus(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// Top Summary
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: "Today Earnings",
                    value: "৳${_dashboardData?['todayEarnings'] ?? 0}",
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(
                            userRole: UserRole.rider,
                          ),
                        ),
                      );
                    },
                    child: _InfoCard(
                      title: "Notifications",
                      value: "${_dashboardData?['unreadNotifications'] ?? 0} New",
                      icon: Icons.notifications_active,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// Active Ride Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Active Ride Summary",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_dashboardData?['activeRide'] != null) ...[
                    _SummaryRow(
                      label: "Pickup",
                      value: "${_dashboardData?['activeRide']?['pickup'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Destination",
                      value: "${_dashboardData?['activeRide']?['destination'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Fare",
                      value: "৳${_dashboardData?['activeRide']?['fare'] ?? 0}",
                    ),
                    _SummaryRow(
                      label: "Status",
                      value: "${_dashboardData?['activeRide']?['status'] ?? ''}",
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isCancellingRide ? null : _cancelActiveRide,
                        icon: _isCancellingRide
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFDC2626),
                          ),
                        )
                            : const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 18),
                        label: Text(
                          _isCancellingRide ? 'Cancelling...' : 'Cancel Ride',
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      "No active ride",
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// Upcoming Reserved Ride
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upcoming Reserved Ride",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_dashboardData?['upcomingReservedRide'] != null) ...[
                    _SummaryRow(
                      label: "Date",
                      value: "${_dashboardData?['upcomingReservedRide']?['date'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Time",
                      value: "${_dashboardData?['upcomingReservedRide']?['time'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Pickup",
                      value: "${_dashboardData?['upcomingReservedRide']?['pickup'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Destination",
                      value: "${_dashboardData?['upcomingReservedRide']?['destination'] ?? ''}",
                    ),
                  ] else
                    const Text(
                      "No upcoming reserved ride",
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                int itemsPerRow = 2;

                if (constraints.maxWidth >= 1100) {
                  itemsPerRow = 4;
                } else if (constraints.maxWidth >= 800) {
                  itemsPerRow = 3;
                }

                final double spacing = 16;
                final double itemWidth =
                    (constraints.maxWidth - ((itemsPerRow - 1) * spacing)) /
                        itemsPerRow;

                return Wrap(
                  spacing: spacing,
                  runSpacing: 20,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _DashboardBox(
                          icon: Icons.directions_bike,
                          title: "Active Rides",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ActiveRidesPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _DashboardBox(
                          icon: Icons.history,
                          title: "Ride History",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RideHistoryPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _DashboardBox(
                          icon: Icons.notifications,
                          title: "Notifications",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(
                                  userRole: UserRole.rider,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _DashboardBox(
                          icon: Icons.local_shipping_outlined,
                          title: "Delivery Item",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RiderDeliveryPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _DashboardBox(
                          icon: Icons.account_balance_wallet,
                          title: "Earnings",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EarningsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _DashboardBox(
                          icon: Icons.account_balance_wallet,
                          title: "Earnings",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EarningsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _DashboardBox(
                          icon: Icons.local_offer_rounded,
                          title: "Offers",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RiderOffersPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            if (_showAds) ...[
              _HomeAdsSlider(
                controller: _adPageController,
                adImages: _adImages,
                onPageChanged: (index) {
                  _currentAdIndex = index;
                  _startAdAutoSlide();
                },
                onClose: _closeAds,
              ),
              const SizedBox(height: 20),
            ],

            if ((_dashboardData?['pendingRideRequests'] is List &&
                (_dashboardData?['pendingRideRequests'] as List).isNotEmpty) ||
                (_dashboardData?['pendingDeliveryRequests'] is List &&
                    (_dashboardData?['pendingDeliveryRequests'] as List).isNotEmpty) ||
                (_dashboardData?['pendingReserveRequests'] is List &&
                    (_dashboardData?['pendingReserveRequests'] as List).isNotEmpty))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(
                          userRole: UserRole.rider,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_alert),
                  label: const Text("You have live requests"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.add_alert),
                  label: const Text("No live requests right now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF14B8A6),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Map",
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

class _DashboardBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardBox({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: const Color(0xFF0F766E)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F766E), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
              ),
            ),
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
            border: Border.all(color: const Color(0xFFE5E7EB)),
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