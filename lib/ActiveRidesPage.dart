import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/auth_api_service.dart';
import 'map_picker_screen.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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

  List<Map<String, dynamic>> routeAlternatives = [];
  int selectedRouteIndex = 0;
  bool routeConfirmed = true; // default route হলে সবসময় true
  bool isLoadingRoutes = false;

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
      } else {
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

    try {
      final geoResponse = await _api.mapsReverseGeocode(
        lat: position.latitude,
        lng: position.longitude,
      );
      final address =
          geoResponse['data']?['formattedAddress']?.toString().trim() ?? '';
      if (address.isNotEmpty && mounted) {
        setState(() {
          currentLocation = address;
        });
      }
    } catch (_) {}
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
        final geoResponse = await _api.mapsReverseGeocode(
          lat: position.latitude,
          lng: position.longitude,
        );
        final address =
            geoResponse['data']?['formattedAddress']?.toString().trim() ?? '';
        if (address.isNotEmpty && mounted) {
          setState(() {
            currentLocation = address;
          });
        }
      } catch (_) {}

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

    await _fetchRouteAlternatives();
  }


  Future<void> _fetchRouteAlternatives() async {
    if (currentLat == null || currentLng == null || destinationLatLng == null) return;

    setState(() {
      isLoadingRoutes = true;
      routeAlternatives = [];
      selectedRouteIndex = 0;
      routeConfirmed = true;
    });

    try {
      final response = await _api.getRouteAlternatives(
        currentLat: currentLat!,
        currentLng: currentLng!,
        destinationLat: destinationLatLng!.latitude,
        destinationLng: destinationLatLng!.longitude,
      );

      final List rawList = response['data'] ?? [];

      if (!mounted) return;
      setState(() {
        routeAlternatives = rawList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        isLoadingRoutes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingRoutes = false);
    }
  }

  Future<void> _onSelectRoute(int index) async {
    if (index == selectedRouteIndex) return;

    if (index == 0) {
      setState(() {
        selectedRouteIndex = 0;
        routeConfirmed = true;
      });
      return;
    }

    final route = routeAlternatives[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm this route?'),
        content: Text(
          'This route is ${route['distanceKm']} km and takes about ${route['durationMinutes']} min. '
              'Passengers along this road will be recommended to you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6)),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        selectedRouteIndex = index;
        routeConfirmed = true;
      });
    }
  }

  Set<Polyline> _buildRoutePolylines() {
    final Set<Polyline> polylines = {};
    final colors = [
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
    ];

    for (int i = 0; i < routeAlternatives.length; i++) {
      final encoded = routeAlternatives[i]['polyline']?.toString();
      if (encoded == null || encoded.isEmpty) continue;

      final points = PolylinePoints()
          .decodePolyline(encoded)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      final isSelected = i == selectedRouteIndex;

      polylines.add(Polyline(
        polylineId: PolylineId('route_$i'),
        points: points,
        color: isSelected ? colors[i % colors.length] : colors[i % colors.length].withOpacity(0.35),
        width: isSelected ? 6 : 3,
      ));
    }
    return polylines;
  }

  Widget _buildRouteSelectionBox() {
    if (destinationLatLng == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Choose your route",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 10),
          if (isLoadingRoutes)
            const Center(child: CircularProgressIndicator())
          else if (routeAlternatives.isEmpty)
            const Text("No route options available.", style: TextStyle(color: Color(0xFF6B7280)))
          else ...[
              Container(
                height: 220,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                clipBehavior: Clip.antiAlias,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: currentLat != null && currentLng != null
                        ? LatLng(currentLat!, currentLng!)
                        : const LatLng(23.8103, 90.4125),
                    zoom: 12,
                  ),
                  polylines: _buildRoutePolylines(),
                  trafficEnabled: true,
                  zoomControlsEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: {
                    if (currentLat != null && currentLng != null)
                      Marker(markerId: const MarkerId('start'), position: LatLng(currentLat!, currentLng!)),
                    if (destinationLatLng != null)
                      Marker(markerId: const MarkerId('end'), position: destinationLatLng!),
                  },
                ),
              ),
              ...routeAlternatives.asMap().entries.map((entry) {
                final index = entry.key;
                final route = entry.value;
                final isSelected = index == selectedRouteIndex;
                final landmarks = (route['landmarks'] as List?)?.map((e) => e.toString()).toList() ?? [];
                final routeLabel = (['Current location', ...landmarks, 'Destination']).join('  →  ');
                final badge = route['isPreviouslyUsed'] == true
                    ? 'Your usual route'
                    : (route['isDefault'] == true ? 'Fastest route' : null);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _onSelectRoute(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFECFEFF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF14B8A6) : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: const Color(0xFF14B8A6),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (badge != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFEFF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(badge,
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                                  ),
                                Text(
                                  routeLabel,
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF374151)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "${route['distanceKm']} km · ${route['durationMinutes']} min",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          if (!routeConfirmed) ...[
            const SizedBox(height: 8),
            const Text(
              "Please confirm your selected route to activate the ride.",
              style: TextStyle(color: Colors.red, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
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

    if (routeAlternatives.isNotEmpty && !routeConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please confirm your selected route first")),
      );
      return;
    }

    try {
      setState(() {
        isConfirming = true;
      });

      final selectedRoute = routeAlternatives.isNotEmpty
          ? routeAlternatives[selectedRouteIndex]
          : null;

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
        routePolyline: selectedRoute?['polyline']?.toString(),
        routeDistanceKm: selectedRoute != null
            ? double.tryParse('${selectedRoute['distanceKm']}')
            : null,
        routeDurationMinutes: selectedRoute != null
            ? int.tryParse('${selectedRoute['durationMinutes']}')
            : null,
        isDefaultRoute: selectedRouteIndex == 0,
        routeLandmarks: (selectedRoute?['landmarks'] as List?)?.map((e) => e.toString()).toList(),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white),
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
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
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
                                  (vehicle['vehicleTypeLabel'] ?? 'Vehicle')
                                      .toString(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: (value) {
                              final matched = vehicles.where(
                                    (vehicle) =>
                                vehicle['vehicleId'].toString() == value,
                              );

                              if (matched.isEmpty) return;

                              setState(() {
                                selectedVehicle = matched.first;
                                vehicleModel =
                                    (selectedVehicle?['model'] ?? '').toString();
                                vehicleNumber =
                                    (selectedVehicle?['vehicleNumber'] ?? '')
                                        .toString();
                                isBike = (selectedVehicle?['vehicleType'] ?? '')
                                    .toString()
                                    .toLowerCase() ==
                                    'bike';
                                selectedSeats = isBike
                                    ? 1
                                    : (selectedVehicle?['totalSeats'] as int? ??
                                    1);
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
                                    final totalSeats =
                                    selectedVehicle?['totalSeats'];
                                    final maxSeats =
                                    (totalSeats is int && totalSeats > 0)
                                        ? totalSeats
                                        : 4;
                                    if (selectedSeats < maxSeats) {
                                      setState(() => selectedSeats++);
                                    }
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: const Color(0xFF14B8A6),
                                ),
                                Builder(
                                  builder: (_) {
                                    final totalSeats =
                                    selectedVehicle?['totalSeats'];
                                    final maxSeats =
                                    (totalSeats is int && totalSeats > 0)
                                        ? totalSeats
                                        : 4;
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
                          const Icon(Icons.my_location,
                              color: Color(0xFF0F766E)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              currentLocation,
                              style:
                              const TextStyle(color: Color(0xFF1F2937)),
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
                            const Icon(Icons.location_on,
                                color: Color(0xFF0F766E)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                destination,
                                style: const TextStyle(
                                    color: Color(0xFF1F2937)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildRouteSelectionBox(),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      side: const BorderSide(
                          color: Color(0xFF14B8A6)),
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
                    onPressed:
                    isConfirming ? null : confirmRide,
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
                        valueColor:
                        AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                        : const Text(
                      "Confirm",
                      style:
                      TextStyle(color: Colors.white),
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