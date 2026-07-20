import 'dart:async';
import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'services/socket_service.dart';
import 'RideRequestModel.dart';
import 'package:url_launcher/url_launcher.dart';

class RideRequestService {
  RideRequestService._();

  static final AuthApiService _api = AuthApiService();
  static final List<ConfirmedRideData> _confirmedRides = [];

  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isDialogShowing = false;
  static bool _listenersAttached = false;
  static final ValueNotifier<double> dueFineNotifier = ValueNotifier<double>(0);
  static final List<RideRequestModel> _pendingRequests = [];

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  static Future<void> setupRealtime() async {
    if (_listenersAttached) return;

    _listenersAttached = true;

    void handleIncoming(dynamic data) {
      if (data is Map<String, dynamic>) {
        final requestData = data['request'] ?? data;
        addRequest(RideRequestModel.fromMap(Map<String, dynamic>.from(requestData)));
      } else if (data is Map) {
        final requestData = data['request'] ?? data;
        addRequest(RideRequestModel.fromMap(Map<String, dynamic>.from(requestData)));
      }
    }

    SocketService.on('ride-request:new', handleIncoming);
    SocketService.on('new_ride_request', handleIncoming);

    SocketService.on('ride_request_status_update', (data) {
      if (data is Map) {
        final requestId = data['requestId']?.toString();
        final status = data['status']?.toString().toLowerCase();

        if (requestId != null && requestId.isNotEmpty) {
          if (status == 'rejected' ||
              status == 'cancelled' ||
              status == 'expired' ||
              status == 'accepted') {
            removePendingRequest(requestId);
          }
        }
      }
    });

    SocketService.on('ride-request:rejected', (data) {
      if (data is Map && data['requestId'] != null) {
        removePendingRequest(data['requestId'].toString());
      }
    });

    SocketService.on('ride-request:accepted', (data) {
      if (data is Map) {
        final requestId = data['requestId']?.toString();
        if (requestId != null && requestId.isNotEmpty) {
          removePendingRequest(requestId);

          final matched = _pendingRequests.cast<RideRequestModel?>().firstWhere(
                (e) => e?.requestId == requestId,
            orElse: () => null,
          );

          if (matched != null) {
            _confirmedRides.removeWhere((ride) => ride.requestId == requestId);
            _confirmedRides.add(
              ConfirmedRideData(
                confirmedRideId: data['confirmedRideId']?.toString() ?? '',
                requestId: requestId,
                request: matched,
                confirmedAt: DateTime.tryParse(
                  data['confirmedAt']?.toString() ?? '',
                ) ??
                    DateTime.now(),
              ),
            );
          }
        }
      }
    });

    SocketService.on('confirmed-ride:cancelled', (data) {
      if (data is Map) {
        final requestId = data['requestId']?.toString();
        if (requestId != null && requestId.isNotEmpty) {
          _confirmedRides.removeWhere((ride) => ride.requestId == requestId);
        }

        final dueBalance = data['dueBalance'];
        if (dueBalance != null) {
          dueFineNotifier.value = (dueBalance as num).toDouble();
        }
      }
    });

    await loadPendingRequests();
  }

  static void removePendingRequest(String requestId) {
    _pendingRequests.removeWhere((r) => r.requestId == requestId);
  }

  static void addRequest(RideRequestModel request) {
    final alreadyExistsInPending =
    _pendingRequests.any((e) => e.requestId == request.requestId);

    final alreadyConfirmed =
    _confirmedRides.any((e) => e.requestId == request.requestId);

    if (alreadyExistsInPending || alreadyConfirmed) return;

    _pendingRequests.add(request);
    _showNextIfPossible();
  }

  static List<ConfirmedRideData> getConfirmedRides() {
    return List.unmodifiable(_confirmedRides);
  }

  static Future<void> loadPendingRequests() async {
    try {
      final response = await _api.getScoredPendingRideRequests();
      final List rawList = (response['data'] ?? []) as List;

      for (final item in rawList) {
        final request = RideRequestModel.fromMap(
          Map<String, dynamic>.from(item as Map),
        );
        addRequest(request);
      }
    } catch (_) {}
  }

  static void removeConfirmedRide(String confirmedRideId) {
    _confirmedRides.removeWhere((ride) => ride.confirmedRideId == confirmedRideId);
  }

  static Future<CancelRideResult> rejectConfirmedRide(String requestId) async {
    try {
      final response = await _api.cancelAcceptedRideRequest(
        requestId: requestId,
        cancelReason: 'cancelled_by_rider',
      );

      final data = response['data'] ?? {};
      final fineAmount = (data['fineAmount'] ?? 0).toDouble();
      final dueBalance = data['dueBalance'];

      if (dueBalance != null) {
        dueFineNotifier.value = (dueBalance as num).toDouble();
      }

      _confirmedRides.removeWhere((ride) => ride.requestId == requestId);
      _pendingRequests.removeWhere((ride) => ride.requestId == requestId);

      return CancelRideResult(
        success: true,
        message: response['message'] ?? 'Ride cancelled successfully.',
        fineAdded: fineAmount,
      );
    } catch (e) {
      return CancelRideResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
        fineAdded: 0,
      );
    }
  }

  static void _showNextIfPossible() {
    if (_isDialogShowing) return;
    if (_pendingRequests.isEmpty) return;
    if (_navigatorKey?.currentContext == null) return;

    final BuildContext context = _navigatorKey!.currentContext!;
    final RideRequestModel request = _pendingRequests.first;

    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RideRequestDialog(request: request),
    ).then((_) {
      _isDialogShowing = false;
      Future.delayed(const Duration(milliseconds: 250), () {
        _showNextIfPossible();
      });
    });
  }
  static Future<void> confirmRequest(
      BuildContext context,
      RideRequestModel request,
      ) async {
    try {
      final response = await _api.acceptRideRequest(
        requestId: request.requestId,
      );

      final data = response['data'] ?? {};

      _pendingRequests.removeWhere((r) => r.requestId == request.requestId);

      if (data['status']?.toString().toLowerCase() == 'accepted') {
        _confirmedRides.removeWhere((ride) => ride.requestId == request.requestId);

        _confirmedRides.add(
          ConfirmedRideData(
            confirmedRideId: (data['rideId'] ?? '').toString(),
            requestId: (data['requestId'] ?? request.requestId).toString(),
            request: request,
            confirmedAt: DateTime.tryParse(
              data['confirmedAt']?.toString() ?? '',
            ) ??
                DateTime.now(),
          ),
        );
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      final passengerPhone = request.phoneNumber;
      if (passengerPhone.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _ConfirmedRidePhoneDialog(
            passengerName: request.passengerName,
            passengerPhone: passengerPhone,
          ),
        );
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? "Ride confirmed for ${request.passengerName}",
            ),
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  static Future<void> rejectIncomingRequest(
      BuildContext context,
      RideRequestModel request,
      ) async {
    try {
      final response = await _api.rejectRideRequest(
        requestId: request.requestId,
      );

      _pendingRequests.removeWhere((r) => r.requestId == request.requestId);

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? "Ride request rejected for ${request.passengerName}",
          ),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }
}

class _RideRequestDialog extends StatelessWidget {
  final RideRequestModel request;

  const _RideRequestDialog({required this.request});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: const Text(
        "New Ride Request",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow("Name", request.passengerName),
            _infoRow("Email", request.passengerEmail),
            _infoRow("Phone", request.phoneNumber),
            _infoRow("Location", request.currentLocation),
            _infoRow("Destination", request.destination),
            _infoRow("Distance", "${request.distanceKm.toStringAsFixed(1)} km"),
            _infoRow("Fare", "৳${request.fare.toStringAsFixed(0)}"),
            _infoRow("Time", "${request.estimatedMinutes} min"),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await RideRequestService.rejectIncomingRequest(context, request);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Reject",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await RideRequestService.confirmRequest(context, request);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

class ConfirmedRideData {
  final String confirmedRideId;
  final String requestId;
  final RideRequestModel request;
  final DateTime confirmedAt;

  ConfirmedRideData({
    required this.confirmedRideId,
    required this.requestId,
    required this.request,
    required this.confirmedAt,
  });

  bool get isFreeCancelAvailable {
    return DateTime.now().difference(confirmedAt).inMinutes < 5;
  }

  int get remainingFreeCancelSeconds {
    final passed = DateTime.now().difference(confirmedAt).inSeconds;
    const total = 5 * 60;
    final left = total - passed;
    return left > 0 ? left : 0;
  }
}

class CancelRideResult {
  final bool success;
  final String message;
  final double fineAdded;

  CancelRideResult({
    required this.success,
    required this.message,
    required this.fineAdded,
  });
}

class _ConfirmedRidePhoneDialog extends StatelessWidget {
  final String passengerName;
  final String passengerPhone;

  const _ConfirmedRidePhoneDialog({
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 26),
          SizedBox(width: 8),
          Text(
            'Ride Confirmed!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger: $passengerName',
            style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Contact the passenger:',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone, color: Color(0xFF16A34A), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    passengerPhone,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: passengerPhone);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}