import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'services/auth_api_service.dart';

import 'ChatListPage.dart';
import 'map_picker_screen.dart';
import 'CoRideChatRoom.dart';
import 'CoRideModels.dart';
import 'CoRideLiveMapPage.dart';

class SharingCaringPage extends StatefulWidget {
  const SharingCaringPage({super.key});

  @override
  State<SharingCaringPage> createState() => _SharingCaringPageState();
}

class _SharingCaringPageState extends State<SharingCaringPage> {
  final AuthApiService _authApiService = AuthApiService();
  bool _isSubmitting = false;
  bool _isLoadingActiveSession = false;
  bool _isCancellingSession = false;
  bool _isStartingJourney = false;
  Map<String, dynamic>? _activeSession;
  Timer? _locationTimer;
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
    return currentLocationController.text.trim().isNotEmpty &&
        destinationController.text.trim().isNotEmpty &&
        selectedDate != null &&
        selectedTime != null &&
        selectedVehicleType != null &&
        availableSeatController.text.trim().isNotEmpty &&
        fareController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    currentLocationController.addListener(_refreshForm);
    destinationController.addListener(_refreshForm);
    vehicleNumberController.addListener(_refreshForm);
    availableSeatController.addListener(_refreshForm);
    fareController.addListener(_refreshForm);
    _loadActiveSession();
  }

  Future<void> _loadActiveSession() async {
    setState(() => _isLoadingActiveSession = true);
    try {
      final res = await _authApiService.getMyActiveCoRideSession();
      if (!mounted) return;
      final sessionData = res['data'];
      if (sessionData != null) {
        final sessionId = sessionData['session_id']?.toString() ?? '';
        if (sessionId.isNotEmpty) {
          // Participants সহ নতুন API call
          final detailRes = await _authApiService
              .getCoRideSessionWithParticipants(sessionId);
          setState(() => _activeSession = detailRes['data']);
        } else {
          setState(() => _activeSession = sessionData);
        }
      } else {
        setState(() => _activeSession = null);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingActiveSession = false);
  }

  Future<void> _cancelSession() async {
    if (_activeSession == null || _isCancellingSession) return;
    setState(() => _isCancellingSession = true);
    try {
      await _authApiService.cancelCoRideSession(
        _activeSession!['session_id'].toString(),
      );
      if (!mounted) return;
      setState(() => _activeSession = null);
      _locationTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CoRide cancelled.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
    if (mounted) setState(() => _isCancellingSession = false);
  }

  Future<void> _startJourney() async {
    if (_activeSession == null) return;
    setState(() => _isStartingJourney = true);
    try {
      await _authApiService.startCoRideJourney(
        _activeSession!['session_id'].toString(),
      );
      if (!mounted) return;
      setState(() {
        _activeSession!['is_started'] = true;
        _isStartingJourney = false;
      });

      // Map page এ navigate করো
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CoRideLiveMapPage(
            sessionId: _activeSession!['session_id'].toString(),
            isHost: true,
            destination: _activeSession!['destination'] ?? '',
            otherPartyName: 'Co-Riders',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isStartingJourney = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmRemoveParticipant(
      String sessionId, String participantUserId, String participantName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Participant'),
        content: Text(
            'Are you sure you want to remove $participantName কfrom your ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child:
            const Text('Yes, remove.', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _authApiService.removeCoRideParticipant(
        sessionId: sessionId,
        participantUserId: participantUserId,
      );
      await _loadActiveSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$participantName has been removed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _startLiveLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      // GPS এর জন্য geolocator package ব্যবহার করো
      // এখানে placeholder — তোমার existing GPS logic দিয়ে replace করো
    });
  }

  void _refreshForm() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
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
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _pickCurrentLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(
          googleApiKey: "AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI",
          initialPosition: LatLng(23.8103, 90.4125),
          title: "Select Current Location",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        currentLocationController.text = result["address"] ?? "";
      });
    }
  }

  Future<void> _pickDestinationLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(
          googleApiKey: "AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI",
          initialPosition: LatLng(23.8103, 90.4125),
          title: "Select Destination",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        destinationController.text = result["address"] ?? "";
      });
    }
  }

  Widget _buildActiveSessionBanner() {
    final s = _activeSession!;
    final isStarted = s['is_started'] == true;
    final List confirmedParticipants = s['confirmed_participants'] ?? [];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF14B8A6), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt, color: Color(0xFF14B8A6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your Active CoRide',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF14B8A6),
                ),
              ),
              const Spacer(),
              if (isStarted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🟢 Started',
                    style: TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${s['start_location']} → ${s['destination']}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 4),
          Text(
            'Seats: ${(s['total_seats'] ?? 2) - (s['booked_seats'] ?? 0)} available',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),

          // ─── Confirmed Participants List ───
          if (confirmedParticipants.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const Text(
              'Confirmed Riders',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            ...confirmedParticipants.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
              final userId = p['user_id']?.toString() ?? '';
              final sessionId = s['session_id']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFCCFBF1),
                      backgroundImage: (p['profile_picture'] != null &&
                          p['profile_picture'].toString().isNotEmpty)
                          ? NetworkImage(p['profile_picture'].toString())
                          : null,
                      child: (p['profile_picture'] == null ||
                          p['profile_picture'].toString().isEmpty)
                          ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${index + 1}. $name',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    // See Message Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CoRideChatRoomPage(
                              post: CoRidePost(
                                id: sessionId,
                                sessionId: sessionId,
                                creatorId: s['created_by']?.toString() ?? '',
                                creatorName: '',
                                creatorPhoto: '',
                                pickup: s['start_location'] ?? '',
                                destination: s['destination'] ?? '',
                                vehicleType: '',
                                vehicleNumber: '',
                                preferredGender: '',
                                dateText: '',
                                timeText: '',
                                totalSeats: s['total_seats'] ?? 2,
                                confirmedSeats: s['booked_seats'] ?? 0,
                                farePerPerson: 0,
                                note: '',
                                confirmedMembers: [],
                              ),
                              currentUserId: userId,
                              currentUserName: name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'See Message',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Long press remove
                    GestureDetector(
                      onLongPress: () => _confirmRemoveParticipant(
                          sessionId, userId, name),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.more_vert,
                            size: 18, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 14),
          Row(
            children: [
              if (!isStarted)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isStartingJourney ? null : _startJourney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: _isStartingJourney
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Start Journey',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              if (!isStarted) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isCancellingSession ? null : _cancelSession,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: _isCancellingSession
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFDC2626),
                    ),
                  )
                      : const Text(
                    'Cancel / Close',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> confirmSharing() async {
    FocusScope.of(context).unfocus();

    if (!isFormValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authApiService.createCompanySharingSession(
        startLocation: currentLocationController.text.trim(),
        destination: destinationController.text.trim(),
        status: 'Active',
        tripDate: selectedDate == null
            ? null
            : '${selectedDate!.year.toString().padLeft(4, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
        tripTime: selectedTime == null
            ? null
            : selectedTime!.format(context),
        vehicleType: selectedVehicleType,
        vehicleNumber: vehicleNumberController.text.trim().isEmpty
            ? null
            : vehicleNumberController.text.trim(),
        totalSeats: int.tryParse(availableSeatController.text.trim()),
        preferredGender: selectedGender,
        farePerPerson: double.tryParse(fareController.text.trim()),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ride shared successfully! Notification sent."),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    currentLocationController.removeListener(_refreshForm);
    destinationController.removeListener(_refreshForm);
    vehicleNumberController.removeListener(_refreshForm);
    availableSeatController.removeListener(_refreshForm);
    fareController.removeListener(_refreshForm);

    currentLocationController.dispose();
    destinationController.dispose();
    vehicleNumberController.dispose();
    availableSeatController.dispose();
    fareController.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF14B8A6),
          title: const Text(
            "Co Ride",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.message, color: Colors.white),
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
        body: Column(
          children: [
            if (_isLoadingActiveSession)
              const LinearProgressIndicator(
                color: Color(0xFF14B8A6),
              ),

            if (_activeSession != null)
              _buildActiveSessionBanner(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // CURRENT LOCATION
                      TextFormField(
                        controller: currentLocationController,
                        readOnly: true,
                        onTap: _pickCurrentLocation,
                        decoration: _inputDecoration(
                          label: "Current Location",
                          prefixIcon: const Icon(
                            Icons.my_location,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // DESTINATION
                      TextFormField(
                        controller: destinationController,
                        readOnly: true,
                        onTap: _pickDestinationLocation,
                        decoration: _inputDecoration(
                          label: "Destination",
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // DATE
                      ListTile(
                        tileColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF0F766E),
                        ),
                        onTap: pickDate,
                      ),

                      const SizedBox(height: 15),

                      // TIME
                      ListTile(
                        tileColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          selectedTime == null
                              ? "Select Time"
                              : selectedTime!.format(context),
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.access_time,
                          color: Color(0xFF0F766E),
                        ),
                        onTap: pickTime,
                      ),

                      const SizedBox(height: 15),

                      // VEHICLE TYPE
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration(
                          label: "Vehicle Type",
                        ),
                        value: selectedVehicleType,
                        items: vehicleTypes
                            .map(
                              (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ),
                        )
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
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: "Vehicle Number",
                        ),
                      ),

                      const SizedBox(height: 15),

                      // AVAILABLE SEAT
                      TextFormField(
                        controller: availableSeatController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: _inputDecoration(
                          label: "Available Seat",
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PREFERRED GENDER
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration(
                          label: "Preferred Gender",
                        ),
                        value: selectedGender,
                        items: genderOptions
                            .map(
                              (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ),
                        )
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
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          label: "Fare Per Person (BDT)",
                        ),
                      ),

                      const SizedBox(height: 25),

                      // CONFIRM BUTTON
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormValid
                                ? const Color(0xFF14B8A6)
                                : Colors.grey,
                            disabledBackgroundColor: Colors.grey.shade400,
                            elevation: isFormValid ? 1.5 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: (isFormValid && !_isSubmitting)
                              ? confirmSharing
                              : null,
                          child: _isSubmitting
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                              : const Text(
                            "Confirm & Notify",
                            style: TextStyle(
                              fontSize: 16,
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
            ),
          ],
        ),
      ),
    );
  }
}