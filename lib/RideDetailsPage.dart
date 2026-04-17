import 'dart:async';

import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'CoRideModels.dart';
import 'CoRideChatRoom.dart';

class CoRideDetailsPage extends StatefulWidget {
  final CoRidePost post;
  final String currentUserId;
  final String currentUserName;

  const CoRideDetailsPage({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<CoRideDetailsPage> createState() => _CoRideDetailsPageState();
}

class _CoRideDetailsPageState extends State<CoRideDetailsPage> {
  bool _isRefreshingDetails = false;
  final AuthApiService _authApiService = AuthApiService();
  late CoRidePost post;
  bool isConfirming = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    post = widget.post;
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  bool get isCreator => widget.currentUserId == post.creatorId;

  bool get alreadyJoined =>
      post.confirmedMembers.any((m) => m.id == widget.currentUserId);

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _safeText(dynamic value, {String fallback = ''}) {
    final text = value?.toString() ?? '';
    return text.trim().isEmpty ? fallback : text;
  }

  String _buildFullName(Map<String, dynamic> json, {String fallback = 'User'}) {
    final first = (json['first_name'] ?? '').toString().trim();
    final last = (json['last_name'] ?? '').toString().trim();
    final full = '$first $last'.trim();
    return full.isEmpty ? fallback : full;
  }

  List<Map<String, dynamic>> _safeParticipants(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  CoRidePost _buildUpdatedPost({
    required Map<String, dynamic> ride,
    required List<Map<String, dynamic>> participants,
  }) {
    final creatorId = _safeText(ride['rider_id'], fallback: post.creatorId);

    final updatedMembers = <CoRideMember>[
      CoRideMember(
        id: creatorId,
        name: _buildFullName(ride, fallback: post.creatorName),
        role: 'creator',
      ),
      ...participants.map(
            (p) => CoRideMember(
          id: _safeText(p['passenger_id']),
          name: _buildFullName(p, fallback: 'User'),
          role: (p['confirmed'] == true) ? 'confirmed' : 'participant',
        ),
      ),
    ];

    return CoRidePost(
      id: post.id,
      sessionId: post.sessionId,
      creatorId: creatorId,
      creatorName: _buildFullName(ride, fallback: post.creatorName),
      creatorPhoto: post.creatorPhoto,
      pickup: _safeText(ride['start_location'], fallback: post.pickup),
      destination: _safeText(ride['destination'], fallback: post.destination),
      vehicleType: _safeText(ride['vehicle_type'], fallback: post.vehicleType),
      vehicleNumber:
      _safeText(ride['number_plate'], fallback: post.vehicleNumber),
      preferredGender: _safeText(
        ride['gender_preference'],
        fallback: post.preferredGender,
      ),
      dateText: _safeText(ride['travel_date'], fallback: post.dateText),
      timeText: _safeText(ride['travel_time'], fallback: post.timeText),
      totalSeats: _toInt(ride['total_seats'], fallback: post.totalSeats),
      confirmedSeats: participants.length,
      farePerPerson: _toDouble(ride['total_fare'], fallback: post.farePerPerson),
      note: _safeText(ride['note'], fallback: post.note),
      confirmedMembers: updatedMembers,
    );
  }

  Future<void> _confirmSeat() async {
    if (post.isFull || alreadyJoined || isCreator || isConfirming) return;

    setState(() {
      isConfirming = true;
    });

    try {
      await _authApiService.joinRide(
        rideId: post.id,
        fare: post.farePerPerson,
      );

      if (!mounted) return;

      final detailsResponse = await _authApiService.getRideDetails(
        rideId: post.id,
      );

      final data = Map<String, dynamic>.from(detailsResponse['data'] ?? {});
      final ride = Map<String, dynamic>.from(data['ride'] ?? {});
      final participants = _safeParticipants(data['participants']);

      setState(() {
        post = _buildUpdatedPost(
          ride: ride,
          participants: participants,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seat confirmed successfully."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isConfirming = false;
      });
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!mounted) return;
      if (!_isRefreshingDetails && !isConfirming) {
        await _reloadRideDetails();
      }
    });
  }

  Future<void> _reloadRideDetails() async {
    if (_isRefreshingDetails) return;

    _isRefreshingDetails = true;

    try {
      final detailsResponse = await _authApiService.getRideDetails(
        rideId: post.id,
      );

      if (!mounted) return;

      final data = Map<String, dynamic>.from(detailsResponse['data'] ?? {});
      final ride = Map<String, dynamic>.from(data['ride'] ?? {});
      final participants = _safeParticipants(data['participants']);

      setState(() {
        post = _buildUpdatedPost(
          ride: ride,
          participants: participants,
        );
      });
    } catch (_) {
      // silent refresh fail
    } finally {
      _isRefreshingDetails = false;
    }
  }

  Future<void> _openChatRoom() async {
    await _reloadRideDetails();

    if (!(alreadyJoined || isCreator)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can open chat only after joining or as creator.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoRideChatRoomPage(
          post: post,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
        ),
      ),
    );

    if (!mounted) return;
    await _reloadRideDetails();
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
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.text),
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
                  Icon(Icons.volunteer_activism, color: AppColors.secondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Co Ride details",
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

  Widget _buildMainCard() {
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.softPrimary,
                child: Text(
                  post.creatorName.isNotEmpty
                      ? post.creatorName[0].toUpperCase()
                      : "C",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.creatorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Post creator",
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSeatBadge(),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoRow("Pickup", post.pickup, Icons.my_location),
          const SizedBox(height: 14),
          _buildInfoRow("Destination", post.destination, Icons.location_on),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard("Date", post.dateText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniCard("Time", post.timeText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard("Vehicle", post.vehicleType),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniCard("Number", post.vehicleNumber),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard("Gender", post.preferredGender),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniCard(
                  "Fare",
                  "৳ ${post.farePerPerson.toStringAsFixed(0)}",
                ),
              ),
            ],
          ),
          if (post.note.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                post.note,
                style: const TextStyle(
                  color: AppColors.text,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeatBadge() {
    final Color bg = post.isFull ? const Color(0xFFFEE2E2) : AppColors.softPrimary;
    final Color fg = post.isFull ? AppColors.danger : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        post.isFull ? "Full" : "${post.seatsLeft} seat left",
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.softPrimary,
          child: Icon(icon, size: 18, color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14.5,
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

  Widget _buildMiniCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersCard() {
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
        children: [
          const Text(
            "Confirmed members",
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...post.confirmedMembers.map(
                (member) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.softPrimary,
                    child: Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : "U",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      member.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: member.role == 'creator'
                          ? AppColors.softPrimary
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      member.role == 'creator' ? "Creator" : "Confirmed",
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
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

  Widget _buildBottomButtons() {
    String buttonText = "Confirm seat";
    VoidCallback? onPressed = _confirmSeat;
    Color buttonColor = AppColors.primary;

    if (isCreator) {
      buttonText = "Open chat";
      onPressed = _openChatRoom;
      buttonColor = AppColors.secondary;
    } else if (alreadyJoined) {
      buttonText = "Open chat";
      onPressed = _openChatRoom;
      buttonColor = AppColors.secondary;
    } else if (post.isFull) {
      buttonText = "Seat full";
      onPressed = null;
      buttonColor = Colors.grey;
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isConfirming ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              disabledBackgroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isConfirming
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildMainCard(),
                    const SizedBox(height: 18),
                    _buildMembersCard(),
                    const SizedBox(height: 28),
                    _buildBottomButtons(),
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