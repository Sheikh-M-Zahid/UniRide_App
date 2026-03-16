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

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  List<dynamic> placePredictions = [];
  bool isSearchingPlaces = false;

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
          searchController.text = selectedAddress;
          isLoadingAddress = false;
        });
      } else {
        setState(() {
          selectedAddress =
          "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
          searchController.text = selectedAddress;
          isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        selectedAddress =
        "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
        searchController.text = selectedAddress;
        isLoadingAddress = false;
      });
    }
  }

  Future<void> _searchPlaces(String input) async {
    if (input.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        placePredictions = [];
        isSearchingPlaces = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      isSearchingPlaces = true;
    });

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=${widget.googleApiKey}",
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data["predictions"] != null) {
        setState(() {
          placePredictions = data["predictions"];
          isSearchingPlaces = false;
        });
      } else {
        setState(() {
          placePredictions = [];
          isSearchingPlaces = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        placePredictions = [];
        isSearchingPlaces = false;
      });
    }
  }

  Future<void> _selectPrediction(dynamic prediction) async {
    final placeId = prediction["place_id"];
    final description = prediction["description"] ?? "";

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${widget.googleApiKey}",
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["result"] != null &&
          data["result"]["geometry"] != null &&
          data["result"]["geometry"]["location"] != null) {
        final location = data["result"]["geometry"]["location"];
        final latLng = LatLng(
          (location["lat"] as num).toDouble(),
          (location["lng"] as num).toDouble(),
        );

        selectedPosition = latLng;

        await mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latLng,
              zoom: 17,
            ),
          ),
        );

        if (!mounted) return;
        setState(() {
          searchController.text = description;
          placePredictions = [];
        });

        searchFocusNode.unfocus();
        await _getAddressFromLatLng(latLng);
      }
    } catch (e) {
      // ignore for now
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
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showPredictionBox = placePredictions.isNotEmpty;

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
            child: IgnorePointer(
              child: Icon(
                Icons.location_pin,
                size: 42,
                color: Color(0xFF14B8A6),
              ),
            ),
          ),

          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
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
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    onChanged: _searchPlaces,
                    decoration: InputDecoration(
                      hintText: "Search location",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF6B7280),
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            placePredictions = [];
                          });
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),

                if (isSearchingPlaces)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          color: Colors.black12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Searching places...",
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (showPredictionBox)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          color: Colors.black12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: placePredictions.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                      itemBuilder: (context, index) {
                        final item = placePredictions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF14B8A6),
                          ),
                          title: Text(
                            item["structured_formatting"]?["main_text"] ??
                                item["description"] ??
                                "",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          subtitle: Text(
                            item["structured_formatting"]?["secondary_text"] ??
                                "",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          onTap: () => _selectPrediction(item),
                        );
                      },
                    ),
                  ),
              ],
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
                  const Text(
                    "Selected Location",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
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