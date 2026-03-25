import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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
  bool isMapMoving = false;
  bool isFetchingCurrentLocation = false;

  Timer? _debounce;
  LatLng? currentDeviceLocation;

  static const Color primaryColor = Color(0xFF14B8A6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color mutedTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color bgColor = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    selectedPosition = widget.initialPosition;
    _getAddressFromLatLng(selectedPosition);
  }

  bool get _isOnCurrentLocation {
    if (currentDeviceLocation == null) return false;

    final distance = Geolocator.distanceBetween(
      currentDeviceLocation!.latitude,
      currentDeviceLocation!.longitude,
      selectedPosition.latitude,
      selectedPosition.longitude,
    );

    return distance <= 20;
  }

  bool get _canConfirm {
    return !isLoadingAddress && !_isOnCurrentLocation;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

        _showSnackBar("Failed to fetch exact address.");
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        selectedAddress =
        "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
        searchController.text = selectedAddress;
        isLoadingAddress = false;
      });

      _showSnackBar("No internet connection or address fetch failed.");
    }
  }

  void _searchPlaces(String input) {
    _debounce?.cancel();

    if (input.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        placePredictions = [];
        isSearchingPlaces = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () async {
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

          _showSnackBar("Failed to search places.");
        }
      } catch (e) {
        if (!mounted) return;

        setState(() {
          placePredictions = [];
          isSearchingPlaces = false;
        });

        _showSnackBar("No internet connection or place search failed.");
      }
    });
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
      } else {
        _showSnackBar("Failed to load selected place.");
      }
    } catch (e) {
      _showSnackBar("No internet connection or place details failed.");
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      if (!mounted) return;

      setState(() {
        isFetchingCurrentLocation = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isFetchingCurrentLocation = false;
        });
        _showSnackBar("Please turn on location service.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          isFetchingCurrentLocation = false;
        });
        _showSnackBar("Location permission denied.");
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isFetchingCurrentLocation = false;
        });
        _showSnackBar("Location permission permanently denied.");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);

      currentDeviceLocation = latLng;
      selectedPosition = latLng;

      await mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: latLng,
            zoom: 17,
          ),
        ),
      );

      await _getAddressFromLatLng(latLng);

      if (!mounted) return;
      setState(() {
        placePredictions = [];
        isFetchingCurrentLocation = false;
      });

      searchFocusNode.unfocus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isFetchingCurrentLocation = false;
      });

      _showSnackBar("Failed to get current location.");
    }
  }

  void _onCameraMove(CameraPosition position) {
    selectedPosition = position.target;

    if (!isMapMoving && mounted) {
      setState(() {
        isMapMoving = true;
      });
    }
  }

  void _onCameraIdle() {
    if (!mounted) return;

    setState(() {
      isMapMoving = false;
    });

    _getAddressFromLatLng(selectedPosition);
  }

  void _confirmLocation() {
    if (!_canConfirm) return;

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
    _debounce?.cancel();
    mapController?.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showPredictionBox = placePredictions.isNotEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textColor),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: textColor,
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
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          Center(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(
                  0,
                  isMapMoving ? -12 : 0,
                  0,
                ),
                child: const Icon(
                  Icons.location_pin,
                  size: 44,
                  color: primaryColor,
                ),
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
                    border: Border.all(color: borderColor),
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
                        color: mutedTextColor,
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

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
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
                            Icon(
                              Icons.open_with_rounded,
                              size: 18,
                              color: primaryColor,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Move map to adjust location",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: mutedTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: isFetchingCurrentLocation
                            ? null
                            : _useCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: primaryColor.withOpacity(0.7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: isFetchingCurrentLocation
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          isFetchingCurrentLocation ? "Loading" : "Current",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (isSearchingPlaces)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
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
                            color: textColor,
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
                      border: Border.all(color: borderColor),
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
                        color: borderColor,
                      ),
                      itemBuilder: (context, index) {
                        final item = placePredictions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: primaryColor,
                          ),
                          title: Text(
                            item["structured_formatting"]?["main_text"] ??
                                item["description"] ??
                                "",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            item["structured_formatting"]?["secondary_text"] ??
                                "",
                            style: const TextStyle(
                              fontSize: 12,
                              color: mutedTextColor,
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
                border: Border.all(color: borderColor),
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
                      color: mutedTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLoadingAddress ? "Loading..." : selectedAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canConfirm ? _confirmLocation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: const Color(0xFFBFC7CD),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isOnCurrentLocation
                            ? "Move map to select another location"
                            : "Confirm Location",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
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