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
  final String role; // creator / confirmed / participant

  const CoRideMember({
    required this.id,
    required this.name,
    required this.role,
  });

  factory CoRideMember.fromJson(Map<String, dynamic> json) {
    return CoRideMember(
      id: (json['id'] ?? json['user_id'] ?? json['passenger_id'] ?? '')
          .toString(),
      name: (() {
        final first = (json['first_name'] ?? '').toString().trim();
        final last = (json['last_name'] ?? '').toString().trim();
        final full = '$first $last'.trim();
        return full.isNotEmpty
            ? full
            : (json['name'] ?? json['member_name'] ?? 'User').toString();
      })(),
      role: (json['role'] ?? 'participant').toString(),
    );
  }
}

class CoRidePost {
  // Core identity
  final String id;
  final String sessionId;

  // Creator
  final String creatorId;
  final String creatorName;
  final String creatorPhoto;

  // Location
  final String pickup;
  final String destination;

  // Details
  final String vehicleType;
  final String vehicleNumber;
  final String preferredGender;
  final String dateText;
  final String timeText;
  final int totalSeats;
  final int confirmedSeats;
  final double farePerPerson;
  final String note;

  // Members
  final List<CoRideMember> confirmedMembers;

  const CoRidePost({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.creatorName,
    required this.creatorPhoto,
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

  // -------- Chat/List page compatibility aliases --------
  String get pickupLocation => pickup;
  String get destinationLocation => destination;
  String get subtitleRoute => '$pickup → $destination';

  // -------- Computed helpers for RideDetailsPage --------
  int get seatsLeft {
    final left = totalSeats - confirmedSeats;
    return left < 0 ? 0 : left;
  }

  bool get isFull => seatsLeft <= 0;

  CoRidePost copyWith({
    String? id,
    String? sessionId,
    String? creatorId,
    String? creatorName,
    String? creatorPhoto,
    String? pickup,
    String? destination,
    String? vehicleType,
    String? vehicleNumber,
    String? preferredGender,
    String? dateText,
    String? timeText,
    int? totalSeats,
    int? confirmedSeats,
    double? farePerPerson,
    String? note,
    List<CoRideMember>? confirmedMembers,
  }) {
    return CoRidePost(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorPhoto: creatorPhoto ?? this.creatorPhoto,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      preferredGender: preferredGender ?? this.preferredGender,
      dateText: dateText ?? this.dateText,
      timeText: timeText ?? this.timeText,
      totalSeats: totalSeats ?? this.totalSeats,
      confirmedSeats: confirmedSeats ?? this.confirmedSeats,
      farePerPerson: farePerPerson ?? this.farePerPerson,
      note: note ?? this.note,
      confirmedMembers: confirmedMembers ?? this.confirmedMembers,
    );
  }

  factory CoRidePost.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['confirmed_members'] ?? json['confirmedMembers'] ?? [];
    final members = membersRaw is List
        ? membersRaw
        .whereType<Map>()
        .map((e) => CoRideMember.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        : <CoRideMember>[];

    int parseInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    double parseDouble(dynamic value, [double fallback = 0]) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    String parseName(Map<String, dynamic> data, String fallbackKey) {
      final first = (data['first_name'] ?? '').toString().trim();
      final last = (data['last_name'] ?? '').toString().trim();
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      return (data[fallbackKey] ?? '').toString();
    }

    return CoRidePost(
      id: (json['id'] ?? json['ride_id'] ?? json['session_id'] ?? '').toString(),
      sessionId:
      (json['sessionId'] ?? json['session_id'] ?? json['ride_id'] ?? '')
          .toString(),
      creatorId:
      (json['creator_id'] ?? json['created_by'] ?? json['rider_id'] ?? '')
          .toString(),
      creatorName: parseName(json, 'creator_name'),
      creatorPhoto: (json['creator_photo'] ?? json['creatorPhoto'] ?? '')
          .toString(),
      pickup: (json['pickup'] ??
          json['pickup_location'] ??
          json['start_location'] ??
          '')
          .toString(),
      destination: (json['destination'] ??
          json['destination_location'] ??
          '')
          .toString(),
      vehicleType:
      (json['vehicle_type'] ?? json['vehicleType'] ?? '').toString(),
      vehicleNumber:
      (json['number_plate'] ?? json['vehicleNumber'] ?? '').toString(),
      preferredGender: (json['gender_preference'] ??
          json['preferredGender'] ??
          'any')
          .toString(),
      dateText:
      (json['travel_date'] ?? json['dateText'] ?? '').toString(),
      timeText:
      (json['travel_time'] ?? json['timeText'] ?? '').toString(),
      totalSeats: parseInt(json['total_seats'], 0),
      confirmedSeats: parseInt(
        json['confirmed_seats'] ?? json['confirmedSeats'],
        members.length,
      ),
      farePerPerson: parseDouble(
        json['fare_per_person'] ?? json['total_fare'],
        0,
      ),
      note: (json['note'] ?? '').toString(),
      confirmedMembers: members,
    );
  }
}

class CoRideChatItem {
  final String sessionId;
  final String title;
  final String subtitle;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final CoRidePost post;

  const CoRideChatItem({
    required this.sessionId,
    required this.title,
    required this.subtitle,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.post,
  });

  CoRideChatItem copyWith({
    String? sessionId,
    String? title,
    String? subtitle,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
    CoRidePost? post,
  }) {
    return CoRideChatItem(
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      post: post ?? this.post,
    );
  }
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

  factory CoRideMessage.fromJson(Map<String, dynamic> json) {
    return CoRideMessage(
      id: (json['id'] ?? json['chat_id'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['sender_id'] ?? '').toString(),
      senderName:
      (json['senderName'] ?? json['sender_name'] ?? 'User').toString(),
      text: (json['text'] ?? json['message_text'] ?? '').toString(),
      time: (json['time'] ?? json['sent_at'] ?? '').toString(),
      isMine: json['isMine'] == true || json['is_mine'] == true,
    );
  }

  CoRideMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    String? time,
    bool? isMine,
  }) {
    return CoRideMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      time: time ?? this.time,
      isMine: isMine ?? this.isMine,
    );
  }
}