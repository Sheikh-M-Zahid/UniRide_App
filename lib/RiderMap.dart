import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'RiderDashboard.dart';
import 'RiderActivityPage.dart';
import 'ActiveRidesPage.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;

  /// Rider current location
  LatLng riderLocation = const LatLng(23.8103, 90.4125);

  /// Current accepted ride info
  /// Later these will come from backend/database
  Map<String, dynamic>? currentRide = {
    "passengerName": "Rahim",
    "phoneNumber": "01712345678",
    "pickupLocationName": "Hall Gate",
    "destinationName": "Main Gate",
    "pickupLatLng": const LatLng(23.8118, 90.4145),
    "destinationLatLng": const LatLng(23.8078, 90.4098),
    "distanceKm": 3.2,
    "estimatedMinutes": 10,
    "fare": 80.0,
    "rideId": "ride_1001",
    "status": "Accepted",
  };

  /// Nearby ride requests
  /// Later backend থেকে আসবে
  final List<Map<String, dynamic>> nearbyRideRequests = [
    {
      "name": "Karim",
      "pickup": "Library Gate",
      "destination": "CSE Building",
      "distanceKm": 2.1,
      "fare": 65.0,
      "eta": 8,
      "pickupLatLng": const LatLng(23.8135, 90.4172),
    },
    {
      "name": "Nusrat",
      "pickup": "Dormitory",
      "destination": "Business Faculty",
      "distanceKm": 3.8,
      "fare": 95.0,
      "eta": 13,
      "pickupLatLng": const LatLng(23.8086, 90.4188),
    },
    {
      "name": "Sadia",
      "pickup": "Central Mosque",
      "destination": "Admin Building",
      "distanceKm": 2.9,
      "fare": 75.0,
      "eta": 9,
      "pickupLatLng": const LatLng(23.8067, 90.4131),
    },
  ];

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

  void _refreshNearbyRequests() {
    /// Later backend call
    /// Example:
    /// GET /nearby-ride-requests
    /// then setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nearby requests refreshed")),
    );
  }

  void _startNavigation() {
    if (currentRide == null) return;

    /// Important:
    /// Start Navigation button চাপা মানে ride create/accept না।
    /// Ride already accepted/created backend-এ save হয়ে থাকবে।
    ///
    /// এখানে future-এ যা করবে:
    /// 1. backend-এ optional navigation_started status update
    /// 2. external map / in-app navigation start
    ///
    /// Example backend call:
    /// PATCH /rides/{rideId}/navigation-started

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Navigation started")),
    );
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
                "${request["distanceKm"].toString()} km",
              ),
              _infoRow(
                "Fare",
                "৳${(request["fare"] as double).toStringAsFixed(0)}",
              ),
              _infoRow(
                "ETA",
                "${request["eta"]} min",
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    /// Later backend/database save জায়গা
                    /// Example:
                    /// POST /rides/accept
                    /// Save accepted ride and update currentRide
                    ///
                    /// setState(() {
                    ///   currentRide = acceptedRideFromBackend;
                    /// });

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text("${request["name"]} request selected"),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Open Request"),
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
      body: Stack(
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
                                "৳${(item["fare"] as double).toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              Text(
                                "${item["distanceKm"]} km",
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
                    "${currentRide!["distanceKm"]} km",
                  ),
                  _infoRow(
                    "ETA",
                    "${currentRide!["estimatedMinutes"]} min",
                  ),
                  _infoRow(
                    "Fare",
                    "৳${(currentRide!["fare"] as double).toStringAsFixed(0)}",
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