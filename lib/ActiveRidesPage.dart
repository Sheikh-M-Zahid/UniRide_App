import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/auth_api_service.dart';
import 'map_picker_screen.dart';

class ActiveRidesPage extends StatefulWidget {
  const ActiveRidesPage({super.key});

  @override
  State<ActiveRidesPage> createState() => _ActiveRidesPageState();
}

class _ActiveRidesPageState extends State<ActiveRidesPage> {
  final AuthApiService _api = AuthApiService();

  String riderName = "Rider Name";

  DateTime today = DateTime.now();
  TimeOfDay time = TimeOfDay.now();

  List<Map<String, dynamic>> vehicles = [];
  Map<String, dynamic>? selectedVehicle;

  String vehicleModel = "";
  String vehicleNumber = "";
  int selectedSeats = 1;
  bool isBike = false;

  String currentLocation = "Detecting location...";
  String destination = "Select destination";

  LatLng? destinationLatLng;

  double? currentLat;
  double? currentLng;

  bool isLoading = true;
  bool isConfirming = false;
  bool isCancelling = false;
  bool hasActiveRide = false;
  Map<String, dynamic>? activeRideData;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      await _loadCurrentActiveRide();

      await _getCurrentLocation();
      _startLocationTracking();

      if (!hasActiveRide) {
        await _loadSetupData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentActiveRide() async {
    final response = await _api.getCurrentActiveRide();
    final data = response['data'] ?? {};

    if (!mounted) return;

    setState(() {
      hasActiveRide = data['hasActiveRide'] == true;
      activeRideData = data['activeRide'];
    });
  }

  Future<void> _cancelActiveRide() async {
    try {
      setState(() {
        isCancelling = true;
      });

      await _api.cancelCurrentActiveRide();

      if (!mounted) return;

      setState(() {
        hasActiveRide = false;
        activeRideData = null;
        destination = "Select destination";
        destinationLatLng = null;
      });

      await _loadSetupData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Active ride cancelled successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isCancelling = false;
      });
    }
  }

  Future<void> _loadSetupData() async {
    final response = await _api.getActiveRideSetupData();
    final data = response['data'] ?? {};

    final List rawVehicles = data['vehicles'] ?? [];

    final validVehicles = rawVehicles
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((vehicle) => vehicle['verified'] == true)
        .toList();

    if (!mounted) return;

    setState(() {
      riderName = (data['riderName'] ?? 'Rider Name').toString();
      vehicles = validVehicles;

      if (vehicles.isNotEmpty) {
        selectedVehicle = vehicles.first;
        vehicleModel = (selectedVehicle?['model'] ?? '').toString();
        vehicleNumber = (selectedVehicle?['vehicleNumber'] ?? '').toString();
        isBike = (selectedVehicle?['vehicleType'] ?? '').toString().toLowerCase() == 'bike';
        selectedSeats = isBike ? 1 : (selectedVehicle?['totalSeats'] as int? ?? 1);
      }
      else {
        selectedVehicle = null;
        vehicleModel = "No verified vehicle found";
        vehicleNumber = "";
      }
    });
  }

  // ================= CURRENT LOCATION =================

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service is turned off');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    setState(() {
      currentLat = position.latitude;
      currentLng = position.longitude;
      currentLocation =
      "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
    });
  }

  void _startLocationTracking() {
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((position) async {
      currentLat = position.latitude;
      currentLng = position.longitude;

      if (mounted) {
        setState(() {
          currentLocation =
          "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
        });
      }

      try {
        final response = await _api.updateActiveRideLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        final auto = response['autoComplete'];

        if (auto != null && auto['autoCompleted'] == true) {
          if (!mounted) return;

          setState(() {
            hasActiveRide = false;
            activeRideData = null;
            destination = "Select destination";
            destinationLatLng = null;
          });

          await _loadSetupData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ride completed automatically 🎉"),
            ),
          );
        }

      } catch (_) {}
    });
  }

  // ================= PICK DESTINATION =================

  Future<void> pickDestination() async {
    final initialPosition = (currentLat != null && currentLng != null)
        ? LatLng(currentLat!, currentLng!)
        : const LatLng(23.8103, 90.4125);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: "AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI",
          initialPosition: initialPosition,
          title: "Select Destination",
        ),
      ),
    );

    if (result == null || result is! Map) return;

    final address = result["address"];
    final latLng = result["latLng"];

    if (address == null || latLng == null || latLng is! LatLng) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid destination selected")),
      );
      return;
    }

    setState(() {
      destination = address.toString();
      destinationLatLng = latLng;
    });
  }

  String travelDateToDisplay() {
    return "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
  }

  Future<void> confirmRide() async {
    if (selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No verified vehicle available")),
      );
      return;
    }

    if (currentLat == null || currentLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current location not available")),
      );
      return;
    }

    if (destinationLatLng == null || destination == "Select destination") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select destination")),
      );
      return;
    }

    try {
      setState(() {
        isConfirming = true;
      });

      final response = await _api.activateActiveRide(
        vehicleId: (selectedVehicle!['vehicleId'] ?? '').toString(),
        destination: destination,
        destinationLat: destinationLatLng!.latitude,
        destinationLng: destinationLatLng!.longitude,
        currentLat: currentLat!,
        currentLng: currentLng!,
        currentLocationText: currentLocation,
        availableSeats: selectedSeats,
        travelDate:
        "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}",
        travelTime:
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00",
      );

      final data = response['data'] ?? {};
      final rideId = data['rideId']?.toString();

      await _api.updateActiveRideLocation(
        latitude: currentLat!,
        longitude: currentLng!,
        rideId: rideId,
      );

      if (!mounted) return;

      setState(() {
        hasActiveRide = true;
        activeRideData = {
          'rideId': data['rideId'],
          'pickup': data['currentLocation'],
          'destination': data['destination'],
          'fare': data['totalFare'],
          'travelDate': travelDateToDisplay(),
          'travelTime': time.format(context),
          'status': data['status'],
          'vehicleType': data['vehicleType'],
          'vehicleModel': data['vehicleModel'],
          'vehicleNumber': data['vehicleNumber'],
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ride Activated Successfully"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isConfirming = false;
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF14B8A6),
          title: const Text(
            "Activate your Ride",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        title: const Text(
          "Activate your Ride",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: hasActiveRide
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "You are already active",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "You started your ride from ${activeRideData?['pickup'] ?? 'Unknown location'}",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Destination: ${activeRideData?['destination'] ?? 'Unknown destination'}",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Vehicle: ${activeRideData?['vehicleType'] ?? ''} ${activeRideData?['vehicleModel'] ?? ''}",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Number: ${activeRideData?['vehicleNumber'] ?? ''}",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCancelling ? null : _cancelActiveRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(55),
                ),
                child: isCancelling
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  "Cancel Ride",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    riderName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F2937)),
                  ),
                  Text(
                    "${today.day}-${today.month}-${today.year}",
                    style: const TextStyle(color: Color(0xFF1F2937)),
                  ),
                  Text(
                    time.format(context),
                    style: const TextStyle(color: Color(0xFF1F2937)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: selectedVehicle?['vehicleId']?.toString(),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: vehicles
                        .map(
                          (vehicle) => DropdownMenuItem<String>(
                        value: vehicle['vehicleId'].toString(),
                        child: Text(
                          (vehicle['vehicleTypeLabel'] ?? 'Vehicle').toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      final matched = vehicles.where(
                            (vehicle) => vehicle['vehicleId'].toString() == value,
                      );

                      if (matched.isEmpty) return;

                      setState(() {
                        selectedVehicle = matched.first;
                        vehicleModel = (selectedVehicle?['model'] ?? '').toString();
                        vehicleNumber = (selectedVehicle?['vehicleNumber'] ?? '').toString();
                        isBike = (selectedVehicle?['vehicleType'] ?? '').toString().toLowerCase() == 'bike';
                        selectedSeats = isBike ? 1 : (selectedVehicle?['totalSeats'] as int? ?? 1);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vehicleModel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vehicleNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isBike) ...[
                    const SizedBox(height: 14),
                    const Text(
                      "Available seats",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: selectedSeats > 1
                              ? () => setState(() => selectedSeats--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: const Color(0xFF14B8A6),
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '$selectedSeats',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final totalSeats = selectedVehicle?['totalSeats'];
                            final maxSeats = (totalSeats is int && totalSeats > 0) ? totalSeats : 4;
                            if (selectedSeats < maxSeats) {
                              setState(() => selectedSeats++);
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          color: const Color(0xFF14B8A6),
                        ),
                        Builder(
                          builder: (_) {
                            final totalSeats = selectedVehicle?['totalSeats'];
                            final maxSeats = (totalSeats is int && totalSeats > 0) ? totalSeats : 4;
                            return Text(
                              '/ $maxSeats max',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Color(0xFF0F766E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentLocation,
                      style: const TextStyle(color: Color(0xFF1F2937)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            GestureDetector(
              onTap: pickDestination,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF0F766E)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        destination,
                        style: const TextStyle(color: Color(0xFF1F2937)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      side: const BorderSide(color: Color(0xFF14B8A6)),
                    ),
                    child: const Text(
                      "Back",
                      style: TextStyle(color: Color(0xFF14B8A6)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isConfirming ? null : confirmRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      minimumSize: const Size.fromHeight(55),
                    ),
                    child: isConfirming
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      "Confirm",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}