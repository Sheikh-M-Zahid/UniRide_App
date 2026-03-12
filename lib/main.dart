import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'LogIn.dart';

void main() {
  runApp(const MyApp());
}

class AppColors {
  static const Color primary = Color(0xFF14B8A6);     // Teal
  static const Color secondary = Color(0xFF0F766E);   // Dark Teal
  static const Color background = Color(0xFFF9FAFB);  // Light background
  static const Color text = Color(0xFF1F2937);        // Dark text
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

  Future<void> checkLocationAndStart() async {
    var permission = await Permission.location.status;

    if (permission.isDenied) {
      permission = await Permission.location.request();
    }

    if (permission.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    startAnimation();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: displayText.isEmpty
            ? const CircularProgressIndicator(
          color: AppColors.primary,
        )
            : Container(
          width: 150,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
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