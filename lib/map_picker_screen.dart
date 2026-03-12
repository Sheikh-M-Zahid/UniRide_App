import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  final String googleApiKey;
  final LatLng initialPosition;
  final String title;

  const MapPickerScreen({
    super.key,
    required this.googleApiKey,
    required this.initialPosition,
    required this.title,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? mapController;
  late LatLng selectedPosition;
  String selectedAddress = "Loading address...";
  bool isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    selectedPosition = widget.initialPosition;
    _getAddressFromLatLng(selectedPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    if (!mounted) return;

    setState(() {
      isLoadingAddress = true;
      selectedAddress = "Loading address...";
    });

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=${widget.googleApiKey}",
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data["results"] != null &&
          data["results"].isNotEmpty) {
        setState(() {
          selectedAddress = data["results"][0]["formatted_address"];
          isLoadingAddress = false;
        });
      } else {
        setState(() {
          selectedAddress =
          "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
          isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        selectedAddress =
        "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
        isLoadingAddress = false;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    selectedPosition = position.target;
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(selectedPosition);
  }

  void _confirmLocation() {
    Navigator.pop(
      context,
      {
        "address": selectedAddress,
        "latLng": selectedPosition,
      },
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
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
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          const Center(
            child: Icon(
              Icons.location_pin,
              size: 42,
              color: Color(0xFF14B8A6),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoadingAddress ? "Loading..." : selectedAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Confirm Location",
                        style: TextStyle(
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
        ],
      ),
    );
  }
}