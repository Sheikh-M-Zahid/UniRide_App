import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'ChatListPage.dart';

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
    return currentLocationController.text.isNotEmpty &&
        destinationController.text.isNotEmpty &&
        selectedDate != null &&
        selectedTime != null &&
        selectedVehicleType != null &&
        availableSeatController.text.isNotEmpty &&
        fareController.text.isNotEmpty;
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    TimeOfDay? picked =
    await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void confirmSharing() async {

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
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            children: [

              // CURRENT LOCATION
              GooglePlaceAutoCompleteTextField(
                textEditingController:
                currentLocationController,
                googleAPIKey: "YOUR_GOOGLE_MAPS_API_KEY",
                inputDecoration: InputDecoration(
                  labelText: "Current Location",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.my_location, color: Color(0xFF0F766E)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                debounceTime: 800,
                countries: const ["bd"],
                isLatLngRequired: false,
                itemClick: (prediction) {
                  currentLocationController.text =
                  prediction.description!;
                  currentLocationController.selection =
                      TextSelection.fromPosition(
                        TextPosition(
                            offset: prediction
                                .description!.length),
                      );
                  setState(() {});
                },
              ),

              const SizedBox(height: 15),

              // DESTINATION
              GooglePlaceAutoCompleteTextField(
                textEditingController:
                destinationController,
                googleAPIKey: "YOUR_GOOGLE_MAPS_API_KEY",
                inputDecoration: InputDecoration(
                  labelText: "Destination",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF0F766E)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                debounceTime: 800,
                countries: const ["bd"],
                isLatLngRequired: false,
                itemClick: (prediction) {
                  destinationController.text =
                  prediction.description!;
                  destinationController.selection =
                      TextSelection.fromPosition(
                        TextPosition(
                            offset: prediction
                                .description!.length),
                      );
                  setState(() {});
                },
              ),

              const SizedBox(height: 15),

              // DATE
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    borderRadius:
                    BorderRadius.circular(12)),
                title: Text(
                  selectedDate == null
                      ? "Select Date"
                      : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                ),
                trailing:
                const Icon(Icons.calendar_today, color: Color(0xFF0F766E)),
                onTap: pickDate,
              ),

              const SizedBox(height: 15),

              // TIME
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    borderRadius:
                    BorderRadius.circular(12)),
                title: Text(
                  selectedTime == null
                      ? "Select Time"
                      : selectedTime!
                      .format(context),
                ),
                trailing: const Icon(Icons.access_time, color: Color(0xFF0F766E)),
                onTap: pickTime,
              ),

              const SizedBox(height: 15),

              // VEHICLE TYPE
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Vehicle Type",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                ),
                value: selectedVehicleType,
                items: vehicleTypes
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
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
                decoration: InputDecoration(
                  labelText: "Vehicle Number",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 15),

              // AVAILABLE SEAT
              TextFormField(
                controller: availableSeatController,
                keyboardType:
                TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Available Seat",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 15),

              // PREFERRED GENDER
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Preferred Gender",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                ),
                value: selectedGender,
                items: genderOptions
                    .map((gender) =>
                    DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
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
                keyboardType:
                TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                  "Fare Per Person (BDT)",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 25),

              // CONFIRM BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    isFormValid
                        ? const Color(0xFF14B8A6)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                  isFormValid
                      ? confirmSharing
                      : null,
                  child: const Text(
                    "Confirm & Notify",
                    style:
                    TextStyle(
                        fontSize: 16,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}