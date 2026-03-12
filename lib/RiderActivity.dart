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
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Ride Summary",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 12),
                  _RideInfoRow(label: "Passenger", value: "No current ride"),
                  _RideInfoRow(label: "Pickup", value: "-"),
                  _RideInfoRow(label: "Destination", value: "-"),
                  _RideInfoRow(label: "Fare", value: "-"),
                  _RideInfoRow(label: "Time", value: "-"),
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