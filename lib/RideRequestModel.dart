class RideRequestModel {
  final String requestId;
  final String rideId;
  final String passengerId;
  final String riderId;
  final String passengerName;
  final String passengerEmail;
  final String phoneNumber;
  final String pickupAddress;
  final String currentLocation;
  final String destination;
  final double distanceKm;
  final double fare;
  final int estimatedMinutes;
  final String status;
  final String vehicleType;

  const RideRequestModel({
    required this.requestId,
    required this.rideId,
    required this.passengerId,
    required this.riderId,
    required this.passengerName,
    required this.passengerEmail,
    required this.phoneNumber,
    required this.pickupAddress,
    required this.currentLocation,
    required this.destination,
    required this.distanceKm,
    required this.fare,
    required this.estimatedMinutes,
    required this.status,
    required this.vehicleType,
  });

  // ─── Private Helpers ───────────────────────────────────────────────────────

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ─── Factory ───────────────────────────────────────────────────────────────

  factory RideRequestModel.fromMap(Map<String, dynamic> map) {
    final meta = map['meta'] is Map<String, dynamic>
        ? map['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    final pickup = (map['pickupAddress']
        ?? map['pickup']
        ?? map['currentLocation']
        ?? meta['pickupAddress']
        ?? '').toString();

    return RideRequestModel(
      requestId:        (map['requestId']        ?? meta['requestId']   ?? '').toString(),
      rideId:           (map['rideId']            ?? '').toString(),
      passengerId:      (map['passengerId']        ?? '').toString(),
      riderId:          (map['riderId']            ?? '').toString(),
      passengerName:    (map['passengerName']      ?? map['name']        ?? 'Passenger').toString(),
      passengerEmail:   (map['passengerEmail']     ?? map['email']       ?? '').toString(),
      phoneNumber:      (map['passengerPhone']     ?? map['phoneNumber'] ?? '').toString(),
      pickupAddress:    pickup,
      currentLocation:  (map['currentLocation']   ?? pickup).toString(),
      destination:      (map['destinationAddress'] ?? map['destination'] ?? '').toString(),
      distanceKm:       _toDouble(map['distanceKm']),
      fare:             _toDouble(map['fare']),
      estimatedMinutes: _toInt(map['estimatedMinutes'] ?? map['eta']),
      status:           (map['status']            ?? 'pending').toString(),
      vehicleType:      (map['vehicleType']        ?? '').toString(),
    );
  }

  // ─── toMap ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'requestId':        requestId,
      'rideId':           rideId,
      'passengerId':      passengerId,
      'riderId':          riderId,
      'passengerName':    passengerName,
      'passengerEmail':   passengerEmail,
      'phoneNumber':      phoneNumber,
      'pickupAddress':    pickupAddress,
      'currentLocation':  currentLocation,
      'destination':      destination,
      'distanceKm':       distanceKm,
      'fare':             fare,
      'estimatedMinutes': estimatedMinutes,
      'status':           status,
      'vehicleType':      vehicleType,
    };
  }

  // ─── copyWith ──────────────────────────────────────────────────────────────

  RideRequestModel copyWith({
    String? requestId,
    String? rideId,
    String? passengerId,
    String? riderId,
    String? passengerName,
    String? passengerEmail,
    String? phoneNumber,
    String? pickupAddress,
    String? currentLocation,
    String? destination,
    double? distanceKm,
    double? fare,
    int?    estimatedMinutes,
    String? status,
    String? vehicleType,
  }) {
    return RideRequestModel(
      requestId:        requestId        ?? this.requestId,
      rideId:           rideId           ?? this.rideId,
      passengerId:      passengerId      ?? this.passengerId,
      riderId:          riderId          ?? this.riderId,
      passengerName:    passengerName    ?? this.passengerName,
      passengerEmail:   passengerEmail   ?? this.passengerEmail,
      phoneNumber:      phoneNumber      ?? this.phoneNumber,
      pickupAddress:    pickupAddress    ?? this.pickupAddress,
      currentLocation:  currentLocation  ?? this.currentLocation,
      destination:      destination      ?? this.destination,
      distanceKm:       distanceKm       ?? this.distanceKm,
      fare:             fare             ?? this.fare,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status:           status           ?? this.status,
      vehicleType:      vehicleType      ?? this.vehicleType,
    );
  }
}