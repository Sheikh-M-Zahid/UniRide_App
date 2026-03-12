import 'dart:math';
import 'package:flutter/material.dart';
import 'otp_verification_page.dart';

class GmailconfirmPage extends StatefulWidget {
  const GmailconfirmPage({super.key});

  @override
  State<GmailconfirmPage> createState() => _GmailconfirmPageState();
}

class _GmailconfirmPageState extends State<GmailconfirmPage> {

  final TextEditingController _emailController =
  TextEditingController();

  // 🔥 OTP generate function (4 digit)
  String _generateOTP() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  void _sendOTP() {

    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text("Please enter your university email")),
      );
      return;
    }

    // 🔥 OTP generate
    String generatedOtp = _generateOTP();

    print("Generated OTP: $generatedOtp");
    // 👉 পরে backend বসালে এখানে email এ পাঠাবে

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPVerificationPage(
          email: email,
          generatedOtp: generatedOtp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 60),

              const Center(
                child: Text(
                  "UniRide",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14B8A6),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Get started with UniRide",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "University Email",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Row(
                  children: [

                    const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF0F766E),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: TextField(
                        controller:
                        _emailController,
                        keyboardType:
                        TextInputType.emailAddress,
                        decoration:
                        const InputDecoration(
                          border: InputBorder.none,
                          hintText:
                          "Enter Your University Email",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sendOTP,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF14B8A6),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  "or",
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Google Sign In Logic এখানে বসবে
                  },
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.white,
                  ),
                  icon: Image.network(
                    "https://developers.google.com/identity/images/g-logo.png",
                    height: 20,
                  ),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}