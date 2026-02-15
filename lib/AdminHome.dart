import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
    ).animate(CurvedAnimation(
        parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ===== Drawer =====
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
                child: Text("Menu",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            drawerItem("Home"),
            drawerItem("Active Rider"),
            drawerItem("All Rider"),
            drawerItem("Passengers"),
            drawerItem("App Stats"),
            drawerItem("Top Location"),
            drawerItem("Income/Expense"),
            drawerItem("Rider Sharing History"),
            drawerItem("Company Sharing History"),
          ],
        ),
      ),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Admin Dashboard",
            style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text("Admin Name",
                    style: TextStyle(color: Colors.white)),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // Navigate to profile
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage:
                    NetworkImage("https://i.pravatar.cc/150?img=3"),
                  ),
                )
              ],
            ),
          )
        ],
      ),

      extendBodyBehindAppBar: true,

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
              : Center(
            child: Text(selectedPage,
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

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

  // ===== Pie Chart =====
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

  // ===== Bar Chart =====
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

  // ===== Glassmorphism Chart Box =====
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
          Text(title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  // ===== Count Animation Card =====
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
            Text(title,
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 10),
            Text(
              val.toString(),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}