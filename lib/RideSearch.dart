import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'map_picker_screen.dart';
import 'RideOptions.dart' show RideOptionsPage;
import 'RideModels.dart' show PickedLocation;

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color border = Color(0xFFE5E7EB);
  static const Color mutedText = Colors.grey;
  static const Color softPrimary = Color(0xFFECFEFF);
}

class SavedPlace {
  final String keyName;
  final String title;
  final String? address;
  final LatLng? latLng;

  const SavedPlace({
    required this.keyName,
    required this.title,
    this.address,
    this.latLng,
  });

  bool get isAvailable => address != null && latLng != null;
}

class PlanYourRidePage extends StatefulWidget {
  final String googleApiKey;

  final SavedPlace? homePlace;
  final SavedPlace? campusPlace;
  final SavedPlace? hallPlace;
  final PickedLocation? lastLocation;

  const PlanYourRidePage({
    super.key,
    required this.googleApiKey,
    this.homePlace,
    this.campusPlace,
    this.hallPlace,
    this.lastLocation,
  });

  @override
  State<PlanYourRidePage> createState() => _PlanYourRidePageState();
}

class _PlanYourRidePageState extends State<PlanYourRidePage> {
  bool isLoadingCurrentLocation = true;
  bool isPickingPickup = false;
  bool isPickingDestination = false;

  PickedLocation? currentLocation;
  PickedLocation? destinationLocation;

  late final List<SavedPlace> savedPlaces;

  static const LatLng _fallbackLatLng = LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();

    savedPlaces = [
      widget.homePlace ??
          const SavedPlace(
            keyName: 'home',
            title: 'Home',
          ),
      widget.campusPlace ??
          const SavedPlace(
            keyName: 'campus',
            title: 'Campus',
          ),
      widget.hallPlace ??
          const SavedPlace(
            keyName: 'hall',
            title: 'Hall',
          ),
    ];

    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      isLoadingCurrentLocation = true;
    });

    try {
      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          isLoadingCurrentLocation = false;
        });
        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          isLoadingCurrentLocation = false;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address = "Current location";

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          final List<String> parts = [
            p.name,
            p.subLocality,
            p.locality,
          ]
              .where((e) => e != null && e.trim().isNotEmpty)
              .map((e) => e!)
              .toList();

          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {
        address = "Current location";
      }

      if (!mounted) return;

      setState(() {
        currentLocation = PickedLocation(
          address: address,
          latLng: LatLng(position.latitude, position.longitude),
        );
        isLoadingCurrentLocation = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingCurrentLocation = false;
      });
    }
  }

  Future<void> _pickLocation({
    required bool isForPickup,
  }) async {
    if (!mounted) return;

    setState(() {
      if (isForPickup) {
        isPickingPickup = true;
      } else {
        isPickingDestination = true;
      }
    });

    final LatLng initialPosition = isForPickup
        ? (currentLocation?.latLng ?? _fallbackLatLng)
        : (destinationLocation?.latLng ??
        currentLocation?.latLng ??
        _fallbackLatLng);

    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: widget.googleApiKey,
          initialPosition: initialPosition,
          title: isForPickup ? "Pick Pickup Location" : "Pick Destination",
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      if (isForPickup) {
        isPickingPickup = false;
      } else {
        isPickingDestination = false;
      }
    });

    PickedLocation? picked;

    if (result is PickedLocation) {
      picked = result;
    } else if (result is Map) {
      final dynamic addressValue = result["address"];
      final dynamic latLngValue = result["latLng"];

      if (addressValue is String && latLngValue is LatLng) {
        picked = PickedLocation(
          address: addressValue,
          latLng: latLngValue,
        );
      }
    }

    if (picked == null) return;

    setState(() {
      if (isForPickup) {
        currentLocation = picked;
      } else {
        destinationLocation = picked;
      }
    });
  }

  void _applySavedPlaceToPickup(SavedPlace place) {
    if (!place.isAvailable) return;

    setState(() {
      currentLocation = PickedLocation(
        address: place.address!,
        latLng: place.latLng!,
      );
    });
  }

  void _applySavedPlaceToDestination(SavedPlace place) {
    if (!place.isAvailable) return;

    setState(() {
      destinationLocation = PickedLocation(
        address: place.address!,
        latLng: place.latLng!,
      );
    });
  }

  void _applyLastLocationToDestination() {
    if (widget.lastLocation == null) return;

    setState(() {
      destinationLocation = widget.lastLocation;
    });
  }

  void _continueRidePlan() {
    if (currentLocation == null || destinationLocation == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideOptionsPage(
          pickupLocation: currentLocation!,
          destinationLocation: destinationLocation!,
          routeDistanceKm: 0,
          estimatedTravelMinutes: 0,
          totalCost: 0,
          availableRides: const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue =
        currentLocation != null && destinationLocation != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 18),
                    _buildRideMetaRow(),
                    const SizedBox(height: 20),
                    _buildLocationBox(),
                    const SizedBox(height: 22),
                    if (widget.lastLocation != null) ...[
                      _buildSectionTitle("Last location"),
                      const SizedBox(height: 12),
                      _buildLastLocationCard(widget.lastLocation!),
                      const SizedBox(height: 22),
                    ],
                    _buildSectionTitle("Saved places"),
                    const SizedBox(height: 12),
                    ...savedPlaces.map(_buildSavedPlaceCard),
                    const SizedBox(height: 22),
                    _buildSectionTitle("More options"),
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.my_location_rounded,
                      title: "Use my live location",
                      subtitle: "Quickly refresh your current pickup point",
                      onTap: _loadCurrentLocation,
                    ),
                    _buildInfoTile(
                      icon: Icons.map_outlined,
                      title: "Pick exact point on map",
                      subtitle: "Choose a more accurate pickup or destination",
                      onTap: () => _pickLocation(
                        isForPickup:
                        destinationLocation != null ? false : true,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: canContinue ? _continueRidePlan : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.text,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.route_rounded,
                    color: AppColors.secondary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Plan your ride",
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text(
            "Plan your ride",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Set your pickup and destination for a smoother and more accurate trip.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideMetaRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Now",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.person,
                  size: 18,
                  color: AppColors.secondary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "For me",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.border,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Icon(
                Icons.radio_button_checked,
                size: 16,
                color: AppColors.primary,
              ),
              Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: AppColors.border,
              ),
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                _buildLocationSelectorTile(
                  title: "Pickup location",
                  value: isLoadingCurrentLocation
                      ? "Detecting current location..."
                      : (currentLocation?.address ?? "Select pickup location"),
                  icon: Icons.my_location_rounded,
                  isLoading: isPickingPickup,
                  onTap: () => _pickLocation(isForPickup: true),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.border,
                ),
                const SizedBox(height: 16),
                _buildLocationSelectorTile(
                  title: "Destination",
                  value: destinationLocation?.address ?? "Where to?",
                  icon: Icons.search,
                  isLoading: isPickingDestination,
                  onTap: () => _pickLocation(isForPickup: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelectorTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.softPrimary,
              child: isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
                  : Icon(
                icon,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      ),
    );
  }

  Widget _buildLastLocationCard(PickedLocation place) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.softPrimary,
            child: Icon(
              Icons.history_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              place.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _applyLastLocationToDestination,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Destination"),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPlaceCard(SavedPlace place) {
    final bool enabled = place.isAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.softPrimary,
            child: Icon(
              _getSavedPlaceIcon(place.keyName),
              color: AppColors.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place.address ?? "No saved location yet",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: enabled ? Colors.grey : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: enabled
                            ? () => _applySavedPlaceToPickup(place)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: BorderSide(
                            color: enabled
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Current",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: enabled
                            ? () => _applySavedPlaceToDestination(place)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: enabled
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Destination",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.softPrimary,
          child: Icon(
            icon,
            color: AppColors.secondary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.35,
            ),
          ),
        ),
        trailing: onTap == null
            ? null
            : const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  IconData _getSavedPlaceIcon(String keyName) {
    switch (keyName) {
      case 'home':
        return Icons.home_rounded;
      case 'campus':
        return Icons.school_rounded;
      case 'hall':
        return Icons.apartment_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}