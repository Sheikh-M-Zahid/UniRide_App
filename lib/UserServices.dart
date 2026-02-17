import 'package:flutter/material.dart';
import 'UserActivity.dart';
import 'UserProfile.dart';
import 'UserOffer.dart';
import 'UserHome.dart';
import 'RideSearch.dart';

void main() {
  runApp(ServicesPage());
}

class UberCloneApp extends StatelessWidget {
  const UberCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ServicesPage(),
    );
  }
}

class ServicesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Services',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Go anywhere, get anything',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),

              // Services Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildServiceCard(context, 'Ride', Icons.directions_car, width: 160, hasPromo: true),
                  _buildServiceCard(context, 'Bike', Icons.pedal_bike, width: 160),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildServiceCard(context, 'Reserve', Icons.calendar_month, width: 160, isPromo: true),
                  _buildServiceCard(context, 'Alumni', Icons.school, width: 160),
                ],
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const UniRideHomePage()),
              );
              break;

            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ActivityPage()),
              );
              break;

            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const OffersPage()),
              );
              break;

            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const UniRideProfilePage()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view), label: 'Services'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Activity'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer), label: 'Offers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  // Widget for Service Card
  Widget _buildServiceCard(
      BuildContext context,
      String title,
      IconData icon, {
        double width = 100,
        bool hasPromo = false,
        bool isPromo = false,
      }) {
    return GestureDetector(
      onTap: () {
        // Ride & Bike → RideSearch page
        if (title == 'Ride' || title == 'Bike') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanYourRidePage(),
            ),
          );
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.black87),
                const SizedBox(height: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          if (hasPromo)
            Positioned(
              top: -10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '20%',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12),
                ),
              ),
            ),

          if (isPromo)
            Positioned(
              top: -10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Promo',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}