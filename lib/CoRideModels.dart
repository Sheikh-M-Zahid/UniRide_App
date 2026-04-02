import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color softPrimary = Color(0xFFECFEFF);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
}

class CoRideMember {
  final String id;
  final String name;
  final String role; // creator / participant

  const CoRideMember({
    required this.id,
    required this.name,
    required this.role,
  });
}

class CoRidePost {
  final String id;
  final String creatorId;
  final String creatorName;
  final String pickup;
  final String destination;
  final String vehicleType;
  final String vehicleNumber;
  final String preferredGender;
  final String dateText;
  final String timeText;
  final int totalSeats;
  final int confirmedSeats;
  final double farePerPerson;
  final String note;
  final List<CoRideMember> confirmedMembers;

  const CoRidePost({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.pickup,
    required this.destination,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.preferredGender,
    required this.dateText,
    required this.timeText,
    required this.totalSeats,
    required this.confirmedSeats,
    required this.farePerPerson,
    required this.note,
    required this.confirmedMembers,
  });

  int get seatsLeft => totalSeats - confirmedSeats;

  bool get isFull => seatsLeft <= 0;
}

class CoRideChatItem {
  final String postId;
  final String title;
  final String subtitle;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final CoRidePost post;

  const CoRideChatItem({
    required this.postId,
    required this.title,
    required this.subtitle,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.post,
  });
}

class CoRideMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String time;
  final bool isMine;

  const CoRideMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.time,
    required this.isMine,
  });
}