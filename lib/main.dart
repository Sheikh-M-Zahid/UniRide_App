import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'LogIn.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;

  bool _minimumSplashFinished = false;
  bool _locationCheckFinished = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );

    _startFlow();
  }

  Future<void> _startFlow() async {
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      _minimumSplashFinished = true;
      _goNextIfReady();
    });

    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      PermissionStatus permission = await Permission.location.status;

      if (permission.isDenied) {
        permission = await Permission.location.request();
      }

      if (permission.isPermanentlyDenied) {
        await openAppSettings();
      } else {
        final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          await Geolocator.openLocationSettings();
        }
      }
    } catch (_) {
      // ইচ্ছা করলে এখানে log দিতে পারো
    } finally {
      _locationCheckFinished = true;
      _goNextIfReady();
    }
  }

  void _goNextIfReady() {
    if (!_minimumSplashFinished || !_locationCheckFinished || _navigated) return;

    _navigated = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => const UniRideLogin(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLogoCard() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Container(
          width: 138,
          height: 138,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.20),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(
                Icons.directions_car_rounded,
                color: Colors.white,
                size: 54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection() {
    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(
        opacity: _textFade,
        child: Column(
          children: const [
            Text(
              'UniRide',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Smart campus ride sharing',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomIndicator() {
    return FadeTransition(
      opacity: _textFade,
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.22),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.05),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogoCard(),
                    const SizedBox(height: 28),
                    _buildTextSection(),
                    const SizedBox(height: 38),
                    _buildBottomIndicator(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}