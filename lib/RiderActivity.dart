import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_api_service.dart';
import 'services/rider_activity_socket_service.dart';

class ActiveRidesPage extends StatefulWidget {
  const ActiveRidesPage({super.key});

  @override
  State<ActiveRidesPage> createState() => _ActiveRidesPageState();
}

class _ActiveRidesPageState extends State<ActiveRidesPage> {
  final AuthApiService _api = AuthApiService();

  bool rideIsActive = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  Timer? _timer;

  Map<String, dynamic>? _currentRide;
  List<Map<String, dynamic>> _pendingRequests = [];

  Map<String, dynamic>? get currentRide => _currentRide;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _connectSocket();
  }

  @override
  void dispose() {
    _timer?.cancel();
    RiderActivitySocketService.instance.off('rider:availability:updated');
    RiderActivitySocketService.instance.off('ride-request:accepted');
    RiderActivitySocketService.instance.off('ride-request:rejected');
    RiderActivitySocketService.instance.off('active-ride:updated');
    RiderActivitySocketService.instance.off('confirmed-ride:cancelled');
    RiderActivitySocketService.instance.off('ride:ongoing');
    RiderActivitySocketService.instance.off('ride:completed');
    RiderActivitySocketService.instance.disconnect();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();

    if (_currentRide != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _currentRide == null) return;

        final remaining =
        (_currentRide!['remainingFreeCancelSeconds'] ?? 0) as int;

        if (remaining > 0) {
          setState(() {
            _currentRide!['remainingFreeCancelSeconds'] = remaining - 1;
            _currentRide!['isFreeCancelAvailable'] =
                (remaining - 1) > 0;
          });
        } else {
          setState(() {
            _currentRide!['remainingFreeCancelSeconds'] = 0;
            _currentRide!['isFreeCancelAvailable'] = false;
          });
        }
      });
    }
  }

  Future<void> _loadDashboard() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _api.getRiderActiveRideDashboard();
      final payload = response['data'] ?? response;

      final confirmedRideRaw = payload['confirmedRide'];
      final pendingRaw = payload['pendingRequests'];

      setState(() {
        rideIsActive = payload['rideIsActive'] == true;
        _currentRide = confirmedRideRaw == null
            ? null
            : Map<String, dynamic>.from(confirmedRideRaw);
        _pendingRequests = pendingRaw is List
            ? pendingRaw
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e),
        )
            .toList()
            : [];
      });

      if (_currentRide != null &&
          (_currentRide!['confirmedRideId']?.toString().isNotEmpty ?? false)) {
        RiderActivitySocketService.instance
            .joinRideRoom(_currentRide!['confirmedRideId'].toString());
      }

      _startTimerIfNeeded();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _connectSocket() async {
    await RiderActivitySocketService.instance.connect();

    RiderActivitySocketService.instance.on(
      'rider:availability:updated',
          (_) => _loadDashboard(),
    );

    RiderActivitySocketService.instance.on(
      'ride-request:accepted',
          (_) => _loadDashboard(),
    );

    RiderActivitySocketService.instance.on(
      'ride-request:rejected',
          (_) => _loadDashboard(),
    );

    RiderActivitySocketService.instance.on(
      'active-ride:updated',
          (_) => _loadDashboard(),
    );

    RiderActivitySocketService.instance.on(
      'confirmed-ride:cancelled',
          (_) => _loadDashboard(),
    );

    RiderActivitySocketService.instance.on(
      'ride:ongoing',
          (_) => _loadDashboard(),
    );

    RiderActivitySocketService.instance.on(
      'ride:completed',
          (_) => _loadDashboard(),
    );
  }

  Future<void> _toggleRideStatus() async {
    if (_isSubmitting) return;

    final nextValue = !rideIsActive;

    try {
      setState(() {
        _isSubmitting = true;
      });

      await _api.updateRideAvailability(isActive: nextValue);

      setState(() {
        rideIsActive = nextValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue ? "Ride activated" : "Ride deactivated",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _cancelConfirmedRide() async {
    final ride = _currentRide;
    if (ride == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No confirmed ride found")),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      final result = await _api.cancelConfirmedRide(
        requestId: ride['requestId'].toString(),
      );

      await _loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Ride cancelled successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _acceptPendingRequest(String requestId) async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      final result = await _api.acceptPendingRideRequest(requestId: requestId);
      await _loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Ride request accepted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _rejectPendingRequest(String requestId) async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      final result = await _api.rejectPendingRideRequest(requestId: requestId);
      await _loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Ride request rejected'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _startRide() async {
    final ride = _currentRide;
    if (ride == null) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      final result = await _api.startAssignedRide(
        rideId: ride['confirmedRideId'].toString(),
      );

      await _loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Ride started successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _completeRide() async {
    final ride = _currentRide;
    if (ride == null) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      final result = await _api.completeOngoingRide(
        rideId: ride['confirmedRideId'].toString(),
      );

      await _loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Ride completed successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final currentRide = this.currentRide;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Active Rides"),
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rideIsActive ? "Ride is Active" : "Ride is Inactive",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Switch(
                    value: rideIsActive,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF14B8A6),
                    onChanged: (_) => _toggleRideStatus(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Current Ride Summary",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RideInfoRow(
                    label: "Passenger",
                    value: currentRide?['passengerName'] ?? "No current ride",
                  ),
                  _RideInfoRow(
                    label: "Phone",
                    value: currentRide?['phoneNumber'] ?? "-",
                  ),
                  _RideInfoRow(
                    label: "Pickup",
                    value: currentRide?['currentLocation'] ?? "-",
                  ),
                  _RideInfoRow(
                    label: "Destination",
                    value: currentRide?['destination'] ?? "-",
                  ),
                  _RideInfoRow(
                    label: "Fare",
                    value: currentRide != null
                        ? "৳${currentRide['fare']}"
                        : "-",
                  ),
                  _RideInfoRow(
                    label: "Time",
                    value: currentRide != null
                        ? "${currentRide['estimatedMinutes']} min"
                        : "-",
                  ),
                  if (currentRide != null) ...[
                    _RideInfoRow(
                      label: "Free Cancel",
                      value: currentRide['isFreeCancelAvailable'] == true
                          ? "${currentRide['remainingFreeCancelSeconds']}s left"
                          : "Expired",
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelConfirmedRide,
                        icon: const Icon(Icons.close),
                        label: const Text("Cancel / Reject Ride"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _RideInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}