import 'dart:async';
import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color card = Colors.white;
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF16A34A);
  static const Color gold = Color(0xFFF59E0B);
}

class RideRequestsPage extends StatefulWidget {
  const RideRequestsPage({super.key});

  @override
  State<RideRequestsPage> createState() => _RideRequestsPageState();
}

class _RideRequestsPageState extends State<RideRequestsPage> {
  final AuthApiService _authApiService = AuthApiService();

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  bool _hasActiveRide = false;
  Map<String, dynamic>? _ride;
  List<dynamic> _confirmedPassengers = [];
  List<dynamic> _pendingRequests = [];

  Timer? _pollTimer;
  final Set<String> _busyRequestIds = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard(showLoader: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _loadDashboard(showLoader: false);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard({bool showLoader = false}) async {
    if (_isRefreshing) return;
    if (showLoader && mounted) setState(() => _isLoading = true);
    setState(() => _isRefreshing = true);

    try {
      final response = await _authApiService.getRiderRideRequestDashboard();
      final data = response['data'] ?? {};

      if (!mounted) return;
      setState(() {
        _hasActiveRide = data['hasActiveRide'] == true;
        _ride = data['ride'] != null ? Map<String, dynamic>.from(data['ride']) : null;
        _confirmedPassengers = data['confirmedPassengers'] ?? [];
        _pendingRequests = data['pendingRequests'] ?? [];
        _error = null;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _accept(String requestId) async {
    if (_busyRequestIds.contains(requestId)) return;
    setState(() => _busyRequestIds.add(requestId));
    try {
      await _authApiService.acceptRideRequest(requestId: requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger confirmed.'), backgroundColor: AppColors.success),
      );
      await _loadDashboard(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyRequestIds.remove(requestId));
    }
  }

  Future<void> _reject(String requestId) async {
    if (_busyRequestIds.contains(requestId)) return;
    setState(() => _busyRequestIds.add(requestId));
    try {
      await _authApiService.rejectRideRequest(requestId: requestId);
      if (!mounted) return;
      await _loadDashboard(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyRequestIds.remove(requestId));
    }
  }

  Future<void> _cancelConfirmed(String requestId, String passengerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel this passenger?'),
        content: Text(
          'Cancel the confirmed booking for $passengerName? A fine may apply if the free-cancel window has passed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (_busyRequestIds.contains(requestId)) return;
    setState(() => _busyRequestIds.add(requestId));

    try {
      await _authApiService.cancelAcceptedRideRequest(requestId: requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );
      await _loadDashboard(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyRequestIds.remove(requestId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Ride Requests",
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadDashboard(showLoader: false),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
        ],
      );
    }

    if (!_hasActiveRide) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.directions_car_outlined, size: 56, color: AppColors.mutedText),
          const SizedBox(height: 16),
          const Text(
            "No active ride",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          const Text(
            "Activate your ride to see passenger requests.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppColors.mutedText),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildRideSummaryCard(),
        const SizedBox(height: 20),
        _sectionTitle("Confirmed passengers (${_confirmedPassengers.length})"),
        const SizedBox(height: 10),
        if (_confirmedPassengers.isEmpty)
          _emptyHint("No passengers confirmed yet.")
        else
          ..._confirmedPassengers.map(_buildConfirmedCard),
        const SizedBox(height: 24),
        _sectionTitle("Pending requests (${_pendingRequests.length})"),
        const SizedBox(height: 10),
        if (_pendingRequests.isEmpty)
          _emptyHint("No new requests right now.")
        else
          ..._pendingRequests.map(_buildPendingCard),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.text),
  );

  Widget _emptyHint(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.mutedText, fontSize: 13.5)),
  );

  Widget _buildRideSummaryCard() {
    final ride = _ride ?? {};
    final seats = ride['availableSeats'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_seat_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "$seats seat(s) available",
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${ride['startLocation'] ?? ''} → ${ride['destination'] ?? ''}",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedCard(dynamic item) {
    final requestId = (item['requestId'] ?? '').toString();
    final name = (item['passengerName'] ?? 'Passenger').toString();
    final isBusy = _busyRequestIds.contains(requestId);
    final canFreeCancel = item['isFreeCancelAvailable'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'P',
              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 3),
                Text(
                  "${item['pickupLocation'] ?? ''} → ${item['destination'] ?? ''}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
                if (canFreeCancel) ...[
                  const SizedBox(height: 4),
                  const Text(
                    "Free cancel এখনো available",
                    style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          isBusy
              ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
            onPressed: () => _cancelConfirmed(requestId, name),
            icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(dynamic item) {
    final requestId = (item['requestId'] ?? '').toString();
    final name = (item['passengerName'] ?? 'Passenger').toString();
    final tier = item['tier'];
    final isBusy = _busyRequestIds.contains(requestId);
    final isFrequent = item['isFrequentPassenger'] == true;
    final detourKm = item['detourKm'];
    final destDistanceKm = item['destDistanceKm'];

    Color? tierColor;
    String? tierLabel;
    if (tier == 'best') {
      tierColor = AppColors.gold;
      tierLabel = '⭐ Best Match';
    } else if (tier == 'good') {
      tierColor = AppColors.primary;
      tierLabel = 'Good Match';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tierColor ?? AppColors.border, width: tierColor != null ? 1.6 : 1),
        boxShadow: [
          BoxShadow(
            color: (tierColor ?? Colors.black).withOpacity(tierColor != null ? 0.10 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
              ),
              if (tierLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: tierColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(tierLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${item['pickupAddress'] ?? ''} → ${item['destinationAddress'] ?? ''}",
            style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _miniBadge("৳${((item['fare'] as num?) ?? 0).toStringAsFixed(0)}"),
              if (detourKm != null) _miniBadge("+${(detourKm as num).toStringAsFixed(1)} km detour"),
              if (destDistanceKm != null) _miniBadge("${(destDistanceKm as num).toStringAsFixed(2)} km off-route"),
              if (isFrequent)
                _miniBadge("Frequent passenger", color: AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : () => _reject(requestId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : () => _accept(requestId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isBusy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String text, {Color color = AppColors.secondary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}