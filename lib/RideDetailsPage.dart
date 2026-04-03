import 'package:flutter/material.dart';
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
  late CoRidePost post;
  bool isConfirming = false;

  @override
  void initState() {
    super.initState();
    post = widget.post;
  }

  bool get isCreator => widget.currentUserId == post.creatorId;

  bool get alreadyJoined =>
      post.confirmedMembers.any((m) => m.id == widget.currentUserId);

  Future<void> _confirmSeat() async {
    if (post.isFull || alreadyJoined || isCreator) return;

    setState(() {
      isConfirming = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    final updatedMembers = [
      ...post.confirmedMembers,
      CoRideMember(
        id: widget.currentUserId,
        name: widget.currentUserName,
        role: 'participant',
      ),
    ];

    setState(() {
      post = CoRidePost(
        id: post.id,
        creatorId: post.creatorId,
        creatorName: post.creatorName,
        pickup: post.pickup,
        destination: post.destination,
        vehicleType: post.vehicleType,
        vehicleNumber: post.vehicleNumber,
        preferredGender: post.preferredGender,
        dateText: post.dateText,
        timeText: post.timeText,
        totalSeats: post.totalSeats,
        confirmedSeats: post.confirmedSeats + 1,
        farePerPerson: post.farePerPerson,
        note: post.note,
        confirmedMembers: updatedMembers,
      );
      isConfirming = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Seat confirmed successfully."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openChatRoom() {
    if (!(alreadyJoined || isCreator)) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoRideChatRoomPage(
          post: post,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
        ),
      ),
    );
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