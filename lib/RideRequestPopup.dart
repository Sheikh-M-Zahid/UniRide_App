import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/auth_api_service.dart';
import 'RideRequestService.dart';
import 'RideRequestModel.dart';

class RideRequestPopup extends StatefulWidget {
  final String requestId;

  const RideRequestPopup({super.key, required this.requestId});

  @override
  State<RideRequestPopup> createState() => _RideRequestPopupState();
}

class _RideRequestPopupState extends State<RideRequestPopup> {
  final AuthApiService _api = AuthApiService();
  bool _isLoading = true;
  bool _isActing = false;
  Map<String, dynamic>? _requestData;
  String? _actionDone; // 'confirmed' or 'rejected'
  String? _confirmedPhone;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final res = await _api.getRideRequestStatus(requestId: widget.requestId);
      if (!mounted) return;
      setState(() {
        _requestData = res['data'] is Map
            ? Map<String, dynamic>.from(res['data'] as Map)
            : null;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirm() async {
    if (_isActing || _requestData == null) return;
    setState(() => _isActing = true);

    final model = RideRequestModel.fromMap(_requestData!);

    try {
      await RideRequestService.confirmRequest(context, model);
      if (!mounted) return;
      setState(() {
        _actionDone = 'confirmed';
        _confirmedPhone = model.phoneNumber;
        _isActing = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _reject() async {
    if (_isActing || _requestData == null) return;
    setState(() => _isActing = true);

    final model = RideRequestModel.fromMap(_requestData!);

    try {
      await RideRequestService.rejectIncomingRequest(context, model);
      if (!mounted) return;
      setState(() {
        _actionDone = 'rejected';
        _isActing = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: _isLoading
                ? const SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF14B8A6),
                ),
              ),
            )
                : _requestData == null
                ? const SizedBox(
              height: 100,
              child: Center(
                child: Text('Could not load request details.'),
              ),
            )
                : _actionDone != null
                ? _buildResultView()
                : _buildRequestView(),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B7280),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestView() {
    final d = _requestData!;
    final status = (d['status'] ?? '').toString().toLowerCase();
    final isStillPending = status == 'pending';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Ride Request',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isStillPending
                      ? Colors.orange.shade400
                      : status == 'accepted'
                      ? Colors.green.shade400
                      : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _row(Icons.person, 'Passenger', (d['passengerName'] ?? d['passenger_name'] ?? 'N/A').toString()),
        const SizedBox(height: 10),
        _row(Icons.email_outlined, 'Email', (d['passengerEmail'] ?? d['passenger_email'] ?? 'N/A').toString()),
        const SizedBox(height: 10),
        _row(Icons.my_location, 'Current Location', (d['pickupAddress'] ?? d['pickup_location'] ?? 'N/A').toString()),
        const SizedBox(height: 10),
        _row(Icons.location_on, 'Destination', (d['destinationAddress'] ?? d['destination'] ?? 'N/A').toString()),
        const SizedBox(height: 10),
        _row(Icons.access_time, 'Est. Time', '${d['estimatedMinutes'] ?? d['estimated_minutes'] ?? 0} min'),
        const SizedBox(height: 10),
        _row(
          Icons.monetization_on,
          'Fare',
          '৳${d['fare'] ?? d['estimated_fare'] ?? 0}',
          valueColor: const Color(0xFF0F766E),
        ),
        const SizedBox(height: 20),
        if (isStillPending)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isActing ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: _isActing
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFDC2626),
                    ),
                  )
                      : const Text(
                    'Reject',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isActing ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: _isActing
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }

  Widget _buildResultView() {
    final isConfirmed = _actionDone == 'confirmed';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isConfirmed ? Icons.check_circle : Icons.cancel,
          color: isConfirmed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          size: 56,
        ),
        const SizedBox(height: 14),
        Text(
          isConfirmed ? 'Ride Confirmed!' : 'Request Rejected',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isConfirmed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        ),
        if (isConfirmed && _confirmedPhone != null && _confirmedPhone!.isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone, color: Color(0xFF16A34A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Passenger Phone',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        _confirmedPhone!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final uri = Uri(scheme: 'tel', path: _confirmedPhone);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.call, color: Color(0xFF16A34A)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F766E)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}