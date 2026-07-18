import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_api_service.dart';

class CoRideLiveMapPage extends StatefulWidget {
  final String sessionId;
  final bool isHost;
  final String destination;
  final String otherPartyName;

  const CoRideLiveMapPage({
    super.key,
    required this.sessionId,
    required this.isHost,
    required this.destination,
    required this.otherPartyName,
  });

  @override
  State<CoRideLiveMapPage> createState() => _CoRideLiveMapPageState();
}

class _CoRideLiveMapPageState extends State<CoRideLiveMapPage> {
  final AuthApiService _api = AuthApiService();
  GoogleMapController? _mapController;
  IO.Socket? _socket;
  Timer? _locationTimer;
  Timer? _refreshTimer;

  LatLng? _myLocation;
  LatLng? _otherPartyLocation;
  bool _isLoading = true;
  bool _isSendingSos = false;
  String _statusText = 'Connecting...';

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initLocationAndSocket();
  }

  Future<void> _initLocationAndSocket() async {
    await _requestLocationPermission();
    await _fetchInitialOtherPartyLocation();
    await _connectSocket();
    _startLocationBroadcast();
    _startAutoRefreshPolling();
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Location Permission ──
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  // ── অন্য পার্টির শেষ সেভ করা location API থেকে আনা (Code 1 এর _initLocation) ──
  Future<void> _fetchInitialOtherPartyLocation() async {
    try {
      final res = await _api.getCoRideLiveLocation(widget.sessionId);
      final data = res['data'];
      if (data != null && data['current_lat'] != null) {
        final lat = double.tryParse(data['current_lat'].toString()) ?? 0;
        final lng = double.tryParse(data['current_lng'].toString()) ?? 0;
        _updateOtherPartyLocation(lat, lng);
      }
    } catch (_) {}
  }

  // ✅ প্রতি ২ সেকেন্ডে fallback হিসেবে API থেকে অন্য পার্টির লোকেশন রিফ্রেশ করে (socket miss হলেও কাজ করবে)
  void _startAutoRefreshPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _fetchInitialOtherPartyLocation();
    });
  }

  // ── Socket Connect ──
  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    _socket = IO.io(
      'https://uniride-e831415d105a.herokuapp.com',
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

    // ── অন্য পার্টির real-time location receive (Code 1 এর socket listener) ──
    _socket!.on('coride:location', (data) {
      final lat = double.tryParse(data['lat'].toString()) ?? 0;
      final lng = double.tryParse(data['lng'].toString()) ?? 0;
      _updateOtherPartyLocation(lat, lng);
    });

    _socket!.onDisconnect((_) {
      if (mounted) setState(() => _statusText = 'Reconnecting...');
    });
  }

  // ── নিজের GPS location প্রতি ৫ সেকেন্ডে broadcast + API save (Code 2) ──
  void _startLocationBroadcast() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (!mounted) return;

        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _myLocation = latLng;
          _markers.removeWhere((m) => m.markerId.value == 'me');
          _markers.add(
            Marker(
              markerId: const MarkerId('me'),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: 'You'),
            ),
          );
        });

        // নিজের location এ focus (যদি অন্য পার্টির location এখনো না আসে)
        if (_otherPartyLocation == null) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
        }

        // Socket দিয়ে broadcast
        _socket?.emit('coride:location', {
          'sessionId': widget.sessionId,
          'lat': pos.latitude,
          'lng': pos.longitude,
        });

        // API তে DB save
        await _api.updateCoRideLiveLocation(
          sessionId: widget.sessionId,
          lat: pos.latitude,
          lng: pos.longitude,
        );
      } catch (_) {}
    });
  }

  // ── অন্য পার্টির location marker update (Code 1 এর _updateLocation) ──
  void _updateOtherPartyLocation(double lat, double lng) {
    final newLatLng = LatLng(lat, lng);
    if (!mounted) return;

    setState(() {
      _otherPartyLocation = newLatLng;
      _statusText = 'Live tracking active';
      _markers.removeWhere((m) => m.markerId.value == 'other_party');
      _markers.add(
        Marker(
          markerId: const MarkerId('other_party'),
          position: newLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: widget.otherPartyName),
        ),
      );
    });

    // অন্য পার্টির location এ camera move
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newLatLng),
    );
  }

  // ── SOS (Code 2) ──
  Future<void> _triggerSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          '🚨 SOS Alert',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'এই বাটনে চাপলে তোমার emergency contact কে SMS যাবে। তুমি কি নিশ্চিত?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'হ্যাঁ, SOS পাঠাও',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSendingSos = true);

    try {
      if (widget.isHost) {
        await _api.triggerCoRideSosHost(sessionId: widget.sessionId);
      } else {
        await _api.triggerCoRideSosParticipant(sessionId: widget.sessionId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ SOS পাঠানো হয়েছে।'),
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
    _refreshTimer?.cancel();
    _socket?.emit('coride:leave_room', {'sessionId': widget.sessionId});
    _socket?.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Map এর initial target: নিজের location থাকলে সেটা, না হলে অন্য পার্টির
    final initialTarget = _myLocation ?? _otherPartyLocation;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isHost ? 'Your Journey' : widget.otherPartyName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '→ ${widget.destination}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
        body: RefreshIndicator(
            color: const Color(0xFF14B8A6),
            onRefresh: () async {
              await _fetchInitialOtherPartyLocation();
              if (_myLocation != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(_otherPartyLocation ?? _myLocation!),
                );
              }
            },
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      AppBar().preferredSize.height -
                      MediaQuery.of(context).padding.top,
                  child: Stack(
                    children: [

                      // ── Map ──
                      _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF14B8A6),
            ),
          )
              : initialTarget == null
              ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off,
                    size: 48, color: Color(0xFF6B7280)),
                SizedBox(height: 12),
                Text(
                  'Unable to get your location...\nWaiting for location data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF6B7280), fontSize: 14),
                ),
              ],
            ),
          )
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),

          // ── Status Bar ──
          Positioned(
            bottom: 100,
            left: 20,
            right: 80,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusText.contains('active')
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
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
                ),
            ),
        ),
    );
  }
}