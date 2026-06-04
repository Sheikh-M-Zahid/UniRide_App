import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'services/auth_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color danger = Color(0xFFDC2626);
}

class ActiveRideTrackingPage extends StatefulWidget {
  final String requestId;
  final String riderName;
  final String riderPhone;
  final String? riderPhoto;
  final String destination;
  final double? initialRiderLat;
  final double? initialRiderLng;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;

  const ActiveRideTrackingPage({
    super.key,
    required this.requestId,
    required this.riderName,
    required this.riderPhone,
    this.riderPhoto,
    required this.destination,
    this.initialRiderLat,
    this.initialRiderLng,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
  });

  @override
  State<ActiveRideTrackingPage> createState() =>
      _ActiveRideTrackingPageState();
}

class _ActiveRideTrackingPageState extends State<ActiveRideTrackingPage> {
  final AuthApiService _api = AuthApiService();
  GoogleMapController? _mapController;
  IO.Socket? _socket;

  Timer? _locationPollTimer;
  Timer? _myLocationTimer;

  LatLng? _riderLocation;
  LatLng? _myLocation;
  LatLng? _destinationLocation;

  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isLoading = true;
  String _statusText = 'Connecting...';
  bool _isSendingSos = false;

  // Custom marker icons
  BitmapDescriptor _riderIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueGreen,
  );
  BitmapDescriptor _myIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueBlue,
  );
  BitmapDescriptor _destIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueRed,
  );

  @override
  void initState() {
    super.initState();

    if (widget.destinationLat != null && widget.destinationLng != null) {
      _destinationLocation =
          LatLng(widget.destinationLat!, widget.destinationLng!);
    }

    if (widget.initialRiderLat != null && widget.initialRiderLng != null) {
      _riderLocation =
          LatLng(widget.initialRiderLat!, widget.initialRiderLng!);
    }

    _initMyLocation();
    _connectSocket();
    _startPollingRiderLocation();

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _locationPollTimer?.cancel();
    _myLocationTimer?.cancel();
    _socket?.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  // ── আমার নিজের location ──
  Future<void> _initMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      _myLocation = LatLng(pos.latitude, pos.longitude);
      _updateMyMarker(pos.latitude, pos.longitude);
      _rebuildPolylines();

      // ৫ সেকেন্ড পর পর নিজের location আপডেট
      _myLocationTimer =
          Timer.periodic(const Duration(seconds: 5), (_) async {
            try {
              final p = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
              );
              if (!mounted) return;
              setState(() => _myLocation = LatLng(p.latitude, p.longitude));
              _updateMyMarker(p.latitude, p.longitude);
              _rebuildPolylines();
            } catch (_) {}
          });
    } catch (_) {}
  }

  // ── Socket connect — rider এর live location ──
  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    _socket = IO.io(
      'https://uniride-app-rm20.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      if (mounted) setState(() => _statusText = 'Live tracking active');
    });

    // Rider এর location update (riderSocket এ send_location emit হলে
    // active_riders_room এ location_update আসে)
    _socket!.on('location_update', (data) {
      // শুধু আমার rider এর update নেব
      // rider এর userId match করতে হবে — তাই poll দিয়েই করব
      // socket শুধু backup হিসেবে থাকবে
    });

    _socket!.onDisconnect((_) {
      if (mounted) setState(() => _statusText = 'Reconnecting...');
    });
  }

  // ── API poll — rider location ──
  void _startPollingRiderLocation() {
    _locationPollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
          try {
            final res = await _api.getRiderLiveLocationForPassenger(
              requestId: widget.requestId,
            );
            final d = res['data'];
            if (d == null) return;

            final lat = double.tryParse('${d['lat'] ?? ''}');
            final lng = double.tryParse('${d['lng'] ?? ''}');

            if (lat == null || lng == null) return;
            if (!mounted) return;

            setState(() {
              _riderLocation = LatLng(lat, lng);
              _statusText = 'Live tracking active';
            });
            _updateRiderMarker(lat, lng);
            _rebuildPolylines();
          } catch (_) {}
        });
  }

  // ── Markers ──
  void _updateRiderMarker(double lat, double lng) {
    if (!mounted) return;
    final pos = LatLng(lat, lng);
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'rider');
      _markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: pos,
          icon: _riderIcon,
          infoWindow: InfoWindow(
            title: widget.riderName,
            snippet: 'Your rider',
          ),
        ),
      );
    });
  }

  void _updateMyMarker(double lat, double lng) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'me');
      _markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(lat, lng),
          icon: _myIcon,
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    });

    // destination marker
    if (_destinationLocation != null) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'dest');
        _markers.add(
          Marker(
            markerId: const MarkerId('dest'),
            position: _destinationLocation!,
            icon: _destIcon,
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: widget.destination,
            ),
          ),
        );
      });
    }
  }

  // ── Polylines ──
  // Rider → Passenger: teal (primary)
  // Passenger → Destination: orange
  void _rebuildPolylines() {
    if (!mounted) return;
    final newPolylines = <Polyline>{};

    if (_riderLocation != null && _myLocation != null) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('rider_to_passenger'),
          points: [_riderLocation!, _myLocation!],
          color: const Color(0xFF14B8A6), // teal
          width: 4,
          patterns: [], // solid line
        ),
      );
    }

    if (_myLocation != null && _destinationLocation != null) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('passenger_to_dest'),
          points: [_myLocation!, _destinationLocation!],
          color: const Color(0xFFF59E0B), // amber/orange
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    setState(() => _polylines = newPolylines);

    // Camera কে rider এর দিকে নিয়ে যাও
    if (_riderLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_riderLocation!),
      );
    }
  }

  // ── SOS ──
  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          '🚨 SOS Alert',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will send an emergency alert. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, send SOS',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isSendingSos = true);

    try {
      await _api.triggerPassengerSos(rideId: widget.requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ SOS sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingSos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──
          _isLoading
              ? const Center(
            child:
            CircularProgressIndicator(color: AppColors.primary),
          )
              : _riderLocation == null && _myLocation == null
              ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_searching,
                    size: 52, color: AppColors.primary),
                SizedBox(height: 14),
                Text(
                  'Getting location...',
                  style: TextStyle(
                      color: AppColors.mutedText, fontSize: 15),
                ),
              ],
            ),
          )
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _riderLocation ??
                  _myLocation ??
                  const LatLng(23.8103, 90.4125),
              zoom: 15,
            ),
            onMapCreated: (c) {
              _mapController = c;
              if (_riderLocation != null) {
                _updateRiderMarker(
                  _riderLocation!.latitude,
                  _riderLocation!.longitude,
                );
              }
              if (_myLocation != null) {
                _updateMyMarker(
                  _myLocation!.latitude,
                  _myLocation!.longitude,
                );
              }
              // destination marker আলাদাভাবে add করো
              // যেন _myLocation null হলেও destination দেখা যায়
              if (_destinationLocation != null) {
                setState(() {
                  _markers.removeWhere((m) => m.markerId.value == 'dest');
                  _markers.add(
                    Marker(
                      markerId: const MarkerId('dest'),
                      position: _destinationLocation!,
                      icon: _destIcon,
                      infoWindow: InfoWindow(
                        title: 'Destination',
                        snippet: widget.destination,
                      ),
                    ),
                  );
                });
              }
              _rebuildPolylines();
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),

          // ── Top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.background,
                        child: Icon(Icons.arrow_back,
                            color: AppColors.text, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Rider photo / avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFECFEFF),
                      backgroundImage: widget.riderPhoto != null &&
                          widget.riderPhoto!.isNotEmpty
                          ? NetworkImage(widget.riderPhoto!)
                          : null,
                      child: widget.riderPhoto == null ||
                          widget.riderPhoto!.isEmpty
                          ? Text(
                        widget.riderName.isNotEmpty
                            ? widget.riderName[0].toUpperCase()
                            : 'R',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.riderName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            '→ ${widget.destination}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Legend ──
          Positioned(
            top: 105,
            left: 16,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(
                    color: const Color(0xFF14B8A6),
                    label: 'Rider → You',
                    dashed: false,
                  ),
                  const SizedBox(height: 6),
                  _legendItem(
                    color: const Color(0xFFF59E0B),
                    label: 'You → Destination',
                    dashed: true,
                  ),
                ],
              ),
            ),
          ),

          // ── Status bar ──
          Positioned(
            bottom: 100,
            left: 20,
            right: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusText.contains('active')
                          ? Colors.green
                          : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusText,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── SOS Button ──
          Positioned(
            bottom: 90,
            right: 20,
            child: GestureDetector(
              onTap: _isSendingSos ? null : _triggerSos,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color:
                  _isSendingSos ? Colors.red.shade300 : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.45),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: _isSendingSos
                    ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_rounded,
                        color: Colors.white, size: 22),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Rider info bottom sheet ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
              const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFECFEFF),
                    backgroundImage: widget.riderPhoto != null &&
                        widget.riderPhoto!.isNotEmpty
                        ? NetworkImage(widget.riderPhoto!)
                        : null,
                    child: widget.riderPhoto == null ||
                        widget.riderPhoto!.isEmpty
                        ? Text(
                      widget.riderName.isNotEmpty
                          ? widget.riderName[0].toUpperCase()
                          : 'R',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.riderName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.riderPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Call button
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri(
                          scheme: 'tel', path: widget.riderPhone);
                      // ignore: deprecated_member_use
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFEFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_rounded,
                          color: AppColors.secondary, size: 22),
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

  Widget _legendItem({
    required Color color,
    required String label,
    required bool dashed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          child: dashed
              ? Row(
            children: [
              Container(
                  width: 8, height: 3, color: color),
              const SizedBox(width: 2),
              Container(
                  width: 8, height: 3, color: color),
              const SizedBox(width: 2),
              Container(
                  width: 4, height: 3, color: color),
            ],
          )
              : Container(height: 3, color: color),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}