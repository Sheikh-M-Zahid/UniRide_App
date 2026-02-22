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

    // 🔥 Backend API call এখানে হবে
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
      appBar: AppBar(
        title: const Text("Co Ride"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
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
                inputDecoration: const InputDecoration(
                  labelText: "Current Location",
                  border: OutlineInputBorder(),
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
                inputDecoration: const InputDecoration(
                  labelText: "Destination",
                  border: OutlineInputBorder(),
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
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius:
                    BorderRadius.circular(5)),
                title: Text(
                  selectedDate == null
                      ? "Select Date"
                      : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                ),
                trailing:
                const Icon(Icons.calendar_today),
                onTap: pickDate,
              ),

              const SizedBox(height: 15),

              // TIME
              ListTile(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius:
                    BorderRadius.circular(5)),
                title: Text(
                  selectedTime == null
                      ? "Select Time"
                      : selectedTime!
                      .format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: pickTime,
              ),

              const SizedBox(height: 15),

              // VEHICLE TYPE
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Vehicle Type",
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: "Vehicle Number",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              // AVAILABLE SEAT
              TextFormField(
                controller: availableSeatController,
                keyboardType:
                TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Available Seat",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              // PREFERRED GENDER
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Preferred Gender",
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText:
                  "Fare Per Person (BDT)",
                  border: OutlineInputBorder(),
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
                        ? Colors.black
                        : Colors.grey,
                  ),
                  onPressed:
                  isFormValid
                      ? confirmSharing
                      : null,
                  child: const Text(
                    "Confirm & Notify",
                    style:
                    TextStyle(fontSize: 16),
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