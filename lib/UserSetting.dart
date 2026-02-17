import 'package:flutter/material.dart';
import 'package:uni_ride/LogIn.dart';
import 'UserProfile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ১. প্রোফাইল কন্টেইনার (সম্পূর্ণ কন্টেইনারে ট্যাপ করলে UserProfile-এ যাবে)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UniRideProfilePage(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Color(0xFFE0E0E0),
                      child: Icon(Icons.person, size: 45, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Zahid hossain",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "2024-1-60-074@std.ewubd.edu",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 0.5),

            // ২. সেটিংস অপশন লিস্ট
            _buildSettingItem(
              icon: Icons.home_outlined,
              title: "Add home",
              onTap: () => print("Navigate to Add Home Screen"),
            ),
            _buildSettingItem(
              icon: Icons.work_outline,
              title: "Add work",
              onTap: () => print("Navigate to Add Work Screen"),
            ),
            _buildSettingItem(
              icon: Icons.location_on_outlined,
              title: "Shortcuts",
              subtitle: "Manage saved locations",
              onTap: () => print("Navigate to Shortcuts Screen"),
            ),
            _buildSettingItem(
              icon: Icons.accessibility_new,
              title: "Accessibility",
              subtitle: "Manage your accessibility settings",
              onTap: () => print("Navigate to Accessibility Screen"),
            ),
            _buildSettingItem(
              icon: Icons.calendar_today_outlined,
              title: "Reserve",
              subtitle: "Manage your pre-booked rides",
              onTap: () => print("Navigate to Reserve Screen"),
            ),

            const SizedBox(height: 30),

            // ৩. লগ আউট বাটন
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UniRideLogin(),
                      ),
                          (route) => false,
                    );
                  },
                  child: const Text(
                    "Sign out",
                    style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // কমন উইজেট ফাংশন সেটিংস রো তৈরির জন্য
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}