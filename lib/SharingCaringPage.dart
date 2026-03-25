import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ChatListPage.dart';
import 'map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SharingCaringPage extends StatefulWidget {
  const SharingCaringPage({super.key});

  @override
  State<SharingCaringPage> createState() => _SharingCaringPageState();
}

class _SharingCaringPageState extends State<SharingCaringPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController currentLocationController =
  TextEditingController();
  final TextEditingController destinationController =
  TextEditingController();
  final TextEditingController vehicleNumberController =
  TextEditingController();
  final TextEditingController availableSeatController =
  TextEditingController();
  final TextEditingController fareController =
  TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String? selectedVehicleType;
  String? selectedGender;

  final List<String> vehicleTypes = [
    "Private Car",
    "CNG",
    "Rickshaw",
  ];

  final List<String> genderOptions = [
    "Male",
    "Female",
    "Any",
  ];

  bool get isFormValid {
    return currentLocationController.text.trim().isNotEmpty &&
        destinationController.text.trim().isNotEmpty &&
        selectedDate != null &&
        selectedTime != null &&
        selectedVehicleType != null &&
        availableSeatController.text.trim().isNotEmpty &&
        fareController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    currentLocationController.addListener(_refreshForm);
    destinationController.addListener(_refreshForm);
    vehicleNumberController.addListener(_refreshForm);
    availableSeatController.addListener(_refreshForm);
    fareController.addListener(_refreshForm);
  }

  void _refreshForm() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _pickCurrentLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(
          googleApiKey: "YOUR_GOOGLE_MAPS_API_KEY",
          initialPosition: LatLng(23.8103, 90.4125),
          title: "Select Current Location",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        currentLocationController.text = result["address"] ?? "";
      });
    }
  }

  Future<void> _pickDestinationLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(
          googleApiKey: "YOUR_GOOGLE_MAPS_API_KEY",
          initialPosition: LatLng(23.8103, 90.4125),
          title: "Select Destination",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        destinationController.text = result["address"] ?? "";
      });
    }
  }

  void confirmSharing() async {
    FocusScope.of(context).unfocus();

    print("===== Co Ride =====");
    print(currentLocationController.text);
    print(destinationController.text);
    print(selectedDate);
    print(selectedTime);
    print(selectedVehicleType);
    print(vehicleNumberController.text);
    print(availableSeatController.text);
    print(selectedGender);
    print(fareController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ride shared successfully! Notification sent."),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    currentLocationController.removeListener(_refreshForm);
    destinationController.removeListener(_refreshForm);
    vehicleNumberController.removeListener(_refreshForm);
    availableSeatController.removeListener(_refreshForm);
    fareController.removeListener(_refreshForm);

    currentLocationController.dispose();
    destinationController.dispose();
    vehicleNumberController.dispose();
    availableSeatController.dispose();
    fareController.dispose();

    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF14B8A6),
          title: const Text(
            "Co Ride",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.message, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatListPage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // CURRENT LOCATION
                TextFormField(
                  controller: currentLocationController,
                  readOnly: true,
                  onTap: _pickCurrentLocation,
                  decoration: _inputDecoration(
                    label: "Current Location",
                    prefixIcon: const Icon(
                      Icons.my_location,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // DESTINATION
                TextFormField(
                  controller: destinationController,
                  readOnly: true,
                  onTap: _pickDestinationLocation,
                  decoration: _inputDecoration(
                    label: "Destination",
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // DATE
                ListTile(
                  tileColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF0F766E),
                  ),
                  onTap: pickDate,
                ),

                const SizedBox(height: 15),

                // TIME
                ListTile(
                  tileColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    selectedTime == null
                        ? "Select Time"
                        : selectedTime!.format(context),
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.access_time,
                    color: Color(0xFF0F766E),
                  ),
                  onTap: pickTime,
                ),

                const SizedBox(height: 15),

                // VEHICLE TYPE
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration(
                    label: "Vehicle Type",
                  ),
                  value: selectedVehicleType,
                  items: vehicleTypes
                      .map(
                        (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVehicleType = value;
                    });
                  },
                ),

                const SizedBox(height: 15),

                // VEHICLE NUMBER
                TextFormField(
                  controller: vehicleNumberController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: "Vehicle Number",
                  ),
                ),

                const SizedBox(height: 15),

                // AVAILABLE SEAT
                TextFormField(
                  controller: availableSeatController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: _inputDecoration(
                    label: "Available Seat",
                  ),
                ),

                const SizedBox(height: 15),

                // PREFERRED GENDER
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration(
                    label: "Preferred Gender",
                  ),
                  value: selectedGender,
                  items: genderOptions
                      .map(
                        (gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                ),

                const SizedBox(height: 15),

                // FARE
                TextFormField(
                  controller: fareController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: _inputDecoration(
                    label: "Fare Per Person (BDT)",
                  ),
                ),

                const SizedBox(height: 25),

                // CONFIRM BUTTON
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFormValid
                          ? const Color(0xFF14B8A6)
                          : Colors.grey,
                      disabledBackgroundColor: Colors.grey.shade400,
                      elevation: isFormValid ? 1.5 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isFormValid ? confirmSharing : null,
                    child: const Text(
                      "Confirm & Notify",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}