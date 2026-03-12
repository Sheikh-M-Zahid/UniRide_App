import 'package:flutter/material.dart';
import 'UserActivity.dart';
import 'UserProfile.dart';
import 'UserOffer.dart';
import 'UserHome.dart';
import 'RideSearch.dart';
import 'ReserveRide.dart';

void main() {
  runApp(const UberCloneApp());
}

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
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
  ServicesPage({super.key});

  // Admin dashboard থেকে offer এলে true হবে
  final bool hasAdminCarOffer = false;

  // Offer text admin side থেকে পরে dynamic করা যাবে
  final String adminOfferText = '20%';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Go anywhere, get anything',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildServiceCard(
                    context,
                    'Car',
                    Icons.directions_car,
                    width: 160,
                    promoText: hasAdminCarOffer ? adminOfferText : null,
                  ),
                  _buildServiceCard(
                    context,
                    'Bike',
                    Icons.pedal_bike,
                    width: 160,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildServiceCard(
                    context,
                    'Reserve',
                    Icons.calendar_month,
                    width: 160,
                  ),
                  _buildServiceCard(
                    context,
                    'Alumni',
                    Icons.school,
                    width: 160,
                  ),
                ],
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
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const UniRideHomePage(),
                ),
              );
              break;

            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActivityPage(),
                ),
              );
              break;

            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const OffersPage(),
                ),
              );
              break;

            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const UniRideProfilePage(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
      BuildContext context,
      String title,
      IconData icon, {
        double width = 100,
        String? promoText,
      }) {
    return GestureDetector(
      onTap: () {
        if (title == 'Car' || title == 'Bike') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanYourRidePage(),
            ),
          );
        } else if (title == 'Reserve') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReserveRide(),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                  size: 40,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          if (promoText != null)
            Positioned(
              top: -10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  promoText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}