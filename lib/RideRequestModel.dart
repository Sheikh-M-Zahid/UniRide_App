class RideRequestModel {
  final String passengerName;
  final String phoneNumber;
  final String currentLocation;
  final String destination;
  final double distanceKm;
  final double fare;
  final int estimatedMinutes;

  const RideRequestModel({
    required this.passengerName,
    required this.phoneNumber,
    required this.currentLocation,
    required this.destination,
    required this.distanceKm,
    required this.fare,
    required this.estimatedMinutes,
  });

  factory RideRequestModel.fromMap(Map<String, dynamic> map) {
    return RideRequestModel(
      passengerName: map['passengerName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      currentLocation: map['currentLocation'] ?? '',
      destination: map['destination'] ?? '',
      distanceKm: (map['distanceKm'] ?? 0).toDouble(),
      fare: (map['fare'] ?? 0).toDouble(),
      estimatedMinutes: map['estimatedMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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