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

  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await _authApiService.getRiderDashboardSummary();
      final data = response['data'] ?? response;

      if (!mounted) return;

      setState(() {
        _dashboardData = data;
        isOnline = data['is_online'] == true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
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

  Future<void> _updateOnlineStatus(bool value) async {
    try {
      await _authApiService.updateRiderStatus(isOnline: value);

      if (!mounted) return;

      setState(() {
        isOnline = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOnline ? "You are now Online" : "You are now Offline",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _openFeature(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title clicked")),
    );
  }

  void _simulateIncomingRequests() {
    if (!isOnline) return;

    RideRequestService.addRequest(
      const RideRequestModel(
        passengerName: "Rakib Hasan",
        phoneNumber: "01712345678",
        currentLocation: "Hall Gate",
        destination: "Main Campus",
        distanceKm: 3.4,
        fare: 85,
        estimatedMinutes: 12,
      ),
    );

    RideRequestService.addRequest(
      const RideRequestModel(
        passengerName: "Nusrat Jahan",
        phoneNumber: "01811223344",
        currentLocation: "Library Front",
        destination: "CSE Building",
        distanceKm: 2.1,
        fare: 60,
        estimatedMinutes: 8,
      ),
    );

    RideRequestService.addRequest(
      const RideRequestModel(
        passengerName: "Tamim",
        phoneNumber: "01999888777",
        currentLocation: "Dormitory Road",
        destination: "Administrative Building",
        distanceKm: 4.8,
        fare: 110,
        estimatedMinutes: 16,
      ),
    );
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
                        onChanged: (value) {
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
                    value: "৳${_dashboardData?['today_earnings'] ?? 0}",
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
                      value: "${_dashboardData?['notification_count'] ?? 0} New",
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
                  if (_dashboardData?['active_ride'] != null) ...[
                    _SummaryRow(
                      label: "Pickup",
                      value: "${_dashboardData?['active_ride']?['start_location'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Destination",
                      value: "${_dashboardData?['active_ride']?['destination'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Fare",
                      value: "৳${_dashboardData?['active_ride']?['total_fare'] ?? 0}",
                    ),
                    _SummaryRow(
                      label: "Status",
                      value: "${_dashboardData?['active_ride']?['status'] ?? ''}",
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
                  if (_dashboardData?['upcoming_reserved_ride'] != null) ...[
                    _SummaryRow(
                      label: "Date",
                      value: "${_dashboardData?['upcoming_reserved_ride']?['travel_date'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Time",
                      value: "${_dashboardData?['upcoming_reserved_ride']?['travel_time'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Pickup",
                      value: "${_dashboardData?['upcoming_reserved_ride']?['start_location'] ?? ''}",
                    ),
                    _SummaryRow(
                      label: "Destination",
                      value: "${_dashboardData?['upcoming_reserved_ride']?['destination'] ?? ''}",
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
                          title: "Send Item",
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
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add_alert),
                label: const Text("Live requests will appear here"),
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