import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_picker_screen.dart';

class ActiveRidesPage extends StatefulWidget {
  const ActiveRidesPage({super.key});

  @override
  State<ActiveRidesPage> createState() => _ActiveRidesPageState();
}

class _ActiveRidesPageState extends State<ActiveRidesPage> {

  String riderName = "Rider Name"; // backend থেকে আসবে

  DateTime today = DateTime.now();
  TimeOfDay time = TimeOfDay.now();

  List<String> vehicleTypes = ["Private Car", "Bike"]; // DB থেকে আসবে
  String? selectedVehicleType;

  String vehicleModel = "Toyota Axio";
  String vehicleNumber = "Dhaka Metro GA-123456";

  String currentLocation = "Detecting location...";
  String destination = "Select destination";

  LatLng? destinationLatLng;

  @override
  void initState() {
    super.initState();
    selectedVehicleType = vehicleTypes.first;
    _getCurrentLocation();
  }

  // ================= CURRENT LOCATION =================

  Future<void> _getCurrentLocation() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position =
    await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      currentLocation =
      "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
    });
  }

  // ================= PICK DESTINATION =================

  Future<void> pickDestination() async {

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: "YOUR_GOOGLE_MAPS_API_KEY",
          initialPosition: const LatLng(23.8103, 90.4125),
          title: "Select Destination",
        ),
      ),
    );

    if (result != null) {
      setState(() {
        destination = result["address"];
        destinationLatLng = result["latLng"];
      });
    }
  }

  void confirmRide() {

    print("===== ACTIVE RIDE =====");
    print(riderName);
    print(selectedVehicleType);
    print(vehicleModel);
    print(vehicleNumber);
    print(currentLocation);
    print(destination);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ride Activated Successfully"),
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
          "Activate your Ride",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= NAME / DATE / TIME =================

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    riderName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F2937)),
                  ),

                  Text(
                    "${today.day}-${today.month}-${today.year}",
                    style: const TextStyle(
                        color: Color(0xFF1F2937)),
                  ),

                  Text(
                    time.format(context),
                    style: const TextStyle(
                        color: Color(0xFF1F2937)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= VEHICLE SECTION =================

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  DropdownButton<String>(
                    value: selectedVehicleType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: vehicleTypes
                        .map(
                          (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedVehicleType = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  Text(
                    vehicleModel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    vehicleNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= CURRENT LOCATION =================

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [

                  const Icon(Icons.my_location,
                      color: Color(0xFF0F766E)),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      currentLocation,
                      style: const TextStyle(
                          color: Color(0xFF1F2937)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ================= DESTINATION =================

            GestureDetector(
              onTap: pickDestination,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(15),
                  border: Border.all(
                      color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [

                    const Icon(Icons.location_on,
                        color: Color(0xFF0F766E)),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        destination,
                        style: const TextStyle(
                            color: Color(0xFF1F2937)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ================= BUTTONS =================

            Row(
              children: [

                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                      const Size.fromHeight(55),
                      side: const BorderSide(
                          color: Color(0xFF14B8A6)),
                    ),
                    child: const Text(
                      "Back",
                      style: TextStyle(
                          color: Color(0xFF14B8A6)),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: ElevatedButton(
                    onPressed: confirmRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF14B8A6),
                      minimumSize:
                      const Size.fromHeight(55),
                    ),
                    child: const Text(
                      "Confirm",
                      style: TextStyle(
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}