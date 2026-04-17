import 'dart:async';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color softPrimary = Color(0xFFECFEFF);
}

class RequestingRidePage extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String driverPhoneNumber;
  final String vehicleType;
  final String vehicleNumber;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final double distanceKm;
  final int estimatedMinutes;

  const RequestingRidePage({
    super.key,
    required this.rideId,
    required this.driverName,
    required this.driverPhoneNumber,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.distanceKm,
    required this.estimatedMinutes,
  });

  @override
  State<RequestingRidePage> createState() => _RequestingRidePageState();
}

class _RequestingRidePageState extends State<RequestingRidePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  final List<String> _loadingMessages = [
    "Looking for nearby riders...",
    "Matching your route preferences...",
    "Checking available seats...",
    "Confirming the best ride option...",
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % _loadingMessages.length;
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _cancelRequest() {
    Navigator.pop(context);
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: Colors.white,
            child: IconButton(
              onPressed: _cancelRequest,
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.local_taxi_rounded,
                    color: AppColors.secondary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Requesting ride",
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softPrimary,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.18),
                  width: 8,
                ),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                size: 46,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Finding drivers nearby",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              _loadingMessages[_currentMessageIndex],
              key: ValueKey(_loadingMessages[_currentMessageIndex]),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.mutedText,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              minHeight: 8,
              backgroundColor: Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Trip summary",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          _buildLocationRow(
            icon: Icons.radio_button_checked,
            iconColor: AppColors.primary,
            title: "Pickup",
            value: widget.pickupAddress,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              height: 1,
              color: AppColors.border,
            ),
          ),
          _buildLocationRow(
            icon: Icons.location_on,
            iconColor: AppColors.secondary,
            title: "Destination",
            value: widget.destinationAddress,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMiniInfoCard(
                  title: "Fare",
                  value: "৳ ${widget.fare.toStringAsFixed(0)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniInfoCard(
                  title: "Distance",
                  value: "${widget.distanceKm.toStringAsFixed(1)} km",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniInfoCard(
                  title: "Time",
                  value: "${widget.estimatedMinutes} min",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.softPrimary,
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfoCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "What’s happening now?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 14),
          _StatusTile(
            icon: Icons.search_rounded,
            title: "Searching nearby rides",
            subtitle: "Looking for the most suitable rider around your route.",
          ),
          SizedBox(height: 12),
          _StatusTile(
            icon: Icons.route_rounded,
            title: "Checking route match",
            subtitle: "Comparing pickup and destination with available trips.",
          ),
          SizedBox(height: 12),
          _StatusTile(
            icon: Icons.verified_user_rounded,
            title: "Preparing confirmation",
            subtitle: "You’ll see the best available option as soon as it’s ready.",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _buildSearchingCard(),
                    const SizedBox(height: 18),
                    _buildRouteSummaryCard(),
                    const SizedBox(height: 18),
                    _buildStatusCard(),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _cancelRequest,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          "Cancel Request",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
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

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.softPrimary,
          child: Icon(
            icon,
            size: 20,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}