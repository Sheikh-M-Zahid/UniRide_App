import 'package:flutter/material.dart';
import 'RiderDashboard.dart';
import 'UserHome.dart';
import 'AdminHome.dart';

class LoginCheck extends StatefulWidget {
  const LoginCheck({super.key});

  @override
  State<LoginCheck> createState() => _LoginCheckState();
}

class _LoginCheckState extends State<LoginCheck> {
  String? selectedRole; // User / Rider / Admin

  void goNext() {
    if (selectedRole == "User") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UniRideHomePage()),
      );
    } else if (selectedRole == "Rider") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RiderDashboard()),
      );
    } else if (selectedRole == "Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a role first."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: selectedRole != null ? goNext : null,
              child: Text(
                "Next",
                style: TextStyle(
                  fontSize: 16,
                  color: selectedRole != null
                      ? const Color(0xFF14B8A6)
                      : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              "Select Your Role",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 40),
            RadioListTile<String>(
              title: const Text(
                "User",
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: "User",
              groupValue: selectedRole,
              activeColor: const Color(0xFF14B8A6),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text(
                "Rider",
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: "Rider",
              groupValue: selectedRole,
              activeColor: const Color(0xFF14B8A6),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text(
                "Admin",
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: "Admin",
              groupValue: selectedRole,
              activeColor: const Color(0xFF14B8A6),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}