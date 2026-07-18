import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'LogIn.dart';
import 'UserHome.dart';
import 'RiderDashboard.dart';
import 'AdminHome.dart';
import 'RideRequestService.dart';
import 'firebase_options.dart';
import 'AccountSuspendedPage.dart';
import 'services/auth_api_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _showLocalNotification(message);
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'uniride_channel',
    'UniRide Notifications',
    channelDescription: 'UniRide app notifications',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'UniRide',
    message.notification?.body ?? '',
    const NotificationDetails(android: androidDetails),
  );
}

Future<void> _initFcmAndSaveToken() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // Notification channel Android-এ create করো
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'uniride_channel',
      'UniRide Notifications',
      description: 'UniRide app notifications',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Token নাও
    final fcmToken = await messaging.getToken();

    if (fcmToken != null && fcmToken.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');

      // Token নতুন হলে বা না থাকলে save করো
      if (savedToken != fcmToken) {
        await prefs.setString('fcm_token', fcmToken);
      }

      // যদি user already logged in থাকে তাহলে server-এ পাঠাও
      final authToken = prefs.getString('token');
      if (authToken != null && authToken.isNotEmpty) {
        try {
          await AuthApiService().saveFcmToken(fcmToken: fcmToken);
        } catch (_) {}
      }
    }

    // Token refresh হলে আবার save করো
    messaging.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);

      final authToken = prefs.getString('token');
      if (authToken != null && authToken.isNotEmpty) {
        try {
          await AuthApiService().saveFcmToken(fcmToken: newToken);
        } catch (_) {}
      }
    });
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidInit),
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Foreground-এ notification দেখানোর জন্য
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showLocalNotification(message);
  });

  // FCM token init এবং server-এ save
  await _initFcmAndSaveToken();

  RideRequestService.initialize(navigatorKey);
  runApp(const MyApp());
}

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
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
    } finally {
      _locationCheckFinished = true;
      _goNextIfReady();
    }
  }

  Future<void> _goNextIfReady() async {
    if (!_minimumSplashFinished || !_locationCheckFinished || _navigated)
      return;

    _navigated = true;

    final prefs = await SharedPreferences.getInstance();

    final lastLoginMillis = prefs.getInt('last_login_at');

    if (lastLoginMillis != null) {
      final lastLoginTime =
      DateTime.fromMillisecondsSinceEpoch(lastLoginMillis);
      final now = DateTime.now();
      final difference = now.difference(lastLoginTime);

      if (difference.inDays >= 30) {
        await prefs.remove('token');
        await prefs.remove('user_email');
        await prefs.remove('user_id');
        await prefs.remove('user_name');
        await prefs.remove('is_logged_in');
        await prefs.remove('is_admin');
        await prefs.remove('last_role');
        await prefs.remove('last_login_at');
      }
    }

    final updatedToken = prefs.getString('token');
    final updatedIsLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final updatedLastRole = prefs.getString('last_role') ?? '';
    final updatedAccountStatus = prefs.getString('account_status') ?? 'active';

    Widget nextPage = const UniRideLogin();

    if (updatedIsLoggedIn &&
        updatedToken != null &&
        updatedToken.isNotEmpty) {
      if (updatedAccountStatus == 'suspended') {
        nextPage = AccountSuspendedPage(
          isRider: updatedLastRole == 'rider',
        );
      } else if (updatedLastRole == 'passenger') {
        nextPage = const UniRideHomePage();
      } else if (updatedLastRole == 'rider') {
        nextPage = const RiderDashboard();
      } else if (updatedLastRole == 'admin') {
        nextPage = AdminDashboard();
      } else {
        nextPage = const UniRideLogin();
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => nextPage,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
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
              colors: [AppColors.primary, AppColors.secondary],
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