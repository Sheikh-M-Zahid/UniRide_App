import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/auth_api_service.dart';

import 'AddOfferPage.dart';
import 'AllRiderPage.dart';
import 'ActiveRiderPage.dart';
import 'AllPassengers.dart';
import 'AdminProfile.dart';
import 'AppStats.dart';
import 'TopLocationPage.dart';
import 'RideSharingHistory.dart';
import 'SharingCaringHistory.dart';
import 'AdminPaymentApproval.dart';
import 'AdminReportsPage.dart';
import 'RiderVerifyByAdmin.dart';
import 'FareManagementPage.dart';
import 'package:uni_ride/Adminalumnireviewpage.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final AuthApiService _authApiService = AuthApiService();

  int totalRide = 0;
  int totalUser = 0;
  int student = 0;
  int faculty = 0;
  int staff = 0;

  int activeRiders = 0;
  int inactiveRiders = 0;
  int activeUsers = 0;
  int inactiveUsers = 0;
  int pendingPaymentRequests = 0;
  int pendingAlumniRequests = 0; // ← নতুন

  String adminName = "Admin";
  String adminEmail = "";
  String? adminProfileImage;

  List<Map<String, dynamic>> last5MonthsRide = [];

  bool isLoading = true;
  String selectedPage = "Home";
  String selectedMood = "Normal Mood";

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _authApiService.getAdminDashboardSummary();
      final data = response['data'] ?? {};

      final admin = data['admin'] ?? {};
      final stats = data['stats'] ?? {};
      final activeRidersChart = data['activeRidersChart'] ?? {};
      final activeUsersChart = data['activeUsersChart'] ?? {};
      final monthlyRide =
      List<Map<String, dynamic>>.from(data['last5MonthsRide'] ?? []);

      if (!mounted) return;

      setState(() {
        final fetchedName = (admin['name'] ?? '').toString().trim();
        adminName = fetchedName.isNotEmpty ? fetchedName : 'Admin';
        adminEmail = (admin['email'] ?? '').toString();
        adminProfileImage = admin['profileImage']?.toString();

        totalRide = stats['totalRide'] ?? 0;
        totalUser = stats['totalUser'] ?? 0;
        student = stats['student'] ?? 0;
        faculty = stats['faculty'] ?? 0;
        staff = stats['staff'] ?? 0;

        activeRiders = activeRidersChart['active'] ?? 0;
        inactiveRiders = activeRidersChart['inactive'] ?? 0;
        activeUsers = activeUsersChart['active'] ?? 0;
        inactiveUsers = activeUsersChart['inactive'] ?? 0;

        pendingPaymentRequests = data['pendingPaymentRequests'] ?? 0;
        pendingAlumniRequests = data['pendingAlumniRequests'] ?? 0; // ← নতুন
        last5MonthsRide = monthlyRide;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _showMoodSelectionSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xff1b2b34),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(Icons.tune, color: Colors.cyanAccent),
                        SizedBox(width: 10),
                        Text(
                          "Switch Mood",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Choose your preferred app mood.",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildMoodOption(
                      title: "Normal Mood",
                      subtitle: "Default mode for regular use",
                      icon: Icons.wb_sunny_outlined,
                      isSelected: selectedMood == "Normal Mood",
                      onTap: () {
                        setState(() => selectedMood = "Normal Mood");
                        setModalState(() {});
                        Navigator.pop(sheetContext);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMoodOption(
                      title: "Exam Mood",
                      subtitle: "Focused mode during exams",
                      icon: Icons.menu_book_rounded,
                      isSelected: selectedMood == "Exam Mood",
                      onTap: () {
                        setState(() => selectedMood = "Exam Mood");
                        setModalState(() {});
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMoodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white24,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? Colors.cyanAccent : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================= DRAWER =================
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff141E30), Color(0xff243B55)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Menu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            drawerItem("Home"),
            drawerItem("Add Offer"),

            ListTile(
              title: const Text("Active Rider",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ActiveRiderPage()),
                );
              },
            ),

            ListTile(
              title: const Text("All Rider",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AllRiderPage()),
                );
              },
            ),

            ListTile(
              title: const Text("Passengers",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AllPassengersPage()),
                );
              },
            ),

            ListTile(
              title: const Text("Payment Requests",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminPaymentApproval()),
                );
              },
            ),

            ListTile(
              title: const Text("Rider Verify by Admin",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RiderVerifyByAdmin()),
                );
              },
            ),

            ListTile(
              title: const Text("Fare Management",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FareManagementPage()),
                );
              },
            ),

            // ─────────────────────────────────────
            // ← NEW: Alumni Verification
            // ─────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.school_outlined,
                  color: Colors.cyanAccent, size: 22),
              title: Row(
                children: [
                  const Text("Alumni Verification",
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  if (pendingAlumniRequests > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingAlumniRequests.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const AdminAlumniReviewPage(),
                  ),
                ).then((_) {
                  // Badge refresh when coming back
                  _loadDashboard();
                });
              },
            ),

            ListTile(
              title: Row(
                children: [
                  const Text("User Reports",
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  if (pendingPaymentRequests > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingPaymentRequests.toString(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminReportsPage()),
                );
              },
            ),

            ListTile(
              title: const Text("App Stats",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AppStatsPage()),
                );
              },
            ),

            ListTile(
              title: const Text("Top Location",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TopLocationPage()),
                );
              },
            ),

            ListTile(
              title: const Text("Ride Sharing History",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                      const RiderSharingHistoryPage()),
                );
              },
            ),

            ListTile(
              title: const Text("Sharing & Caring History",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                      const SharingCaringHistoryPage()),
                );
              },
            ),

            const Divider(color: Colors.white24, thickness: 1),

            ListTile(
              leading: const Icon(Icons.tune, color: Colors.cyanAccent),
              title: const Text("Switch Mood",
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(selectedMood,
                  style: const TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                _showMoodSelectionSheet();
              },
            ),
          ],
        ),
      ),

      // ================= APPBAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Admin Dashboard",
            style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminProfilePage()),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Row(
                children: [
                  Text(adminName,
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: (adminProfileImage != null &&
                        adminProfileImage!.isNotEmpty)
                        ? NetworkImage(adminProfileImage!)
                        : null,
                    child: (adminProfileImage == null ||
                        adminProfileImage!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      extendBodyBehindAppBar: true,

      // ================= BODY =================
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff0f2027),
              Color(0xff203a43),
              Color(0xff2c5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: selectedPage == "Home"
              ? homePage()
              : selectedPage == "Add Offer"
              ? AddOfferPage()
              : Center(
            child: Text(selectedPage,
                style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget drawerItem(String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        setState(() => selectedPage = title);
        Navigator.pop(context);
      },
    );
  }

  Widget homePage() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // ── Alumni pending badge card (home এ দেখাবে) ──
              if (pendingAlumniRequests > 0)
                _alumniPendingCard(),

              chartBox(
                  "Active Riders", pieChart(activeRiders, inactiveRiders)),
              chartBox("Active Users", pieChart(activeUsers, inactiveUsers)),
              chartBox("Last 5 Months Ride", barChart()),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: statCard("Total Ride", totalRide)),
                  const SizedBox(width: 20),
                  Expanded(child: statCard("Total User", totalUser)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: statCard("Student", student)),
                  const SizedBox(width: 10),
                  Expanded(child: statCard("Faculty", faculty)),
                  const SizedBox(width: 10),
                  Expanded(child: statCard("Staff", staff)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Alumni Pending Notification Card (Home Page) ──
  Widget _alumniPendingCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AdminAlumniReviewPage()),
        ).then((_) => _loadDashboard());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.cyanAccent.withOpacity(0.15),
              Colors.cyanAccent.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_outlined,
                  color: Colors.cyanAccent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alumni Verification',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$pendingAlumniRequests application${pendingAlumniRequests > 1 ? 's' : ''} pending review',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pendingAlumniRequests.toString(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.cyanAccent, size: 14),
          ],
        ),
      ),
    );
  }

  Widget pieChart(int active, int inactive) {
    final total = active + inactive;
    if (total == 0) {
      return PieChart(PieChartData(sections: [
        PieChartSectionData(
            value: 1, color: Colors.white24, title: "0", radius: 55),
      ]));
    }
    return PieChart(PieChartData(sections: [
      PieChartSectionData(
          value: active.toDouble(),
          color: Colors.cyanAccent,
          title: active.toString(),
          radius: 55),
      PieChartSectionData(
          value: inactive.toDouble(),
          color: Colors.redAccent,
          title: inactive.toString(),
          radius: 55),
    ]));
  }

  Widget barChart() {
    return BarChart(BarChartData(
      barGroups: List.generate(
        last5MonthsRide.length,
            (index) => barData(
            index, (last5MonthsRide[index]['count'] ?? 0).toDouble()),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= last5MonthsRide.length)
                return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  last5MonthsRide[index]['month'] ?? '',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true)),
        topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
      ),
    ));
  }

  BarChartGroupData barData(int x, double value) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
          toY: value,
          color: Colors.cyanAccent,
          width: 16,
          borderRadius: BorderRadius.circular(6)),
    ]);
  }

  Widget chartBox(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  Widget statCard(String title, int value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(colors: [
          Colors.black.withOpacity(0.7),
          Colors.black.withOpacity(0.9),
        ]),
      ),
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        duration: const Duration(seconds: 3),
        builder: (context, val, child) => Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Text(val.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}