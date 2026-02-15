import 'package:flutter/material.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Rider Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      // ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Rider Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Status",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Online",
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _DashboardBox(
                  icon: Icons.directions_bike,
                  title: "Active Rides",
                ),
                _DashboardBox(
                  icon: Icons.history,
                  title: "Ride History",
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _DashboardBox(
                  icon: Icons.account_balance_wallet,
                  title: "Earnings",
                ),
                _DashboardBox(
                  icon: Icons.settings,
                  title: "Settings",
                ),
              ],
            ),
          ],
        ),
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.design_services),
            label: "Services",
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

// ================= Dashboard Box Widget =================

class _DashboardBox extends StatelessWidget {
  final IconData icon;
  final String title;

  const _DashboardBox({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 35),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}