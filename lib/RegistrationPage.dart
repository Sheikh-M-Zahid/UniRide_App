import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'LogIn.dart';
import 'main.dart'; // UniRideLogin ক্লাসটি পাওয়ার জন্য

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // স্ক্রিন ছোট হলে যাতে স্ক্রল করা যায়
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // UniRide Logo Box (Arrow ছাড়া)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12)
                ),
                child: const Text(
                    'UniRide',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                    )
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                'Get started with UniRide',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('University Email', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),

              // Mobile/Email Input Field (main.dart এর স্টাইল অনুযায়ী)
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter Your University Email',
                  filled: true,
                  fillColor: const Color(0xFFF3F3F3),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.black),
                  suffixIcon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Already have an account? Log in
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      // main.dart এর UniRideLogin পেজে নিয়ে যাবে
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UniRideLogin()),
                      );
                    },
                    child: const Text(
                      "Log in",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // or Divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 25),

              // Continue with Google (main.dart এর social button স্টাইল অনুযায়ী)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEEEEE),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.google, color: Colors.red, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Find my account
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.search, color: Colors.grey, size: 20),
                label: const Text(
                  'Find my account',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),

              // Footer Text
              const Text(
                'By continuing, you agree to receive calls, including by automated dialer, WhatsApp or texts from UniRide and its affiliates.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}