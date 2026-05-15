import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_api_service.dart';

class PassengerLiveMapPage extends StatefulWidget {
  final String sessionId;       // CoRide session id
  final String hostName;        // Host এর নাম
  final String destination;
  final bool isCoRide;          // true = CoRide, false = regular ride
  final String? rideId;         // Regular ride এর জন্য

  const PassengerLiveMapPage({
    super.key,
    required this.sessionId,
    required this.hostName,
    required this.destination,
    this.isCoRide = true,
    this.rideId,
  });

  @override
  State<PassengerLiveMapPage> createState() => _PassengerLiveMapPageState();
}

class _PassengerLiveMapPageState extends State<PassengerLiveMapPage> {
  final AuthApiService _api = AuthApiService();
  GoogleMapController? _mapController;
  IO.Socket? _socket;
  Timer? _locationTimer;

  LatLng? _hostLocation;      // Host/Rider এর location
  LatLng? _myLocation;        // আমার location
  bool _isLoading = true;
  bool _isSendingSos = false;
  String _statusText = 'Connecting...';

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initMyLocation();
    _connectSocket();
    _fetchInitialHostLocation();
  }

  // ── আমার location get করা ──
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
      setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
      });

      _addMyMarker(pos.latitude, pos.longitude);
      _startSendingMyLocation(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  // ── Host/Rider এর initial location ──
  Future<void> _fetchInitialHostLocation() async {
    try {
      final res = await _api.getCoRideLiveLocation(widget.sessionId);
      final data = res['data'];
      if (data != null && data['current_lat'] != null) {
        final lat = double.tryParse(data['current_lat'].toString()) ?? 0;
        final lng = double.tryParse(data['current_lng'].toString()) ?? 0;
        _updateHostMarker(lat, lng);
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Socket connect ──
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
      _socket!.emit('coride:join_room', {'sessionId': widget.sessionId});
      if (mounted) setState(() => _statusText = 'Live tracking active');
    });

    // Host/Rider এর location update receive
    _socket!.on('coride:location', (data) {
      final lat = double.tryParse(data['lat'].toString()) ?? 0;
      final lng = double.tryParse(data['lng'].toString()) ?? 0;
      _updateHostMarker(lat, lng);
    });

    _socket!.onDisconnect((_) {
      if (mounted) setState(() => _statusText = 'Reconnecting...');
    });
  }

  // ── আমার location পাঠানো (SOS tracking এর জন্য) ──
  void _startSendingMyLocation(double initialLat, double initialLng) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (!mounted) return;

        setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
        _addMyMarker(pos.latitude, pos.longitude);

        // Socket দিয়ে SOS tracking update (token আছে কিনা check করে)
        _socket?.emit('sos:location_update', {
          'token': '', // SOS trigger হলে token এখানে set হবে
          'lat': pos.latitude,
          'lng': pos.longitude,
        });
      } catch (_) {}
    });
  }

  void _updateHostMarker(double lat, double lng) {
    if (!mounted) return;
    final newLatLng = LatLng(lat, lng);
    setState(() {
      _hostLocation = newLatLng;
      _markers.removeWhere((m) => m.markerId.value == 'host');
      _markers.add(
        Marker(
          markerId: const MarkerId('host'),
          position: newLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: widget.hostName,
            snippet: 'Heading to ${widget.destination}',
          ),
        ),
      );
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
  }

  void _addMyMarker(double lat, double lng) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'me');
      _markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    });
  }

  // ── SOS Button ──
  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          '🚨 SOS Alert',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Pressing this button will send an SMS to your emergency contact. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, send SOS.',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSendingSos = true);

    try {
      if (widget.isCoRide) {
        await _api.triggerCoRideSosParticipant(sessionId: widget.sessionId);
      } else {
        await _api.triggerPassengerSos(rideId: widget.rideId ?? '');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ SOS has been sent.'),
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
  void dispose() {
    _locationTimer?.cancel();
    _socket?.emit('coride:leave_room', {'sessionId': widget.sessionId});
    _socket?.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hostName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              '→ ${widget.destination}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ── Map ──
          _isLoading
              ? const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF14B8A6)),
          )
              : _hostLocation == null
              ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off,
                    size: 48, color: Color(0xFF6B7280)),
                SizedBox(height: 12),
                Text(
                  'Please wait…\nThe host’s location has not been found yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF6B7280), fontSize: 14),
                ),
              ],
            ),
          )
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _hostLocation!,
              zoom: 15,
            ),
            onMapCreated: (c) => _mapController = c,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),

          // ── Status bar ──
          Positioned(
            bottom: 100,
            left: 20,
            right: 80,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3))
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
                  Text(
                    _statusText,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _isSendingSos ? Colors.red.shade300 : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: _isSendingSos
                    ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}