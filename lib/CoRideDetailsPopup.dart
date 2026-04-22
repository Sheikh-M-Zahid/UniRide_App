import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'CoRideLiveMapPage.dart';

class CoRideDetailsPopup extends StatefulWidget {
  final String sessionId;

  const CoRideDetailsPopup({super.key, required this.sessionId});

  @override
  State<CoRideDetailsPopup> createState() => _CoRideDetailsPopupState();
}

class _CoRideDetailsPopupState extends State<CoRideDetailsPopup> {
  final AuthApiService _api = AuthApiService();
  bool _isLoading = true;
  bool _isBooking = false;
  Map<String, dynamic>? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final res = await _api.getCoRideSessionDetails(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _session = res['data'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _bookNow() async {
    if (_isBooking) return;
    setState(() => _isBooking = true);
    try {
      await _api.bookCoRideSession(widget.sessionId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed! Check your notifications for contact details.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
              ),
            )
                : _session == null
                ? const SizedBox(
              height: 100,
              child: Center(child: Text('Could not load ride details.')),
            )
                : _buildContent(),
          ),
          // Cross (✕) button — upper right
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

  Widget _buildContent() {
    final s = _session!;
    final creatorName = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    final availableSeats = (s['total_seats'] ?? 2) - (s['booked_seats'] ?? 0);
    final isStarted = s['is_started'] == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'CoRide Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isStarted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🟢 Live',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                creatorName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Details
        _detailRow(Icons.my_location, 'From', s['start_location'] ?? ''),
        const SizedBox(height: 10),
        _detailRow(Icons.location_on, 'To', s['destination'] ?? ''),
        const SizedBox(height: 10),
        _detailRow(Icons.calendar_today, 'Date', s['trip_date'] ?? 'N/A'),
        const SizedBox(height: 10),
        _detailRow(Icons.access_time, 'Time', s['trip_time'] ?? 'N/A'),
        const SizedBox(height: 10),
        _detailRow(
          Icons.event_seat,
          'Available Seats',
          '$availableSeats seat${availableSeats != 1 ? 's' : ''}',
          valueColor: availableSeats > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
        const SizedBox(height: 10),
        _detailRow(
          Icons.monetization_on,
          'Fare per person',
          '৳${s['fare_per_person'] ?? 'N/A'}',
          valueColor: const Color(0xFF0F766E),
        ),

        const SizedBox(height: 20),

        // Live Location button (if started)
        if (isStarted) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoRideLiveMapPage(sessionId: widget.sessionId),
                  ),
                );
              },
              icon: const Icon(Icons.location_on, color: Color(0xFF14B8A6)),
              label: const Text(
                'Track Live Location',
                style: TextStyle(color: Color(0xFF14B8A6)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF14B8A6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Book Now button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: availableSeats > 0 ? _bookNow : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: availableSeats > 0
                  ? const Color(0xFF14B8A6)
                  : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isBooking
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              availableSeats > 0 ? 'Book Now' : 'Fully Booked',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
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
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
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
