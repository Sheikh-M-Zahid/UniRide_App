import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_api_service.dart';

class CoRideLiveMapPage extends StatefulWidget {
  final String sessionId;

  const CoRideLiveMapPage({super.key, required this.sessionId});

  @override
  State<CoRideLiveMapPage> createState() => _CoRideLiveMapPageState();
}

class _CoRideLiveMapPageState extends State<CoRideLiveMapPage> {
  final AuthApiService _api = AuthApiService();
  GoogleMapController? _mapController;
  IO.Socket? _socket;

  LatLng? _creatorLocation;
  bool _isLoading = true;
  String _statusText = 'Connecting...';

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
    _connectSocket();
  }

  Future<void> _initLocation() async {
    try {
      final res = await _api.getCoRideLiveLocation(widget.sessionId);
      final data = res['data'];
      if (data != null && data['current_lat'] != null) {
        final lat = double.tryParse(data['current_lat'].toString()) ?? 0;
        final lng = double.tryParse(data['current_lng'].toString()) ?? 0;
        _updateLocation(lat, lng);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

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
      if (mounted) setState(() => _statusText = 'Tracking live location');
    });

    _socket!.on('coride:location', (data) {
      final lat = double.tryParse(data['lat'].toString()) ?? 0;
      final lng = double.tryParse(data['lng'].toString()) ?? 0;
      _updateLocation(lat, lng);
    });

    _socket!.onDisconnect((_) {
      if (mounted) setState(() => _statusText = 'Reconnecting...');
    });
  }

  void _updateLocation(double lat, double lng) {
    final newLatLng = LatLng(lat, lng);
    if (!mounted) return;

    setState(() {
      _creatorLocation = newLatLng;
      _statusText = 'Live tracking active';
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('creator'),
            position: newLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Co-rider Location'),
          ),
        );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newLatLng),
    );
  }

  @override
  void dispose() {
    _socket?.emit('coride:leave_room', {'sessionId': widget.sessionId});
    _socket?.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        title: const Text(
          'Live Location',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
          )
              : _creatorLocation == null
              ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off, size: 48, color: Color(0xFF6B7280)),
                SizedBox(height: 12),
                Text(
                  'Location not available yet.\nWaiting for co-rider to share location.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
              ],
            ),
          )
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _creatorLocation!,
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

          // Status bar at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  Text(
                    _statusText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
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
