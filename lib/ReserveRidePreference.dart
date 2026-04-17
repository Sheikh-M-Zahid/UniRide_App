import 'package:flutter/material.dart';
import 'ReserveRideSummary.dart';
import 'services/auth_api_service.dart';

class ReserveRidePreferencePage extends StatefulWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  final String pickupLocation;
  final String destinationLocation;

  final double totalDistanceKm; // map থেকে আসবে
  final int estimatedTravelMinutes; // map থেকে আসবে
  final double estimatedCost; // backend থেকে আসবে

  const ReserveRidePreferencePage({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.totalDistanceKm,
    required this.estimatedTravelMinutes,
    required this.estimatedCost,
  });

  @override
  State<ReserveRidePreferencePage> createState() =>
      _ReserveRidePreferencePageState();
}

class _ReserveRidePreferencePageState
    extends State<ReserveRidePreferencePage> {
  final AuthApiService _authApiService = AuthApiService();
  bool _isSubmitting = false;
  int selectedSeats = 1;
  String? selectedGenderPreference;
  String? selectedVehicleType;
  final TextEditingController noteController = TextEditingController();

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

  bool get _isFormValid => selectedVehicleType != null;

  String _toApiDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _mapVehicleType(String value) {
    switch (value) {
      case 'Car':
        return 'car';
      case 'Bike':
        return 'bike';
      default:
        return value.toLowerCase();
    }
  }

  String? _mapGenderPreference(String? value) {
    if (value == null || value == 'No Preference') {
      return 'any';
    }

    if (value == 'Male') return 'male';
    if (value == 'Female') return 'female';

    return null;
  }

  Future<void> _validateAndContinue() async {
    if (!_isFormValid || _isSubmitting || selectedVehicleType == null) return;

    final mappedVehicleType = _mapVehicleType(selectedVehicleType!);
    final mappedGender = _mapGenderPreference(selectedGenderPreference);

    if (mappedVehicleType == 'bike' && selectedSeats != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bike ride allows only 1 seat.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authApiService.validateReservePreferences(
        pickupLocation: widget.pickupLocation,
        destinationLocation: widget.destinationLocation,
        totalDistanceKm: widget.totalDistanceKm,
        estimatedTravelMinutes: widget.estimatedTravelMinutes,
        estimatedCost: widget.estimatedCost,
        travelDate: _toApiDate(widget.selectedDate),
        travelTime: _formatTime(widget.selectedTime),
        selectedSeats: selectedSeats,
        genderPreference: mappedGender,
        vehicleType: mappedVehicleType,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReserveRequestSummaryPage(
            selectedDate: widget.selectedDate,
            selectedTime: widget.selectedTime,
            pickupLocation: widget.pickupLocation,
            destinationLocation: widget.destinationLocation,
            selectedSeats: selectedSeats,
            genderPreference: selectedGenderPreference ?? "No Preference",
            vehicleType: selectedVehicleType!,
            totalDistanceKm: widget.totalDistanceKm,
            estimatedTravelMinutes: widget.estimatedTravelMinutes,
            estimatedCost: widget.estimatedCost,
            note: noteController.text,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
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
          "Ride Preferences",
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
                      "Choose your preference",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Select seat, ride type and other preferences before moving to the next step.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),

                    _buildTripInfoCard(),
                    const SizedBox(height: 22),

                    const Text(
                      "Seat needed",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSeatSelector(),

                    const SizedBox(height: 24),

                    const Text(
                      "Gender preference (optional)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChoiceChip(
                          label: "No Preference",
                          isSelected: selectedGenderPreference == null,
                          onTap: () {
                            setState(() {
                              selectedGenderPreference = null;
                            });
                          },
                        ),
                        _buildChoiceChip(
                          label: "Male",
                          isSelected: selectedGenderPreference == "Male",
                          onTap: () {
                            setState(() {
                              selectedGenderPreference = "Male";
                            });
                          },
                        ),
                        _buildChoiceChip(
                          label: "Female",
                          isSelected: selectedGenderPreference == "Female",
                          onTap: () {
                            setState(() {
                              selectedGenderPreference = "Female";
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Ride type",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildVehicleCard(
                            icon: Icons.directions_car_filled_rounded,
                            title: "Car",
                            subtitle: "Comfortable ride",
                            isSelected: selectedVehicleType == "Car",
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "Car";
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildVehicleCard(
                            icon: Icons.two_wheeler_rounded,
                            title: "Bike",
                            subtitle: "Fast and easy",
                            isSelected: selectedVehicleType == "Bike",
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "Bike";
                                selectedSeats = 1;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Fare preview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFarePreviewCard(),

                    const SizedBox(height: 24),

                    const Text(
                      "Note for driver (optional)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                      child: TextField(
                        controller: noteController,
                        maxLines: 4,
                        maxLength: 180,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                          "Write anything helpful for the driver. Example: I will wait at the main gate.",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          counterText: "",
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
                              "Distance and travel time should come from your map route data, and estimated fare should come from backend calculation so the screen stays fully dynamic.",
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
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF14B8A6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Back",
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
                        onPressed: (!_isFormValid || _isSubmitting)
                            ? null
                            : _validateAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          "Next",
                          style: TextStyle(
                            color: !_isFormValid
                                ? Colors.grey.shade600
                                : Colors.white,
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

  Widget _buildTripInfoCard() {
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
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: "Travel date",
            value: _formatDate(widget.selectedDate),
          ),
          const SizedBox(height: 14),
          _buildDivider(),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: "Travel time",
            value: _formatTime(widget.selectedTime),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "How many seats do you need?",
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          _buildSeatButton(
            icon: Icons.remove,
            onTap: selectedSeats > 1
                ? () {
              setState(() {
                selectedSeats--;
              });
            }
                : null,
          ),
          Container(
            width: 52,
            alignment: Alignment.center,
            child: Text(
              "$selectedSeats",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          _buildSeatButton(
            icon: Icons.add,
            onTap: (selectedVehicleType == "Bike")
                ? null
                : selectedSeats < 4
                ? () {
              setState(() {
                selectedSeats++;
              });
            }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFarePreviewCard() {
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
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.route_rounded,
            label: "Total distance",
            value: "${widget.totalDistanceKm.toStringAsFixed(1)} km",
          ),
          const SizedBox(height: 14),
          _buildDivider(),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.timelapse_rounded,
            label: "Estimated time",
            value: "${widget.estimatedTravelMinutes} min",
          ),
          const SizedBox(height: 14),
          _buildDivider(),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.payments_rounded,
            label: "Estimated cost",
            value: "৳ ${widget.estimatedCost.toStringAsFixed(0)}",
            valueColor: const Color(0xFF0F766E),
            valueWeight: FontWeight.bold,
          ),
        ],
      ),
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
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: valueWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade200,
      height: 1,
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF14B8A6) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF14B8A6)
                : const Color(0xFFD1D5DB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1F2937),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFECFEFF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF14B8A6)
                  : const Color(0xFFD1D5DB),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF14B8A6)
                      : const Color(0xFFECFEFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF0F766E),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFFECFEFF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? const Color(0xFFBEE3F8)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? const Color(0xFF0F766E) : Colors.grey,
        ),
      ),
    );
  }
}