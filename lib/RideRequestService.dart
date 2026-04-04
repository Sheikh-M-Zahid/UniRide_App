import 'dart:collection';
import 'package:flutter/material.dart';
import 'RideRequestModel.dart';

class RideRequestService {
  RideRequestService._();

  static final Queue<RideRequestModel> _queue = Queue<RideRequestModel>();
  static final List<ConfirmedRideData> _confirmedRides = [];

  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isDialogShowing = false;

  // Wallet due / fine tracking
  static final ValueNotifier<double> dueFineNotifier = ValueNotifier<double>(0);

  static const int freeCancelMinutes = 5;
  static const double lateCancelFine = 50;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  static void addRequest(RideRequestModel request) {
    _queue.add(request);
    _showNextIfPossible();
  }

  static List<ConfirmedRideData> getConfirmedRides() {
    return List.unmodifiable(_confirmedRides);
  }

  static void removeConfirmedRide(String confirmedRideId) {
    _confirmedRides.removeWhere((ride) => ride.confirmedRideId == confirmedRideId);
  }

  static CancelRideResult rejectConfirmedRide(String confirmedRideId) {
    final index = _confirmedRides.indexWhere(
          (ride) => ride.confirmedRideId == confirmedRideId,
    );

    if (index == -1) {
      return CancelRideResult(
        success: false,
        message: "Ride not found.",
        fineAdded: 0,
      );
    }

    final ride = _confirmedRides[index];
    final now = DateTime.now();
    final difference = now.difference(ride.confirmedAt);

    double fine = 0;

    if (difference.inMinutes >= freeCancelMinutes) {
      fine = lateCancelFine;
      dueFineNotifier.value += fine;
    }

    _confirmedRides.removeAt(index);

    return CancelRideResult(
      success: true,
      message: fine > 0
          ? "Ride cancelled. ৳${fine.toStringAsFixed(0)} fine added to due."
          : "Ride cancelled successfully within 5 minutes.",
      fineAdded: fine,
    );
  }

  static void _showNextIfPossible() {
    if (_isDialogShowing) return;
    if (_queue.isEmpty) return;
    if (_navigatorKey?.currentContext == null) return;

    final BuildContext context = _navigatorKey!.currentContext!;
    final RideRequestModel request = _queue.removeFirst();

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

  static void confirmRequest(BuildContext context, RideRequestModel request) {
    final confirmedRide = ConfirmedRideData(
      confirmedRideId: DateTime.now().microsecondsSinceEpoch.toString(),
      request: request,
      confirmedAt: DateTime.now(),
    );

    _confirmedRides.add(confirmedRide);

    Navigator.pop(context);

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          "Ride confirmed for ${request.passengerName}",
        ),
      ),
    );
  }

  static void rejectIncomingRequest(BuildContext context, RideRequestModel request) {
    Navigator.pop(context);

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          "Ride request rejected for ${request.passengerName}",
        ),
      ),
    );
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
                onPressed: () {
                  RideRequestService.rejectIncomingRequest(context, request);
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
                onPressed: () {
                  RideRequestService.confirmRequest(context, request);
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
  final RideRequestModel request;
  final DateTime confirmedAt;

  ConfirmedRideData({
    required this.confirmedRideId,
    required this.request,
    required this.confirmedAt,
  });

  bool get isFreeCancelAvailable {
    return DateTime.now().difference(confirmedAt).inMinutes < RideRequestService.freeCancelMinutes;
  }

  int get remainingFreeCancelSeconds {
    final passed = DateTime.now().difference(confirmedAt).inSeconds;
    final total = RideRequestService.freeCancelMinutes * 60;
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