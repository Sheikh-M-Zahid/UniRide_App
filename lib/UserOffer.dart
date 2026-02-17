import 'package:flutter/material.dart';
import 'UserProfile.dart';
import 'UserHome.dart';
import 'UserActivity.dart';
import 'UserServices.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final TextEditingController _offerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // ব্যাক বাটন সরিয়ে দেওয়া হয়েছে
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0, top: 10),
          child: Text(
            "Offers",
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // সার্চ বার (Add offer code)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _offerController,
                decoration: const InputDecoration(
                  hintText: "Add offer code",
                  prefixIcon: Icon(Icons.local_offer_outlined, color: Colors.black),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: (value) {
                  print("Applying offer code: $value");
                  // এখানে অফার কোড চেক করার লজিক বসবে
                },
              ),
            ),
          ),

          // অফার লিস্ট (অ্যাডমিন থেকে আসার জন্য ফাঁকা রাখা হয়েছে)
          const Expanded(
            child: Center(
              child: Text(
                "No offers available right now",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),

      // বটম নেভিগেশন বার
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: 3, // Offers পেজ সিলেক্টেড থাকবে
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const UniRideHomePage(),
              ),
            );
          }
          else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ServicesPage()),
            );
          }
          else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ActivityPage()),
            );
          }

          else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const UniRideProfilePage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Services"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Activity"),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: "Offers"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}