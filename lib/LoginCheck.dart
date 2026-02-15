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
    }

    else if (selectedRole == "Rider") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RiderDashboard()),
      );
    }

    else if (selectedRole == "Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard(),),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                      ? Colors.black
                      : Colors.grey,
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
              ),
            ),

            const SizedBox(height: 40),

            CheckboxListTile(
              title: const Text("User"),
              value: selectedRole == "User",
              onChanged: (value) {
                setState(() {
                  selectedRole = "User";
                });
              },
            ),

            CheckboxListTile(
              title: const Text("Rider"),
              value: selectedRole == "Rider",
              onChanged: (value) {
                setState(() {
                  selectedRole = "Rider";
                });
              },
            ),

            CheckboxListTile(
              title: const Text("Admin"),
              value: selectedRole == "Admin",
              onChanged: (value) {
                setState(() {
                  selectedRole = "Admin";
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}