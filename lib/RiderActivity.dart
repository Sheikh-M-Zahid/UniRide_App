import 'dart:async';

import 'package:flutter/material.dart';
import 'RideRequestModel.dart';
import 'RideRequestService.dart';

class ActiveRidesPage extends StatefulWidget {
  const ActiveRidesPage({super.key});

  @override
  State<ActiveRidesPage> createState() => _ActiveRidesPageState();
}

class _ActiveRidesPageState extends State<ActiveRidesPage> {
  bool rideIsActive = false;
  Timer? _timer;

  ConfirmedRideData? get _currentRide {
    final rides = RideRequestService.getConfirmedRides();
    if (rides.isEmpty) return null;
    return rides.last;
  }

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();

    if (_currentRide != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _toggleRideStatus() {
    setState(() {
      rideIsActive = !rideIsActive;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          rideIsActive ? "Ride activated" : "Ride deactivated",
        ),
      ),
    );
  }

  void _cancelConfirmedRide() {
    final currentRide = _currentRide;
    if (currentRide == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No confirmed ride found"),
        ),
      );
      return;
    }

    final result = RideRequestService.rejectConfirmedRide(
      currentRide.confirmedRideId,
    );

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );
  }

  void _simulateRideRequestsFromActivePage() {
    if (!rideIsActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please activate ride first"),
        ),
      );
      return;
    }

    RideRequestService.addRequest(
      const RideRequestModel(
        passengerName: "Afsana",
        phoneNumber: "01700001111",
        currentLocation: "Girls Hall",
        destination: "Business Faculty",
        distanceKm: 2.7,
        fare: 70,
        estimatedMinutes: 9,
      ),
    );

    RideRequestService.addRequest(
      const RideRequestModel(
        passengerName: "Jubayer",
        phoneNumber: "01611224455",
        currentLocation: "Central Mosque",
        destination: "Science Building",
        distanceKm: 3.9,
        fare: 95,
        estimatedMinutes: 13,
      ),
    );

    _startTimerIfNeeded();
  }

  @override
  Widget build(BuildContext context) {

    final currentRide = _currentRide;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Active Rides"),
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rideIsActive ? "Ride is Active" : "Ride is Inactive",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Switch(
                    value: rideIsActive,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF14B8A6),
                    onChanged: (_) => _toggleRideStatus(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  const Text(
                    "Current Ride Summary",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RideInfoRow(
                    label: "Passenger",
                    value: currentRide?.request.passengerName ?? "No current ride",
                  ),
                  _RideInfoRow(
                    label: "Phone",
                    value: currentRide?.request.phoneNumber ?? "-",
                  ),
                  _RideInfoRow(
                    label: "Pickup",
                    value: currentRide?.request.currentLocation ?? "-",
                  ),
                  _RideInfoRow(
                    label: "Destination",
                    value: currentRide?.request.destination ?? "-",
                  ),
                  _RideInfoRow(
                    label: "Fare",
                    value: currentRide != null
                        ? "৳${currentRide.request.fare.toStringAsFixed(0)}"
                        : "-",
                  ),
                  _RideInfoRow(
                    label: "Time",
                    value: currentRide != null
                        ? "${currentRide.request.estimatedMinutes} min"
                        : "-",
                  ),
                  if (currentRide != null) ...[
                    _RideInfoRow(
                      label: "Free Cancel",
                      value: currentRide.isFreeCancelAvailable
                          ? "${currentRide.remainingFreeCancelSeconds}s left"
                          : "Expired",
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelConfirmedRide,
                        icon: const Icon(Icons.close),
                        label: const Text("Cancel / Reject Ride"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _simulateRideRequestsFromActivePage,
                icon: const Icon(Icons.notifications_active),
                label: const Text("Simulate New Requests"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _RideInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 95,
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