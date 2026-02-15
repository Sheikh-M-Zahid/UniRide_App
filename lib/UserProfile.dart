import 'package:flutter/material.dart';
import 'UserHome.dart';

void main() => runApp(
  const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UniRideProfilePage(),
  ),
);

class UniRideProfilePage extends StatefulWidget {
  const UniRideProfilePage({super.key});

  @override
  State<UniRideProfilePage> createState() => _UniRideProfilePageState();
}

class _UniRideProfilePageState extends State<UniRideProfilePage> {
  String userName = "Zahid Hossain";
  double userRating = 4.8;
  int _selectedIndex = 4;

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UniRideHomePage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              const SizedBox(height: 30),

              // ================= PROFILE IMAGE =================
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.person,
                        size: 60, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // image picker logic later
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 15),

              Text(
                userName,
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star,
                      size: 18,
                      color:
                      userRating < 3 ? Colors.red : Colors.green),
                  Text(
                    " ${userRating.toStringAsFixed(1)}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: userRating < 3
                            ? Colors.red
                            : Colors.green),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // ================= SCROLLABLE OPTION ROW =================
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: [
                    _buildSquareTile(Icons.settings, "Settings"),
                    _buildSquareTile(Icons.person, "Personal info"),
                    _buildSquareTile(Icons.security, "Security"),
                    _buildSquareTile(Icons.lock, "Privacy & data"),
                    _buildSquareTile(Icons.help, "Help"),
                    _buildSquareTile(Icons.account_balance_wallet, "Wallet"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ================= SUGGESTION CARD =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Suggestions",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Complete your account check-up to improve your UniRide experience.",
                            style: TextStyle(
                                color: Colors.grey.shade600),
                          ),
                        ),
                        const Icon(Icons.badge,
                            size: 35, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text("Begin check-up",
                          style: TextStyle(color: Colors.black)),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
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
              icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildSquareTile(IconData icon, String label) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 10),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}