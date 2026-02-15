import 'package:flutter/material.dart';
import 'UserProfile.dart';
import 'RideSearch.dart';

class UniRideHomePage extends StatelessWidget {
  const UniRideHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.directions_car, color: Colors.black),
            SizedBox(width: 8),
            Text(
              "UniRide",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Where to search box
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlanYourRidePage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 10),
                      Text(
                        "Where do you want to go?",
                        style: TextStyle(fontSize: 16),
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
                ),
              ),
              const SizedBox(height: 15),

              // 3 Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _SuggestionBox(
                    icon: Icons.directions_car,
                    title: "Ride",
                  ),
                  _SuggestionBox(
                    icon: Icons.calendar_today,
                    title: "Reserve",
                  ),
                  _SuggestionBox(
                    icon: Icons.local_shipping,
                    title: "Send Item",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UniRideProfilePage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view), label: "Services"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: "Activity"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer), label: "Offers"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}

// ================= Suggestion Box Widget =================
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 35),
          const SizedBox(height: 10),
          Text(title),
        ],
      ),
    );
  }
}