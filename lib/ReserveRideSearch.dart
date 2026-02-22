import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'ReserveDateSelection.dart';

class ReserveRideSearch extends StatefulWidget {
  const ReserveRideSearch({super.key});

  @override
  State<ReserveRideSearch> createState() =>
      _ReserveRideSearchState();
}

class _ReserveRideSearchState
    extends State<ReserveRideSearch> {

  String currentLocation = "Fetching location...";
  final TextEditingController destinationController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    await Geolocator.requestPermission();

    Position position =
    await Geolocator.getCurrentPosition(
        desiredAccuracy:
        LocationAccuracy.high);

    setState(() {
      currentLocation =
      "Lat: ${position.latitude}, Lng: ${position.longitude}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reserve a trip",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [

            const SizedBox(height: 20),

            // FOR ME (No dropdown)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text("For me"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CURRENT LOCATION
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(currentLocation),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // GOOGLE AUTOCOMPLETE DESTINATION
            GooglePlaceAutoCompleteTextField(
              textEditingController:
              destinationController,
              googleAPIKey: "YOUR_GOOGLE_MAPS_API_KEY",
              inputDecoration: InputDecoration(
                hintText: "Where to?",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              debounceTime: 800,
              countries: const ["bd"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng:
                  (prediction) {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const ReserveDateSelection(),
                  ),
                );
              },
              itemClick: (prediction) {
                destinationController.text =
                prediction.description!;
                destinationController
                    .selection =
                    TextSelection.fromPosition(
                      TextPosition(
                          offset:
                          prediction.description!
                              .length),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}