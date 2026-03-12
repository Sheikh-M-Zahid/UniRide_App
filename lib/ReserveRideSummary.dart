import 'package:flutter/material.dart';

class ReserveRideSummary extends StatefulWidget {
  final String pickupLocation;
  final String dropLocation;
  final DateTime selectedDateTime;

  const ReserveRideSummary({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.selectedDateTime,
  });

  @override
  State<ReserveRideSummary> createState() => _ReserveRideSummaryState();
}

class _ReserveRideSummaryState extends State<ReserveRideSummary> {
  String selectedVehicle = "car";

  // ⚠️ এগুলো backend থেকে আসবে
  double carFare = 898.29;
  double bikeFare = 450.00;

  bool isLoading = false;

  String _formatDateTime(DateTime dateTime) {
    final List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    int hour = dateTime.hour;
    final int minute = dateTime.minute;
    final String period = hour >= 12 ? "PM" : "AM";

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final String minuteText = minute.toString().padLeft(2, '0');

    return "${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, $hour:$minuteText $period";
  }

  Future<void> confirmReservation() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        content: Text(
          "Your $selectedVehicle reservation has been submitted successfully.",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget vehicleCard({
    required String type,
    required String title,
    required double fare,
  }) {
    bool isSelected = selectedVehicle == type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            selectedVehicle = type;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFECFEFF)
                : Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF14B8A6)
                  : const Color(0xFFE5E7EB),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                type == "car"
                    ? Icons.directions_car
                    : Icons.motorcycle,
                size: 40,
                color: isSelected
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF1F2937),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type == "car"
                          ? "Comfortable for longer trips"
                          : "Fast and budget-friendly",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "BDT ${fare.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF14B8A6),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text(
          "Trip Summary",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 📍 Map Placeholder
          Container(
            height: 250,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: Color(0xFF0F766E),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Google Map will appear here",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.radio_button_checked,
                              color: Color(0xFF14B8A6),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.pickupLocation,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF0F766E),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.dropLocation,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: Color(0xFF0F766E),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _formatDateTime(widget.selectedDateTime),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Choose your vehicle",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
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
                        backgroundColor: const Color(0xFF14B8A6),
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading ? null : confirmReservation,
                      child: isLoading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text(
                        "Confirm Reservation",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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