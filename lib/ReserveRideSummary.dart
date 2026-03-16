import 'package:flutter/material.dart';
import 'UserHome.dart';
import 'ReserveRide.dart';

class ReserveRequestSummaryPage extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  final String pickupLocation;
  final String destinationLocation;

  final int selectedSeats;
  final String genderPreference;
  final String vehicleType;

  final double totalDistanceKm;
  final int estimatedTravelMinutes;
  final double estimatedCost;

  final String note;

  const ReserveRequestSummaryPage({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.selectedSeats,
    required this.genderPreference,
    required this.vehicleType,
    required this.totalDistanceKm,
    required this.estimatedTravelMinutes,
    required this.estimatedCost,
    required this.note,
  });

  String _formatDate(DateTime date) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reservation Summary",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Review your request",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please check all reservation details before confirming your request.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),

                    _buildSectionTitle("Trip details"),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildInfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: "Travel date",
                          value: _formatDate(selectedDate),
                        ),
                        _buildSpacingDivider(),
                        _buildInfoRow(
                          icon: Icons.access_time_rounded,
                          label: "Travel time",
                          value: _formatTime(selectedTime),
                        ),
                        _buildSpacingDivider(),
                        _buildInfoRow(
                          icon: Icons.my_location_rounded,
                          label: "Pickup location",
                          value: pickupLocation,
                        ),
                        _buildSpacingDivider(),
                        _buildInfoRow(
                          icon: Icons.location_on_rounded,
                          label: "Destination",
                          value: destinationLocation,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _buildSectionTitle("Ride preference"),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildInfoRow(
                          icon: Icons.event_seat_rounded,
                          label: "Seats needed",
                          value: "$selectedSeats",
                        ),
                        _buildSpacingDivider(),
                        _buildInfoRow(
                          icon: Icons.person_outline_rounded,
                          label: "Gender preference",
                          value: genderPreference,
                        ),
                        _buildSpacingDivider(),
                        _buildInfoRow(
                          icon: vehicleType == "Car"
                              ? Icons.directions_car_filled_rounded
                              : Icons.two_wheeler_rounded,
                          label: "Ride type",
                          value: vehicleType,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _buildSectionTitle("Fare preview"),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildInfoRow(
                          icon: Icons.route_rounded,
                          label: "Total distance",
                          value: "${totalDistanceKm.toStringAsFixed(1)} km",
                        ),
                        _buildSpacingDivider(),
                        _buildInfoRow(
                          icon: Icons.timelapse_rounded,
                          label: "Estimated time",
                          value: "$estimatedTravelMinutes min",
                        ),
                        _buildSpacingDivider(),
                        _buildInfoRow(
                          icon: Icons.payments_rounded,
                          label: "Estimated cost",
                          value: "৳ ${estimatedCost.toStringAsFixed(0)}",
                          valueColor: const Color(0xFF0F766E),
                          valueWeight: FontWeight.bold,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _buildSectionTitle("Note for driver"),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        note.trim().isEmpty ? "No note added" : note.trim(),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: note.trim().isEmpty
                              ? Colors.grey
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFEFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFBEE3F8),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF0F766E),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "After you confirm, your reserve request will be submitted with the selected details.",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF1F2937),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReserveRide(),
                            ),
                                (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF14B8A6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Color(0xFF14B8A6),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UniRideHomePage(),
                            ),
                                (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSpacingDivider() {
    return Column(
      children: [
        const SizedBox(height: 14),
        Divider(
          color: Colors.grey.shade200,
          height: 1,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xFF1F2937),
    FontWeight valueWeight = FontWeight.w600,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFECFEFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0F766E),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: valueWeight,
              color: valueColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}