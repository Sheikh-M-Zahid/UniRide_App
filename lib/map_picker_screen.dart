import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  final String googleApiKey;
  final LatLng initialPosition;
  final String title;

  const MapPickerScreen({
    super.key,
    this.googleApiKey = "AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI",
    required this.initialPosition,
    required this.title,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;

  late LatLng _selectedPosition;
  LatLng? _currentDeviceLocation;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;

  bool _isLoadingAddress = false;
  bool _isSearchingPlaces = false;
  bool _isFetchingCurrentLocation = false;
  bool _isMapMoving = false;

  String _selectedAddress = "Loading address...";
  List<dynamic> _placePredictions = [];

  static const Color primaryColor = Color(0xFF14B8A6);
  static const Color secondaryColor = Color(0xFF0F766E);
  static const Color bgColor = Color(0xFFF9FAFB);
  static const Color textColor = Color(0xFF1F2937);
  static const Color mutedTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _getAddressFromLatLng(_selectedPosition);
  }

  bool get _isOnCurrentLocation {
    if (_currentDeviceLocation == null) return false;

    final double distance = Geolocator.distanceBetween(
      _currentDeviceLocation!.latitude,
      _currentDeviceLocation!.longitude,
      _selectedPosition.latitude,
      _selectedPosition.longitude,
    );

    return distance <= 20;
  }

  bool get _canConfirm => !_isLoadingAddress;

  String _latLngText(LatLng latLng) {
    return "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
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
      _isLoadingAddress = true;
      _selectedAddress = "Loading address...";
    });

    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      ).timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        final List<String> parts = [
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.trim().isNotEmpty).cast<String>().toList();

        final String formattedAddress = parts.isNotEmpty
            ? parts.join(", ")
            : _latLngText(latLng);

        setState(() {
          _selectedAddress = formattedAddress;
          _searchController.text = formattedAddress;
          _isLoadingAddress = false;
        });
      } else {
        final String fallback = _latLngText(latLng);

        setState(() {
          _selectedAddress = fallback;
          _searchController.text = fallback;
          _isLoadingAddress = false;
        });

        _showSnackBar("Exact address পাওয়া যায়নি.");
      }
    } on TimeoutException {
      if (!mounted) return;

      final String fallback = _latLngText(latLng);

      setState(() {
        _selectedAddress = fallback;
        _searchController.text = fallback;
        _isLoadingAddress = false;
      });

      _showSnackBar("Address fetch timeout হয়েছে.");
    } catch (e) {
      if (!mounted) return;

      final String fallback = _latLngText(latLng);

      setState(() {
        _selectedAddress = fallback;
        _searchController.text = fallback;
        _isLoadingAddress = false;
      });

      _showSnackBar("Address fetch করতে সমস্যা হয়েছে.");
    }
  }

  void _searchPlaces(String input) {
    _debounce?.cancel();

    if (input.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _placePredictions = [];
        _isSearchingPlaces = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;

      setState(() {
        _isSearchingPlaces = true;
      });

      try {
        final Uri url = Uri.parse(
          "https://maps.googleapis.com/maps/api/place/autocomplete/json"
              "?input=${Uri.encodeComponent(input)}"
              "&key=${widget.googleApiKey}"
              "&components=country:bd",
        );

        final http.Response response = await http
            .get(url)
            .timeout(const Duration(seconds: 12));

        final dynamic data = jsonDecode(response.body);

        if (!mounted) return;

        if (response.statusCode == 200 &&
            data is Map<String, dynamic> &&
            (data["status"] == "OK" || data["status"] == "ZERO_RESULTS")) {
          setState(() {
            _placePredictions = (data["predictions"] as List?) ?? [];
            _isSearchingPlaces = false;
          });
        } else {
          final String apiStatus = data is Map<String, dynamic>
              ? (data["status"]?.toString() ?? "UNKNOWN_ERROR")
              : "INVALID_RESPONSE";

          setState(() {
            _placePredictions = [];
            _isSearchingPlaces = false;
          });

          _showSnackBar("Place search failed. ($apiStatus)");
        }
      } on TimeoutException {
        if (!mounted) return;

        setState(() {
          _placePredictions = [];
          _isSearchingPlaces = false;
        });

        _showSnackBar("Place search timeout হয়েছে.");
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _placePredictions = [];
          _isSearchingPlaces = false;
        });

        _showSnackBar("Place search-এ সমস্যা হয়েছে.");
      }
    });
  }

  Future<void> _selectPrediction(dynamic prediction) async {
    final String placeId = prediction["place_id"]?.toString() ?? "";
    final String description = prediction["description"]?.toString() ?? "";

    if (placeId.isEmpty) {
      _showSnackBar("Invalid place selected.");
      return;
    }

    try {
      final Uri url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/details/json"
            "?place_id=$placeId"
            "&key=${widget.googleApiKey}",
      );

      final http.Response response = await http
          .get(url)
          .timeout(const Duration(seconds: 12));

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data["status"] == "OK" &&
          data["result"] != null &&
          data["result"]["geometry"] != null &&
          data["result"]["geometry"]["location"] != null) {
        final dynamic location = data["result"]["geometry"]["location"];

        final LatLng latLng = LatLng(
          (location["lat"] as num).toDouble(),
          (location["lng"] as num).toDouble(),
        );

        _selectedPosition = latLng;

        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latLng,
              zoom: 17,
            ),
          ),
        );

        if (!mounted) return;

        setState(() {
          _searchController.text = description;
          _placePredictions = [];
        });

        _searchFocusNode.unfocus();
        await _getAddressFromLatLng(latLng);
      } else {
        final String apiStatus = data is Map<String, dynamic>
            ? (data["status"]?.toString() ?? "UNKNOWN_ERROR")
            : "INVALID_RESPONSE";

        _showSnackBar("Selected place load failed. ($apiStatus)");
      }
    } on TimeoutException {
      _showSnackBar("Place details timeout হয়েছে.");
    } catch (e) {
      _showSnackBar("Place details load করতে সমস্যা হয়েছে.");
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      if (!mounted) return;

      setState(() {
        _isFetchingCurrentLocation = true;
      });

      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isFetchingCurrentLocation = false;
        });
        _showSnackBar("Please turn on location service.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _isFetchingCurrentLocation = false;
        });
        _showSnackBar("Location permission denied.");
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isFetchingCurrentLocation = false;
        });
        _showSnackBar("Location permission permanently denied.");
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng latLng = LatLng(position.latitude, position.longitude);

      _currentDeviceLocation = latLng;
      _selectedPosition = latLng;

      await _mapController?.animateCamera(
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
        _placePredictions = [];
        _isFetchingCurrentLocation = false;
      });

      _searchFocusNode.unfocus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFetchingCurrentLocation = false;
      });

      _showSnackBar("Failed to get current location.");
    }
  }

  void _onCameraMove(CameraPosition position) {
    _selectedPosition = position.target;

    if (!_isMapMoving && mounted) {
      setState(() {
        _isMapMoving = true;
      });
    }
  }

  void _onCameraIdle() {
    if (!mounted) return;

    setState(() {
      _isMapMoving = false;
    });

    _getAddressFromLatLng(_selectedPosition);
  }

  void _confirmLocation() {
    if (!_canConfirm) return;

    Navigator.pop(
      context,
      {
        "address": _selectedAddress.trim().isNotEmpty
            ? _selectedAddress
            : _latLngText(_selectedPosition),
        "latLng": _selectedPosition,
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showPredictionBox = _placePredictions.isNotEmpty;

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
            fontWeight: FontWeight.w700,
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
            onMapCreated: (controller) async {
              _mapController = controller;

              await controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: widget.initialPosition,
                    zoom: 16,
                  ),
                ),
              );

              if (mounted) {
                setState(() {});
              }
            },
            mapType: MapType.normal,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: false,
          ),

          Center(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(
                  0,
                  _isMapMoving ? -12 : 0,
                  0,
                ),
                child: const Icon(
                  Icons.location_pin,
                  size: 46,
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
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _searchPlaces,
                    decoration: InputDecoration(
                      hintText: "Search location",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: mutedTextColor,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _placePredictions = [];
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
                          vertical: 12,
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
                        child: Row(
                          children: [
                            const Icon(
                              Icons.open_with_rounded,
                              size: 18,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isMapMoving
                                    ? "Release map to update location"
                                    : "Move map to adjust location",
                                style: const TextStyle(
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
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isFetchingCurrentLocation
                            ? null
                            : _useCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor:
                          primaryColor.withOpacity(0.7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: _isFetchingCurrentLocation
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
                          _isFetchingCurrentLocation ? "Loading" : "Current",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_isSearchingPlaces)
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
                      itemCount: _placePredictions.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: borderColor,
                      ),
                      itemBuilder: (context, index) {
                        final dynamic item = _placePredictions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: primaryColor,
                          ),
                          title: Text(
                            item["structured_formatting"]?["main_text"]
                                ?.toString() ??
                                item["description"]?.toString() ??
                                "",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            item["structured_formatting"]?["secondary_text"]
                                ?.toString() ??
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
                    _isLoadingAddress
                        ? _latLngText(_selectedPosition)
                        : _selectedAddress,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
                            ? "Confirm Current Location"
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