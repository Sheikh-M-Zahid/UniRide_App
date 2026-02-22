import 'package:flutter/material.dart';

class ReserveRideSummary extends StatefulWidget {
  final String pickupLocation;
  final String dropLocation;
  final DateTime selectedDateTime;

  const ReserveRideSummary({
    Key? key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.selectedDateTime,
  }) : super(key: key);

  @override
  State<ReserveRideSummary> createState() => _ReserveRideSummaryState();
}

class _ReserveRideSummaryState extends State<ReserveRideSummary> {

  String selectedVehicle = "car";

  // ⚠️ এগুলো backend থেকে আসবে
  double carFare = 898.29;
  double bikeFare = 450.00;

  void confirmReservation() async {

    // এখানে backend API call দিবে
    print("Vehicle: $selectedVehicle");
    print("Pickup: ${widget.pickupLocation}");
    print("Drop: ${widget.dropLocation}");
    print("Date: ${widget.selectedDateTime}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ride request sent to riders"),
      ),
    );
  }

  Widget vehicleCard({
    required String type,
    required String title,
    required double fare,
  }) {
    bool isSelected = selectedVehicle == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVehicle = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [

            // 🚗 / 🏍 Icon
            Icon(
              type == "car"
                  ? Icons.directions_car
                  : Icons.motorcycle,
              size: 40,
              color: Colors.black,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Text(
              "BDT ${fare.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reserve a trip"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [

          // 📍 Map Placeholder
          Container(
            height: 250,
            color: Colors.grey.shade300,
            child: const Center(
              child: Text("Google Map এখানে বসবে"),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Choose your vehicle",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🚗 Car
                  vehicleCard(
                    type: "car",
                    title: "Car",
                    fare: carFare,
                  ),

                  // 🏍 Bike
                  vehicleCard(
                    type: "bike",
                    title: "Bike",
                    fare: bikeFare,
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      onPressed: confirmReservation,
                      child: const Text(
                        "Confirm Reservation",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}