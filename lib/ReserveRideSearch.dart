import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'services/auth_api_service.dart';

import 'ReserveDateSelection.dart';
import 'map_picker_screen.dart';

class ReserveRideSearch extends StatefulWidget {
  const ReserveRideSearch({super.key});

  @override
  State<ReserveRideSearch> createState() => _ReserveRideSearchState();
}

class _ReserveRideSearchState extends State<ReserveRideSearch> {
  static const String googleApiKey = "AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI";

  String currentLocation = "Fetching your current location...";
  bool isLoadingLocation = true;
  bool locationError = false;

  final TextEditingController currentLocationController =
  TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  LatLng currentLatLng = const LatLng(23.8103, 90.4125);
  LatLng destinationLatLng = const LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    currentLocationController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<String?> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$googleApiKey",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["results"] != null && data["results"].isNotEmpty) {
          return data["results"][0]["formatted_address"];
        }
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
    return null;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
      locationError = false;
      currentLocation = "Fetching your current location...";
      currentLocationController.text = "Fetching your current location...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          isLoadingLocation = false;
          locationError = true;
          currentLocation =
          "Location service is turned off. Please enable it.";
          currentLocationController.text = currentLocation;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          isLoadingLocation = false;
          locationError = true;
          currentLocation =
          "Location permission denied. Please allow access.";
          currentLocationController.text = currentLocation;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          isLoadingLocation = false;
          locationError = true;
          currentLocation =
          "Location permission permanently denied. Please enable it from settings.";
          currentLocationController.text = currentLocation;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await _getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;
        locationError = false;
        currentLatLng = LatLng(position.latitude, position.longitude);
        currentLocation = address ??
            "Current location: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
        currentLocationController.text = currentLocation;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingLocation = false;
        locationError = true;
        currentLocation =
        "Unable to fetch location right now. Please try again.";
        currentLocationController.text = currentLocation;
      });
    }
  }

  Future<void> _pickCurrentLocationFromMap() async {
    FocusScope.of(context).unfocus();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: googleApiKey,
          initialPosition: currentLatLng,
          title: "Select Pickup Location",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        currentLocationController.text = result["address"];
        currentLocation = result["address"];
        currentLatLng = result["latLng"];
        locationError = false;
        isLoadingLocation = false;
      });
    }
  }

  Future<void> _pickDestinationFromMap() async {
    FocusScope.of(context).unfocus();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: googleApiKey,
          initialPosition: destinationLatLng,
          title: "Select Destination",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        destinationController.text = result["address"];
        destinationLatLng = result["latLng"];
      });
    }
  }

  Future<Map<String, dynamic>> _calculateReserveRide() async {
    final response = await _authApiService.calculateReserveRide(
      pickupLat: currentLatLng.latitude,
      pickupLng: currentLatLng.longitude,
      destinationLat: destinationLatLng.latitude,
      destinationLng: destinationLatLng.longitude,
    );

    return response['data'];
  }

  Future<void> _goToNextPage() async {
    FocusScope.of(context).unfocus();

    if (currentLocationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your pickup location first."),
        ),
      );
      return;
    }

    if (destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your destination first."),
        ),
      );
      return;
    }

    try {
      final data = await _calculateReserveRide();

      final double totalDistanceKm =
      (data['distance_km'] ?? 0).toDouble();
      final int estimatedTravelMinutes =
      (data['estimated_time_min'] ?? 0).toInt();
      final double estimatedCost =
      (data['estimated_cost'] ?? 0).toDouble();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReserveDateSelection(
            pickupLocation: currentLocationController.text.trim(),
            destinationLocation: destinationController.text.trim(),
            totalDistanceKm: totalDistanceKm,
            estimatedTravelMinutes: estimatedTravelMinutes,
            estimatedCost: estimatedCost,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormReady = currentLocationController.text.trim().isNotEmpty &&
        destinationController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reserve a Trip",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Color(0xFF0F766E),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "For me",
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickCurrentLocationFromMap,
              child: AbsorbPointer(
                child: TextField(
                  controller: currentLocationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "Pickup location",
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.my_location,
                      color: Color(0xFF0F766E),
                    ),
                    suffixIcon: IconButton(
                      onPressed: _pickCurrentLocationFromMap,
                      icon: const Icon(
                        Icons.map,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF14B8A6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isLoadingLocation
                    ? "Fetching your current location..."
                    : locationError
                    ? currentLocation
                    : "Auto-detected location. You can also change it manually.",
                style: TextStyle(
                  fontSize: 13,
                  color: locationError ? Colors.red : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 15),

            GestureDetector(
              onTap: _pickDestinationFromMap,
              child: AbsorbPointer(
                child: TextField(
                  controller: destinationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "Destination",
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Color(0xFF0F766E),
                    ),
                    suffixIcon: const Icon(
                      Icons.map,
                      color: Color(0xFF14B8A6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF14B8A6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                destinationController.text.trim().isEmpty
                    ? "Choose your destination before continuing."
                    : "Selected destination: ${destinationController.text}",
                style: TextStyle(
                  fontSize: 13,
                  color: destinationController.text.trim().isEmpty
                      ? Colors.grey
                      : const Color(0xFF1F2937),
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isFormReady ? _goToNextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Next",
                  style: TextStyle(
                    color: isFormReady ? Colors.white : Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}