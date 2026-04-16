import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/auth_api_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final AuthApiService _authApiService = AuthApiService();

  GoogleMapController? mapController;

  LatLng riderLocation = const LatLng(23.8103, 90.4125);
  Map<String, dynamic>? currentRide;
  List<Map<String, dynamic>> nearbyRideRequests = [];

  bool isLoading = true;
  bool isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMapDashboard();
  }

  LatLng _safeLatLng(dynamic lat, dynamic lng) {
    final double parsedLat = (lat is num)
        ? lat.toDouble()
        : double.tryParse(lat?.toString() ?? '') ?? 23.8103;

    final double parsedLng = (lng is num)
        ? lng.toDouble()
        : double.tryParse(lng?.toString() ?? '') ?? 90.4125;

    return LatLng(parsedLat, parsedLng);
  }

  String _formatMoney(dynamic fare) {
    final num value =
    (fare is num) ? fare : num.tryParse(fare?.toString() ?? '') ?? 0;
    return "৳${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}";
  }

  String _formatDistance(dynamic distance) {
    final num value = (distance is num)
        ? distance
        : num.tryParse(distance?.toString() ?? '') ?? 0;
    return "${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} km";
  }

  String _formatMinutes(dynamic minutes) {
    final num value = (minutes is num)
        ? minutes
        : num.tryParse(minutes?.toString() ?? '') ?? 0;
    return "${value.toStringAsFixed(0)} min";
  }

  Future<void> _loadMapDashboard() async {
    try {
      final response = await _authApiService.getRiderMapDashboard();
      final data = response['data'] ?? {};

      final riderLoc = data['riderLocation'] ?? {};
      final ride = data['currentRide'];
      final requests = data['nearbyRideRequests'];

      if (!mounted) return;

      setState(() {
        riderLocation = _safeLatLng(riderLoc['lat'], riderLoc['lng']);

        currentRide = ride != null
            ? {
          ...Map<String, dynamic>.from(ride),
          'pickupLatLng': _safeLatLng(ride['pickupLat'], ride['pickupLng']),
          'destinationLatLng': _safeLatLng(
            ride['destinationLat'],
            ride['destinationLng'],
          ),
        }
            : null;

        nearbyRideRequests = requests is List
            ? requests.map<Map<String, dynamic>>((item) {
          final map = Map<String, dynamic>.from(item);
          map['pickupLatLng'] =
              _safeLatLng(map['pickupLat'], map['pickupLng']);
          return map;
        }).toList()
            : [];

        isLoading = false;
      });

      await _syncCurrentLocation(); // ✅ এই লাইন add
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Set<Marker> get _markers {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId("rider_location"),
        position: riderLocation,
        infoWindow: const InfoWindow(title: "Your Location"),
      ),
    };

    if (currentRide != null) {
      final LatLng pickup = currentRide!["pickupLatLng"];
      final LatLng destination = currentRide!["destinationLatLng"];

      markers.add(
        Marker(
          markerId: const MarkerId("pickup_location"),
          position: pickup,
          infoWindow: InfoWindow(
            title: currentRide!["pickupLocationName"],
            snippet: "Passenger Pickup",
          ),
        ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId("destination_location"),
          position: destination,
          infoWindow: InfoWindow(
            title: currentRide!["destinationName"],
            snippet: "Destination",
          ),
        ),
      );
    }

    for (int i = 0; i < nearbyRideRequests.length; i++) {
      final item = nearbyRideRequests[i];
      markers.add(
        Marker(
          markerId: MarkerId("nearby_request_$i"),
          position: item["pickupLatLng"],
          infoWindow: InfoWindow(
            title: item["name"],
            snippet: item["pickup"],
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    if (currentRide == null) return {};

    final LatLng pickup = currentRide!["pickupLatLng"];
    final LatLng destination = currentRide!["destinationLatLng"];

    return {
      Polyline(
        polylineId: const PolylineId("ride_route"),
        points: [riderLocation, pickup, destination],
        width: 5,
        color: const Color(0xFF14B8A6),
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _goToMyLocation() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: riderLocation,
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _syncCurrentLocation() async {
    try {
      await _authApiService.updateRiderLocation(
        lat: riderLocation.latitude,
        lng: riderLocation.longitude,
      );
    } catch (_) {}
  }

  void _focusPickupLocation() {
    if (currentRide == null) return;

    final LatLng pickup = currentRide!["pickupLatLng"];
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pickup,
          zoom: 16,
        ),
      ),
    );
  }

  void _focusDestinationLocation() {
    if (currentRide == null) return;

    final LatLng destination = currentRide!["destinationLatLng"];
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: destination,
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> _refreshNearbyRequests() async {
    await _loadMapDashboard();
    await _syncCurrentLocation();


    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nearby requests refreshed")),
    );
  }

  Future<void> _startNavigation() async {
    if (currentRide == null || isActionLoading) return;

    final rideId = (currentRide!['rideId'] ?? '').toString();

    if (rideId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride ID not found")),
      );
      return;
    }

    setState(() {
      isActionLoading = true;
    });

    try {
      await _authApiService.startRideNavigation(rideId: rideId);
      await _loadMapDashboard();

      if (!mounted) return;

      setState(() {
        isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Navigation started")),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _openNearbyRequest(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Nearby Ride Request",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              _infoRow("Passenger", request["name"]),
              _infoRow("Pickup", request["pickup"]),
              _infoRow("Destination", request["destination"]),
              _infoRow(
                "Distance",
                _formatDistance(request["distanceKm"]),
              ),
              _infoRow(
                "Fare",
                _formatMoney(request["fare"]),
              ),
              _infoRow(
                "ETA",
                _formatMinutes(request["eta"]),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isActionLoading
                      ? null
                      : () async {
                    final requestId =
                    (request["requestId"] ?? "").toString();

                    if (requestId.isEmpty) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text("Request ID not found"),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    setState(() {
                      isActionLoading = true;
                    });

                    try {
                      await _authApiService.acceptRideRequestFromMap(
                        requestId: requestId,
                      );
                      await _loadMapDashboard();

                      if (!mounted) return;

                      setState(() {
                        isActionLoading = false;
                      });

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content:
                          Text("${request["name"]} request accepted"),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      setState(() {
                        isActionLoading = false;
                      });

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Accept Request"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveRide = currentRide != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Map",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF14B8A6),
        ),
      )
          : Stack(
        children: [
          /// Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: riderLocation,
              zoom: 14.5,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),

          /// Quick Action Buttons
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _circleButton(
                  icon: Icons.my_location,
                  onTap: _goToMyLocation,
                ),
                const SizedBox(height: 10),
                _circleButton(
                  icon: Icons.refresh,
                  onTap: _refreshNearbyRequests,
                ),
                const SizedBox(height: 10),
                _circleButton(
                  icon: Icons.flag,
                  onTap: _focusPickupLocation,
                ),
                const SizedBox(height: 10),
                _circleButton(
                  icon: Icons.location_on,
                  onTap: _focusDestinationLocation,
                ),
              ],
            ),
          ),

          /// Nearby Ride Requests
          Positioned(
            top: 18,
            left: 16,
            right: 82,
            child: SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: nearbyRideRequests.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = nearbyRideRequests[index];

                  return InkWell(
                    onTap: () => _openNearbyRequest(item),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 190,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["name"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item["pickup"],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatMoney(item["fare"]),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              Text(
                                _formatDistance(item["distanceKm"]),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// Bottom Ride Info Panel
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 14,
                    color: Colors.black12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: hasActiveRide
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Current Ride",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow("Passenger", currentRide!["passengerName"]),
                  _infoRow("Phone", currentRide!["phoneNumber"]),
                  _infoRow("Pickup", currentRide!["pickupLocationName"]),
                  _infoRow(
                    "Destination",
                    currentRide!["destinationName"],
                  ),
                  _infoRow(
                    "Distance",
                    _formatDistance(currentRide!["distanceKm"]),
                  ),
                  _infoRow(
                    "ETA",
                    _formatMinutes(currentRide!["estimatedMinutes"]),
                  ),
                  _infoRow(
                    "Fare",
                    _formatMoney(currentRide!["fare"]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _focusPickupLocation,
                          icon: const Icon(Icons.place),
                          label: const Text("Pickup"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(
                              color: Color(0xFF14B8A6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startNavigation,
                          icon: const Icon(Icons.navigation),
                          label: const Text("Start Navigation"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "No active ride right now",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Nearby ride requests are shown above.",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
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

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: const Color(0xFF0F766E),
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}