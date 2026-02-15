import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'LogIn.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  String displayText = "";
  final String fullText = "UniRide";
  int index = 0;

  @override
  void initState() {
    super.initState();
    checkLocationAndStart();
  }

  // =========================
  // LOCATION CHECK SYSTEM
  // =========================

  Future<void> checkLocationAndStart() async {

    // 1️⃣ Check Permission
    var permission = await Permission.location.status;

    if (permission.isDenied) {
      permission = await Permission.location.request();
    }

    if (permission.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    // 2️⃣ Check Location Service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // 3️⃣ Get Current Location (optional but recommended)
    await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4️⃣ Start Splash Animation
    startAnimation();
  }

  // =========================
  // SPLASH ANIMATION
  // =========================

  void startAnimation() {
    Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (index < fullText.length) {
        setState(() {
          displayText += fullText[index];
          index++;
        });
      } else {
        timer.cancel();

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UniRideLogin(),
            ),
          );
        });
      }
    });
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: displayText.isEmpty
            ? const CircularProgressIndicator(color: Colors.black)
            : Container(
          width: 150,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                displayText,
                key: ValueKey(displayText),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}