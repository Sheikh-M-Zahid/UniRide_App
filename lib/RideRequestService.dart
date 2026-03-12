import 'dart:collection';
import 'package:flutter/material.dart';
import 'RideRequestModel.dart';

class RideRequestService {
  RideRequestService._();

  static final Queue<RideRequestModel> _queue = Queue<RideRequestModel>();
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isDialogShowing = false;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  static void addRequest(RideRequestModel request) {
    _queue.add(request);
    _showNextIfPossible();
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(
                  content: Text(
                    "Ride confirmed for ${request.passengerName}",
                  ),
                ),
              );
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