import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/auth_api_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final AuthApiService _authApiService = AuthApiService();

  GoogleMapController? mapController;

  LatLng riderLocation = const LatLng(23.8103, 90.4125);
  Map<String, dynamic>? currentRide;
  List<Map<String, dynamic>> nearbyRideRequests = [];

  bool isLoading = true;
  bool isActionLoading = false;

  // Panel state
  bool _isPanelExpanded = true;
  late AnimationController _panelAnimController;
  late Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _panelAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelAnimController,
      curve: Curves.easeInOut,
    );
    _panelAnimController.value = 1.0; // start expanded

    _loadMapDashboard();
  }

  @override
  void dispose() {
    _panelAnimController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _isPanelExpanded = !_isPanelExpanded;
    });
    if (_isPanelExpanded) {
      _panelAnimController.forward();
    } else {
      _panelAnimController.reverse();
    }
  }

  void _collapsePanel() {
    if (_isPanelExpanded) {
      setState(() => _isPanelExpanded = false);
      _panelAnimController.reverse();
    }
  }

  void _expandPanel() {
    if (!_isPanelExpanded) {
      setState(() => _isPanelExpanded = true);
      _panelAnimController.forward();
    }
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
          'pickupLatLng':
          _safeLatLng(ride['pickupLat'], ride['pickupLng']),
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

      await _syncCurrentLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // Decode Google encoded polyline into LatLng list
  List<LatLng> _decodePolyline(String encoded) {
    final polylinePoints = PolylinePoints();
    final result = polylinePoints.decodePolyline(encoded);
    return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
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

      markers.add(Marker(
        markerId: const MarkerId("pickup_location"),
        position: pickup,
        infoWindow: InfoWindow(
          title: currentRide!["pickupLocationName"],
          snippet: "Passenger Pickup",
        ),
      ));

      markers.add(Marker(
        markerId: const MarkerId("destination_location"),
        position: destination,
        infoWindow: InfoWindow(
          title: currentRide!["destinationName"],
          snippet: "Destination",
        ),
      ));
    }

    for (int i = 0; i < nearbyRideRequests.length; i++) {
      final item = nearbyRideRequests[i];
      markers.add(Marker(
        markerId: MarkerId("nearby_request_$i"),
        position: item["pickupLatLng"],
        infoWindow: InfoWindow(
          title: item["name"],
          snippet: item["pickup"],
        ),
      ));
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    if (currentRide == null) return {};

    final String? encoded = currentRide!["encodedPolyline"];

    if (encoded != null && encoded.isNotEmpty) {
      // Real road polyline from Google
      final points = _decodePolyline(encoded);
      return {
        Polyline(
          polylineId: const PolylineId("ride_route"),
          points: points,
          width: 5,
          color: const Color(0xFF14B8A6),
          patterns: [],
        ),
      };
    }

    // Fallback: straight line
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
        CameraPosition(target: riderLocation, zoom: 15),
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
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentRide!["pickupLatLng"], zoom: 16),
      ),
    );
  }

  void _focusDestinationLocation() {
    if (currentRide == null) return;
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentRide!["destinationLatLng"], zoom: 16),
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

  /// Launch Google Maps navigation with correct travel mode
  Future<void> _launchGoogleMapsNavigation() async {
    if (currentRide == null) return;

    final LatLng dest = currentRide!["destinationLatLng"];
    final String vehicleType =
    (currentRide!['vehicleType'] ?? 'bike').toString().toLowerCase();

    // Google Maps directionsmode: driving for car, two-wheeler for bike
    // 'driving' works for both but we set the mode hint
    final String mode = vehicleType == 'car' ? 'driving' : 'driving';

    // Google Maps URL with waypoint at pickup
    final LatLng pickup = currentRide!["pickupLatLng"];
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&origin=${riderLocation.latitude},${riderLocation.longitude}'
          '&waypoints=${pickup.latitude},${pickup.longitude}'
          '&destination=${dest.latitude},${dest.longitude}'
          '&travelmode=$mode',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Maps খোলা যাচ্ছে না")),
      );
    }
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

    setState(() => isActionLoading = true);

    try {
      await _authApiService.startRideNavigation(rideId: rideId);
      await _loadMapDashboard();

      if (!mounted) return;
      setState(() => isActionLoading = false);

      _collapsePanel();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Navigation started. Follow the map."),
          backgroundColor: Color(0xFF14B8A6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _dropPassenger() async {
    if (currentRide == null || isActionLoading) return;

    final rideId = (currentRide!['rideId'] ?? '').toString();
    if (rideId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride ID not found")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Drop Passenger?"),
        content: const Text(
            "Confirm that you have dropped the passenger at the destination."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel",
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Confirm Drop"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isActionLoading = true);

    try {
      await _authApiService.completeRideFromMap(rideId: rideId);
      await _loadMapDashboard();

      if (!mounted) return;
      setState(() => isActionLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Ride completed successfully! Passenger has been dropped off."),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text(e.toString().replaceFirst('Exception: ', ''))),
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
              _infoRow("Distance", _formatDistance(request["distanceKm"])),
              _infoRow("Fare", _formatMoney(request["fare"])),
              _infoRow("ETA", _formatMinutes(request["eta"])),
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
                            content: Text("Request ID not found")),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    setState(() => isActionLoading = true);

                    try {
                      await _authApiService.acceptRideRequestFromMap(
                        requestId: requestId,
                      );
                      await _loadMapDashboard();
                      if (!mounted) return;
                      setState(() => isActionLoading = false);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "${request["name"]} request accepted"),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => isActionLoading = false);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(e
                              .toString()
                              .replaceFirst('Exception: ', '')),
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
        child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
      )
          : Stack(
        children: [
          // ── Google Map ──
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
            compassEnabled: false,
            trafficEnabled: true,
            markers: _markers,
            polylines: _polylines,
            onTap: (_) => _collapsePanel(),
            padding: const EdgeInsets.only(bottom: 160),
          ),

          // ── Quick Action Buttons ──
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

          // ── Nearby Ride Request Cards ──
          Positioned(
            top: 18,
            left: 16,
            right: 82,
            child: SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: nearbyRideRequests.length,
                separatorBuilder: (_, __) =>
                const SizedBox(width: 10),
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
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
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

          // ── Sliding Bottom Panel ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle bar (always visible)
                GestureDetector(
                  onTap: _togglePanel,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! > 200) {
                        _collapsePanel();
                      } else if (details.primaryVelocity! < -200) {
                        _expandPanel();
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          color: Colors.black12,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag pill
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Collapsed summary line
                        if (!_isPanelExpanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  hasActiveRide
                                      ? "Current Ride  •  ${_formatMoney(currentRide!['fare'])}"
                                      : "No active ride",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: Color(0xFF14B8A6),
                                ),
                              ],
                            ),
                          ),
                        if (_isPanelExpanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const [
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF14B8A6),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Expandable content
                SizeTransition(
                  sizeFactor: _panelAnimation,
                  axisAlignment: -1,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: hasActiveRide
                        ? _buildActiveRidePanel()
                        : _buildNoRidePanel(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRidePanel() {
    final String vehicleType =
    (currentRide!['vehicleType'] ?? 'bike').toString().toLowerCase();
    final IconData vehicleIcon =
    vehicleType == 'car' ? Icons.directions_car : Icons.two_wheeler;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Current Ride",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(width: 8),
            Icon(vehicleIcon, size: 20, color: const Color(0xFF14B8A6)),
          ],
        ),
        const SizedBox(height: 12),
        _infoRow("Passenger", currentRide!["passengerName"]),
        _infoRow("Phone", currentRide!["phoneNumber"]),
        _infoRow("Pickup", currentRide!["pickupLocationName"]),
        _infoRow("Destination", currentRide!["destinationName"]),
        _infoRow("Distance", _formatDistance(currentRide!["distanceKm"])),
        _infoRow("ETA", _formatMinutes(currentRide!["estimatedMinutes"])),
        _infoRow("Fare", _formatMoney(currentRide!["fare"])),
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
                  side: const BorderSide(color: Color(0xFF14B8A6)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isActionLoading ? null : _startNavigation,
                icon: isActionLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.navigation),
                label: const Text("Start Navigation"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isActionLoading ? null : _dropPassenger,
            icon: isActionLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.check_circle_outline),
            label: const Text("Drop Passenger"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoRidePanel() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 4),
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
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        SizedBox(height: 8),
      ],
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
          child: Icon(icon, color: const Color(0xFF0F766E)),
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
              style: const TextStyle(color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}