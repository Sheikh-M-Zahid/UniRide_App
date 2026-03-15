import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickedLocation {
  final String address;
  final LatLng latLng;

  const PickedLocation({
    required this.address,
    required this.latLng,
  });
}

class RideOptionModel {
  final String id;
  final String driverName;
  final String driverPhoneNumber;
  final String userType;
  final String vehicleType;
  final String vehicleNumber;
  final int emptySeats;
  final String departureTime;
  final double estimatedFare;
  final String genderPreference;
  final double rating;
  final double distanceAwayKm;
  final bool isAvailable;

  const RideOptionModel({
    required this.id,
    required this.driverName,
    required this.driverPhoneNumber,
    required this.userType,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.emptySeats,
    required this.departureTime,
    required this.estimatedFare,
    required this.genderPreference,
    required this.rating,
    required this.distanceAwayKm,
    this.isAvailable = true,
  });
}