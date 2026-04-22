class RideRequestModel {
  final String requestId;
  final String passengerName;
  final String phoneNumber;
  final String currentLocation;
  final String destination;
  final double distanceKm;
  final double fare;
  final int estimatedMinutes;

  const RideRequestModel({
    required this.requestId,
    required this.passengerName,
    required this.phoneNumber,
    required this.currentLocation,
    required this.destination,
    required this.distanceKm,
    required this.fare,
    required this.estimatedMinutes,
  });

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory RideRequestModel.fromMap(Map<String, dynamic> map) {
    final meta = map['meta'] is Map<String, dynamic>
        ? map['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    return RideRequestModel(
      requestId: (map['requestId'] ?? meta['requestId'] ?? '').toString(),
      passengerName: (map['passengerName'] ?? map['name'] ?? '').toString(),
      phoneNumber: (map['phoneNumber'] ?? '').toString(),
      currentLocation: (map['currentLocation'] ?? map['pickup'] ?? map['pickupAddress'] ?? '').toString(),
      destination: (map['destination'] ?? map['destinationAddress'] ?? '').toString(),
      distanceKm: _toDouble(map['distanceKm']),
      fare: _toDouble(map['fare']),
      estimatedMinutes: _toInt(map['estimatedMinutes'] ?? map['eta']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'passengerName': passengerName,
      'phoneNumber': phoneNumber,
      'currentLocation': currentLocation,
      'destination': destination,
      'distanceKm': distanceKm,
      'fare': fare,
      'estimatedMinutes': estimatedMinutes,
    };
  }
}