import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_picker_screen.dart';

class SendItemLocation extends StatefulWidget {
  final String receiverName;
  final String receiverEmail;
  final String itemName;
  final String itemWeight;

  const SendItemLocation({
    super.key,
    required this.receiverName,
    required this.receiverEmail,
    required this.itemName,
    required this.itemWeight,
  });

  @override
  State<SendItemLocation> createState() => _SendItemLocationState();
}

class _SendItemLocationState extends State<SendItemLocation> {
  final TextEditingController pickupController =
  TextEditingController();

  final TextEditingController destinationController =
  TextEditingController();

  LatLng? pickupLatLng;
  LatLng? destinationLatLng;

  bool isGettingLocation = true;

  bool get isFormValid =>
      pickupController.text.isNotEmpty &&
          destinationController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
      pickupController.text = "Detecting current location...";
    });

    try {
      bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          isGettingLocation = false;
          pickupController.text =
          "Location service is disabled";
        });
        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          isGettingLocation = false;
          pickupController.text =
          "Location permission denied";
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          isGettingLocation = false;
          pickupController.text =
          "Enable location permission from settings";
        });
        return;
      }

      Position position =
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      pickupLatLng = LatLng(
        position.latitude,
        position.longitude,
      );

      try {
        List<Placemark> placemarks =
        await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (!mounted) return;

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final List<String> parts = [
            place.name ?? "",
            place.subLocality ?? "",
            place.locality ?? "",
          ].where((e) => e.trim().isNotEmpty).toList();

          setState(() {
            isGettingLocation = false;
            pickupController.text = parts.isNotEmpty
                ? parts.join(", ")
                : "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
          });
        } else {
          setState(() {
            isGettingLocation = false;
            pickupController.text =
            "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
          });
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          isGettingLocation = false;
          pickupController.text =
          "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isGettingLocation = false;
        pickupController.text =
        "Unable to detect current location";
      });
    }
  }

  Future<void> _pickPickupLocation() async {
    final LatLng initialPosition =
        pickupLatLng ?? const LatLng(23.8103, 90.4125);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: "YOUR_GOOGLE_MAPS_API_KEY",
          initialPosition: initialPosition,
          title: "Select Pickup Location",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        pickupController.text = result["address"];
        pickupLatLng = result["latLng"];
      });
    }
  }

  Future<void> _pickDestinationLocation() async {
    final LatLng initialPosition =
        destinationLatLng ??
            pickupLatLng ??
            const LatLng(23.8103, 90.4125);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: "YOUR_GOOGLE_MAPS_API_KEY",
          initialPosition: initialPosition,
          title: "Select Destination",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        destinationController.text = result["address"];
        destinationLatLng = result["latLng"];
      });
    }
  }

  void confirmSendItem() async {
    print("===== SEND ITEM DATA =====");
    print("Receiver Name: ${widget.receiverName}");
    print("Receiver Email: ${widget.receiverEmail}");
    print("Item Name: ${widget.itemName}");
    print("Item Weight: ${widget.itemWeight}");
    print("Pickup: ${pickupController.text}");
    print("Destination: ${destinationController.text}");
    print("Pickup LatLng: $pickupLatLng");
    print("Destination LatLng: $destinationLatLng");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Email sent to receiver"),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Send Item",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Receiver Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE6FFFA),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.receiverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CURRENT LOCATION (Editable)
            GestureDetector(
              onTap: _pickPickupLocation,
              child: AbsorbPointer(
                child: TextField(
                  controller: pickupController,
                  decoration: InputDecoration(
                    hintText: "Enter Current Location",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.my_location,
                      color: Color(0xFF0F766E),
                    ),
                    suffixIcon: isGettingLocation
                        ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF14B8A6),
                        ),
                      ),
                    )
                        : IconButton(
                      onPressed: _pickPickupLocation,
                      icon: const Icon(
                        Icons.edit_location_alt,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF14B8A6),
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pickup location auto-detected. Tap to change it.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // DESTINATION (Google Autocomplete)
            GooglePlaceAutoCompleteTextField(
              textEditingController: destinationController,
              googleAPIKey: "YOUR_GOOGLE_MAPS_API_KEY",
              inputDecoration: InputDecoration(
                hintText: "Where to?",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Color(0xFF0F766E),
                ),
                suffixIcon: IconButton(
                  onPressed: _pickDestinationLocation,
                  icon: const Icon(
                    Icons.map_outlined,
                    color: Color(0xFF14B8A6),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF14B8A6),
                    width: 1.5,
                  ),
                ),
              ),
              debounceTime: 800,
              countries: const ["bd"],
              isLatLngRequired: true,
              itemClick: (prediction) {
                destinationController.text =
                    prediction.description ?? "";
                destinationController.selection =
                    TextSelection.fromPosition(
                      TextPosition(
                        offset:
                        (prediction.description ?? "").length,
                      ),
                    );

                if (prediction.lat != null &&
                    prediction.lng != null) {
                  destinationLatLng = LatLng(
                    double.tryParse(prediction.lat!) ?? 23.8103,
                    double.tryParse(prediction.lng!) ?? 90.4125,
                  );
                }

                setState(() {});
              },
              getPlaceDetailWithLatLng: (prediction) {
                if (prediction.lat != null &&
                    prediction.lng != null) {
                  destinationLatLng = LatLng(
                    double.tryParse(prediction.lat!) ?? 23.8103,
                    double.tryParse(prediction.lng!) ?? 90.4125,
                  );
                }
              },
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "You can search or pick destination from map.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            const Spacer(),

            // CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid
                      ? const Color(0xFF14B8A6)
                      : Colors.grey,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                isFormValid ? confirmSendItem : null,
                child: const Text(
                  "Confirm",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}