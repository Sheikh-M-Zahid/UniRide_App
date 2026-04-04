import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  // ===== Database Ready Variables =====
  int totalRide = 0;
  int totalUser = 0;
  int student = 0;
  int faculty = 0;
  int staff = 0;

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
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildMoodOption(
                      title: "Normal Mood",
                      subtitle: "Default mode for regular use",
                      icon: Icons.wb_sunny_outlined,
                      isSelected: selectedMood == "Normal Mood",
                      onTap: () {
                        setState(() {
                          selectedMood = "Normal Mood";
                        });
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
                        setState(() {
                          selectedMood = "Exam Mood";
                        });
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                    ),
                  ),
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
              decoration: BoxDecoration(
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
              title: Text(
                "Active Rider",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActiveRiderPage(),
                  ),
                );
              },
            ),

            // ✅ All Rider → Separate Page
            ListTile(
              title: Text(
                "All Rider",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllRiderPage(),
                  ),
                );
              },
            ),

            ListTile(
              title: Text(
                "Passengers",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllPassengersPage(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text(
                "Payment Requests",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPaymentApproval(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text(
                "App Stats",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppStatsPage(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text(
                "Top Location",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TopLocationPage(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text(
                "Ride Sharing History",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RiderSharingHistoryPage(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text(
                "Sharing & Caring History",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SharingCaringHistoryPage(),
                  ),
                );
              },
            ),

            const Divider(color: Colors.white24, thickness: 1),

            ListTile(
              leading: const Icon(Icons.tune, color: Colors.cyanAccent),
              title: const Text(
                "Switch Mood",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                selectedMood,
                style: const TextStyle(color: Colors.white70),
              ),
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
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminProfilePage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Row(
                children: [
                  Text(
                    "Admin Name",
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  CircleAvatar(
                    radius: 18,
                    backgroundImage:
                    NetworkImage("https://i.pravatar.cc/150?img=3"),
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
        decoration: BoxDecoration(
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
            child: Text(
              selectedPage,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // ================= Drawer Item =================
  Widget drawerItem(String title) {
    return ListTile(
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () {
        setState(() {
          selectedPage = title;
        });
        Navigator.pop(context);
      },
    );
  }

  // ================= HOME PAGE =================
  Widget homePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 90, 20, 20),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              chartBox("Active Riders", pieChart()),
              chartBox("Active Users", pieChart()),
              chartBox("Last 5 Months Ride", barChart()),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: statCard("Total Ride", totalRide)),
                  SizedBox(width: 20),
                  Expanded(child: statCard("Total User", totalUser)),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: statCard("Student", student)),
                  SizedBox(width: 10),
                  Expanded(child: statCard("Faculty", faculty)),
                  SizedBox(width: 10),
                  Expanded(child: statCard("Staff", staff)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= Pie Chart =================
  Widget pieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: 1,
            color: Colors.cyanAccent,
            title: "0",
            radius: 55,
          ),
        ],
      ),
    );
  }

  // ================= Bar Chart =================
  Widget barChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          barData(0, 0),
          barData(1, 0),
          barData(2, 0),
          barData(3, 0),
          barData(4, 0),
        ],
      ),
    );
  }

  BarChartGroupData barData(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: Colors.cyanAccent,
          width: 16,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  // ================= Chart Box =================
  Widget chartBox(String title, Widget child) {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  // ================= Stat Card =================
  Widget statCard(String title, int value) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        duration: Duration(seconds: 3),
        builder: (context, val, child) => Column(
          children: [
            Text(title, style: TextStyle(color: Colors.white70)),
            SizedBox(height: 10),
            Text(
              val.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}