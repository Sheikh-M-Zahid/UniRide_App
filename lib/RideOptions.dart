import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'RideModels.dart';
import 'package:uni_ride/RequestingRide.dart';
import 'services/auth_api_service.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color border = Color(0xFFE5E7EB);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color softPrimary = Color(0xFFECFEFF);
  static const Color warning = Color(0xFFF59E0B);
}

enum RideSortType {
  lowestFare,
  nearestRide,
  earliestDeparture,
}

class RideOptionsPage extends StatefulWidget {
  final PickedLocation pickupLocation;
  final PickedLocation destinationLocation;
  final double routeDistanceKm;
  final int estimatedTravelMinutes;
  final double totalCost;
  final List<RideOptionModel> availableRides;

  const RideOptionsPage({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.routeDistanceKm,
    required this.estimatedTravelMinutes,
    required this.totalCost,
    required this.availableRides,
  });

  @override
  State<RideOptionsPage> createState() => _RideOptionsPageState();
}

class _RideOptionsPageState extends State<RideOptionsPage> {
  final AuthApiService _authApiService = AuthApiService();
  RideSortType selectedSort = RideSortType.lowestFare;

  late List<RideOptionModel> _liveRides;
  bool _isRefreshing = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _liveRides = List.from(widget.availableRides);
    _startLiveRefresh();
  }

  void _startLiveRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchLiveRides();
    });
  }

  Future<void> _fetchLiveRides() async {
    if (_isRefreshing || !mounted) return;
    setState(() => _isRefreshing = true);
    try {
      final response = await _authApiService.searchRides(
        pickupLat: widget.pickupLocation.latLng.latitude,
        pickupLng: widget.pickupLocation.latLng.longitude,
        destinationLat: widget.destinationLocation.latLng.latitude,
        destinationLng: widget.destinationLocation.latLng.longitude,
      );
      final data = response['data'] ?? {};
      final List<dynamic> rawRides = data['availableRides'] ?? [];
      final updated = rawRides.map((ride) {
        final map = Map<String, dynamic>.from(ride as Map);
        final rider = Map<String, dynamic>.from(map['rider'] ?? {});
        return RideOptionModel(
          id: map['ride_id']?.toString() ?? '',
          driverPhoneNumber: (rider['phone'] ?? '').toString(),
          driverName: (rider['name'] ?? '').toString(),
          userType: 'Student',
          vehicleType: (map['vehicle_type'] ?? '').toString().isEmpty
              ? 'Car'
              : (map['vehicle_type'] ?? '').toString(),
          rating: double.tryParse('${rider['rating'] ?? 0}') ?? 0,
          vehicleNumber:
          '${map['company'] ?? ''} ${map['model'] ?? ''} ${map['number_plate'] ?? ''}'
              .trim(),
          emptySeats: int.tryParse('${map['available_seats'] ?? 0}') ?? 0,
          departureTime: (map['travel_time'] ?? 'Now').toString(),
          genderPreference: (map['gender_preference'] ?? 'Any').toString(),
          distanceAwayKm:
          double.tryParse('${map['riderDistanceKm'] ?? 0}') ?? 0,
          estimatedFare:
          double.tryParse('${map['estimatedFare'] ?? 0}') ?? 0,
          isAvailable:
          (int.tryParse('${map['available_seats'] ?? 0}') ?? 0) > 0,
        );
      }).toList();
      if (!mounted) return;
      setState(() => _liveRides = updated);
    } catch (_) {
      // silent fail — পুরনো list রেখে দাও
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String selectedGender = 'Any';
  String selectedUserType = 'All';
  String selectedVehicleType = 'All';

// Offer state — প্রতিটা ride এর জন্য আলাদা
  final Map<String, _AppliedOffer> _appliedOffers = {};
  final Map<String, TextEditingController> _promoControllers = {};
  final Map<String, bool> _promoLoading = {};

  TextEditingController _promoControllerFor(String rideId) {
    return _promoControllers.putIfAbsent(rideId, () => TextEditingController());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    for (final c in _promoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<RideOptionModel> get filteredRides {
    final List<RideOptionModel> rides = _liveRides.where((ride) {
      final bool genderMatch = selectedGender == 'Any'
          ? true
          : ride.driverGender.toLowerCase() ==
          (selectedGender == 'Male only' ? 'male' : 'female');

      final bool userTypeMatch =
      selectedUserType == 'All' ? true : ride.userType == selectedUserType;

      final bool vehicleTypeMatch = selectedVehicleType == 'All'
          ? true
          : ride.vehicleType.toLowerCase() == selectedVehicleType.toLowerCase();

      return ride.isAvailable &&
          genderMatch &&
          userTypeMatch &&
          vehicleTypeMatch;
    }).toList();

    switch (selectedSort) {
      case RideSortType.lowestFare:
        rides.sort((a, b) => a.estimatedFare.compareTo(b.estimatedFare));
        break;
      case RideSortType.nearestRide:
        rides.sort((a, b) => a.distanceAwayKm.compareTo(b.distanceAwayKm));
        break;
      case RideSortType.earliestDeparture:
        rides.sort(
              (a, b) =>
              _timeToMinutes(a.departureTime).compareTo(
                _timeToMinutes(b.departureTime),
              ),
        );
        break;
    }

    return rides;
  }

  int _timeToMinutes(String time) {
    final List<String> parts = time.split(' ');
    if (parts.length != 2) return 9999;

    final List<String> hm = parts[0].split(':');
    if (hm.length != 2) return 9999;

    int hour = int.tryParse(hm[0]) ?? 0;
    final int minute = int.tryParse(hm[1]) ?? 0;
    final String period = parts[1].toUpperCase();

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return hour * 60 + minute;
  }

  /*Future<void> _reloadRideOptions() async {
    try {
      final response = await _authApiService.getRideOptions(
        pickupAddress: widget.pickupLocation.address,
        destinationAddress: widget.destinationLocation.address,
        pickupLat: widget.pickupLocation.latLng.latitude,
        pickupLng: widget.pickupLocation.latLng.longitude,
        destinationLat: widget.destinationLocation.latLng.latitude,
        destinationLng: widget.destinationLocation.latLng.longitude,
        genderPreference: selectedGender,
        vehicleType: selectedVehicleType,
        userType: selectedUserType,
      );

      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final routeSummary = Map<String, dynamic>.from(data['routeSummary'] ?? {});
      final rides = List<Map<String, dynamic>>.from(data['availableRides'] ?? const []);

      final mappedRides = rides.map((ride) => RideOptionModel.fromJson(ride)).toList();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RideOptionsPage(
            pickupLocation: widget.pickupLocation,
            destinationLocation: widget.destinationLocation,
            routeDistanceKm: (routeSummary['routeDistanceKm'] ?? widget.routeDistanceKm).toDouble(),
            estimatedTravelMinutes: (routeSummary['estimatedTravelMinutes'] ?? widget.estimatedTravelMinutes).toInt(),
            totalCost: (routeSummary['totalCost'] ?? widget.totalCost).toDouble(),
            availableRides: mappedRides,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh ride options: $e')),
      );
    }
  }*/

  void _onViewDetails(RideOptionModel ride) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(ride.driverName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone: ${ride.driverPhoneNumber}'),
              Text('Vehicle: ${ride.vehicleType}'),
              Text('Vehicle Number: ${ride.vehicleNumber}'),
              Text('Seats: ${ride.emptySeats}'),
              Text('Departure: ${ride.departureTime}'),
              Text('Gender: ${ride.genderPreference}'),
              Text('Distance: ${ride.distanceAwayKm.toStringAsFixed(1)} km'),
              Text('Fare: ৳${ride.estimatedFare.toStringAsFixed(0)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _onBookNow(RideOptionModel ride) {
    final applied = _appliedOffers[ride.id];
    final finalFare = applied != null ? applied.discountedFare : ride.estimatedFare;
    final promoCode = applied?.promoCode;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestingRidePage(
          rideId: ride.id,
          driverName: ride.driverName,
          driverPhoneNumber: ride.driverPhoneNumber,
          vehicleType: ride.vehicleType,
          vehicleNumber: ride.vehicleNumber,
          pickupAddress: widget.pickupLocation.address,
          destinationAddress: widget.destinationLocation.address,
          fare: finalFare,
          distanceKm: widget.routeDistanceKm,
          estimatedMinutes: widget.estimatedTravelMinutes,
          appliedPromoCode: promoCode,
          originalFare: applied != null ? ride.estimatedFare : null,
        ),
      ),
    );
  }

  Future<void> _applyPromo(RideOptionModel ride) async {
    final controller = _promoControllerFor(ride.id);
    final code = controller.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _promoLoading[ride.id] = true);

    try {
      final response = await _authApiService.applyPromoCode(promoCode: code);
      final data = response['data'] ?? {};
      final rewardPct = double.tryParse('${data['reward_percentage'] ?? 0}') ?? 0;
      final offerName = (data['offer_name'] ?? '').toString();

      if (rewardPct <= 0) {
        _showPromoSnack('Invalid or expired offer code.', isError: true);
        return;
      }

      final discounted = ride.estimatedFare - (ride.estimatedFare * rewardPct / 100);

      setState(() {
        _appliedOffers[ride.id] = _AppliedOffer(
          promoCode: code,
          offerName: offerName,
          discountPct: rewardPct,
          discountedFare: discounted.roundToDouble(),
        );
      });

      _showPromoSnack('🎉 "$code" applied! You save ৳${(ride.estimatedFare - discounted).toStringAsFixed(0)}');
    } catch (e) {
      _showPromoSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _promoLoading[ride.id] = false);
    }
  }

  void _removePromo(String rideId) {
    setState(() {
      _appliedOffers.remove(rideId);
      _promoControllers[rideId]?.clear();
    });
  }

  void _showPromoSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFDC2626) : AppColors.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedNumber = phoneNumber.trim();
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open dial pad."),
        ),
      );
    }
  }

  Future<void> _onNotifyMe() async {
    try {
      await _authApiService.createRideAvailabilityAlert(
        pickupAddress: widget.pickupLocation.address,
        destinationAddress: widget.destinationLocation.address,
        pickupLat: widget.pickupLocation.latLng.latitude,
        pickupLng: widget.pickupLocation.latLng.longitude,
        destinationLat: widget.destinationLocation.latLng.latitude,
        destinationLng: widget.destinationLocation.latLng.longitude,
        genderPreference: selectedGender,
        vehicleType: selectedVehicleType,
        userType: selectedUserType,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You’ll be notified when a ride becomes available."),
          duration: Duration(seconds: 1),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save notification request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<RideOptionModel> rides = filteredRides;

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
                    _buildRouteSummaryCard(),
                    const SizedBox(height: 20),
                    _buildSectionTitle("Filter & sort"),
                    const SizedBox(height: 12),
                    _buildSortSection(),
                    const SizedBox(height: 12),
                    _buildFilterSection(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSectionTitle(
                            rides.isEmpty
                                ? "Available rides"
                                : "Available rides (${rides.length})",
                          ),
                        ),
                        if (_isRefreshing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (rides.isEmpty)
                      _buildNoRideFound()
                    else
                      ...rides.map(_buildRideCard),
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
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.text),
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
                    Icons.directions_car_filled_rounded,
                    color: AppColors.secondary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Ride options",
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

  Widget _buildRouteSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Route summary",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          _buildRouteRow(
            icon: Icons.radio_button_checked,
            iconColor: AppColors.primary,
            label: "Pickup location",
            value: widget.pickupLocation.address,
          ),
          const SizedBox(height: 14),
          _buildRouteDivider(),
          const SizedBox(height: 14),
          _buildRouteRow(
            icon: Icons.location_on,
            iconColor: AppColors.secondary,
            label: "Destination",
            value: widget.destinationLocation.address,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMiniCard(
                  title: "Distance",
                  value: "${widget.routeDistanceKm.toStringAsFixed(1)} km",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryMiniCard(
                  title: "Travel time",
                  value: "${widget.estimatedTravelMinutes} min",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCostCard(),
        ],
      ),
    );
  }

  Widget _buildRouteRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.softPrimary,
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Container(
        height: 1,
        color: AppColors.border,
      ),
    );
  }

  Widget _buildSummaryMiniCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.softPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFEFF0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.payments_rounded, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Total cost",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            "৳ ${widget.totalCost.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }

  Widget _buildSortSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sort by",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChoiceChip(
                label: "Lowest fare",
                isSelected: selectedSort == RideSortType.lowestFare,
                onTap: () {
                  setState(() {
                    selectedSort = RideSortType.lowestFare;
                  });
                },
              ),
              _buildChoiceChip(
                label: "Nearest ride",
                isSelected: selectedSort == RideSortType.nearestRide,
                onTap: () {
                  setState(() {
                    selectedSort = RideSortType.nearestRide;
                  });
                },
              ),
              _buildChoiceChip(
                label: "Earliest departure",
                isSelected: selectedSort == RideSortType.earliestDeparture,
                onTap: () {
                  setState(() {
                    selectedSort = RideSortType.earliestDeparture;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filters",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _buildDropdownField(
            label: "Gender preference",
            value: selectedGender,
            items: const ["Any", "Female only", "Male only"],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedGender = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: "User type",
            value: selectedUserType,
            items: const ["All", "Student", "Teacher", "Staff", "Alumni"],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedUserType = value;
              });
              //_reloadRideOptions();
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: "Vehicle type",
            value: selectedVehicleType,
            items: const ["All", "Car", "Bike"],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedVehicleType = value;
              });
              //_reloadRideOptions();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(RideOptionModel ride) {
    return Container(
      key: ValueKey(ride.id),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.softPrimary,
                    child: Text(
                      ride.driverName.isNotEmpty
                          ? ride.driverName[0].toUpperCase()
                          : "D",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ride.userType.isNotEmpty
                            ? ride.userType[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSmallBadge(ride.userType),
                        _buildSmallBadge(ride.vehicleType),
                        _buildRatingBadge(ride.rating),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRideInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: "Vehicle number",
            value: ride.vehicleNumber,
          ),
          const SizedBox(height: 10),
          _buildRideInfoRow(
            icon: Icons.event_seat_outlined,
            label: "Empty seats",
            value: "${ride.emptySeats}",
          ),
          const SizedBox(height: 10),
          _buildRideInfoRow(
            icon: Icons.access_time_rounded,
            label: "Departure time",
            value: ride.departureTime,
          ),
          const SizedBox(height: 10),
          _buildRideInfoRow(
            icon: Icons.person_outline_rounded,
            label: "Gender match",
            value: ride.genderPreference,
          ),
          const SizedBox(height: 10),
          _buildRideInfoRow(
            icon: Icons.near_me_rounded,
            label: "Ride distance away",
            value: "${ride.distanceAwayKm.toStringAsFixed(1)} km",
          ),
          const SizedBox(height: 14),
          _buildFareSection(ride),
          const SizedBox(height: 10),
          _buildPromoSection(ride),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onViewDetails(ride),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "View Details",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onBookNow(ride),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Book Now",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookRideSheet(RideOptionModel ride) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Book ride",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Contact ${ride.driverName} to confirm your booking.",
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softPrimary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFEFF0)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.call_rounded,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.driverName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.driverPhoneNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _makePhoneCall(ride.driverPhoneNumber);
                },
                icon: const Icon(Icons.call_rounded),
                label: const Text(
                  "Call now",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.8,
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareSection(RideOptionModel ride) {
    final applied = _appliedOffers[ride.id];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: applied != null
              ? const Color(0xFF34D399).withOpacity(0.6)
              : const Color(0xFFBFEFF0),
          width: applied != null ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Estimated fare",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                if (applied != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.local_offer_rounded,
                          size: 11, color: Color(0xFF059669)),
                      const SizedBox(width: 3),
                      Text(
                        applied.promoCode,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(-${applied.discountPct.toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (applied != null)
                Text(
                  "৳ ${ride.estimatedFare.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                "৳ ${applied != null ? applied.discountedFare.toStringAsFixed(0) : ride.estimatedFare.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: applied != null
                      ? const Color(0xFF059669)
                      : AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSection(RideOptionModel ride) {
    final applied = _appliedOffers[ride.id];
    final isLoading = _promoLoading[ride.id] ?? false;

    if (applied != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 18, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    applied.offerName.isNotEmpty
                        ? applied.offerName
                        : 'Offer Applied',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  Text(
                    'Code: ${applied.promoCode} · ${applied.discountPct.toStringAsFixed(0)}% off',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _removePromo(ride.id),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 15, color: Color(0xFF15803D)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined,
              size: 18, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _promoControllerFor(ride.id),
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                letterSpacing: 0.8,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter promo code',
                hintStyle: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _applyPromo(ride),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : () => _applyPromo(ride),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isLoading
                    ? AppColors.border
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Apply',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRideFound() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.softPrimary,
            child: Icon(
              Icons.search_off_rounded,
              size: 30,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "No rides available right now",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Try changing filters or get notified when a ride becomes available.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onNotifyMe,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Notify me when a ride is available",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppliedOffer {
  final String promoCode;
  final String offerName;
  final double discountPct;
  final double discountedFare;

  const _AppliedOffer({
    required this.promoCode,
    required this.offerName,
    required this.discountPct,
    required this.discountedFare,
  });
}