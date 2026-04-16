import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color card = Colors.white;
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);
}

class RiderSharingHistoryPage extends StatefulWidget {
  const RiderSharingHistoryPage({super.key});

  @override
  State<RiderSharingHistoryPage> createState() =>
      _RiderSharingHistoryPageState();
}

class _RiderSharingHistoryPageState extends State<RiderSharingHistoryPage> {
  late Future<List<RiderSharingHistoryModel>> _futureHistory;
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _futureHistory = _loadHistory();
  }

  Future<List<RiderSharingHistoryModel>> _loadHistory() {
    return RiderSharingHistoryService().fetchRideHistory(
      search: _searchController.text.trim(),
      status: _selectedStatus,
    );
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _futureHistory = _loadHistory();
    });
    await _futureHistory;
  }

  void _applyFilters() {
    setState(() {
      _futureHistory = _loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _countByStatus(List<RiderSharingHistoryModel> items, String status) {
    return items.where((e) => e.rideStatus.toLowerCase() == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rider Sharing History',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshHistory,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _TopFilterSection(
                searchController: _searchController,
                selectedStatus: _selectedStatus,
                onSearch: _applyFilters,
                onStatusChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                    _futureHistory = _loadHistory();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<RiderSharingHistoryModel>>(
                future: _futureHistory,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingView();
                  }

                  if (snapshot.hasError) {
                    return _ErrorView(
                      message: snapshot.error.toString(),
                      onRetry: _refreshHistory,
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return _EmptyView(onRefresh: _refreshHistory);
                  }

                  final completedCount = _countByStatus(items, 'completed');
                  final cancelledCount = _countByStatus(items, 'cancelled');
                  final scheduledCount = _countByStatus(items, 'scheduled');
                  final ongoingCount = _countByStatus(items, 'ongoing');

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      _OverviewCard(
                        totalRides: items.length,
                        completedCount: completedCount,
                        cancelledCount: cancelledCount,
                        scheduledCount: scheduledCount,
                        ongoingCount: ongoingCount,
                      ),
                      const SizedBox(height: 16),
                      const _SectionTitle(title: 'Ride Records'),
                      const SizedBox(height: 10),
                      ...List.generate(
                        items.length,
                            (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RideHistoryCard(item: items[index]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopFilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final VoidCallback onSearch;
  final ValueChanged<String> onStatusChanged;

  const _TopFilterSection({
    required this.searchController,
    required this.selectedStatus,
    required this.onSearch,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'Search by rider name, ride ID, vehicle number',
            hintStyle: const TextStyle(color: AppColors.mutedText),
            prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.mutedText),
            suffixIcon: IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusDropdown(
                value: selectedStatus,
                onChanged: onStatusChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
            DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final int totalRides;
  final int completedCount;
  final int cancelledCount;
  final int scheduledCount;
  final int ongoingCount;

  const _OverviewCard({
    required this.totalRides,
    required this.completedCount,
    required this.cancelledCount,
    required this.scheduledCount,
    required this.ongoingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride Sharing Records',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalRides Total Rides',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderChip(
                label: 'Completed: $completedCount',
                icon: Icons.check_circle_rounded,
              ),
              _HeaderChip(
                label: 'Cancelled: $cancelledCount',
                icon: Icons.cancel_rounded,
              ),
              _HeaderChip(
                label: 'Scheduled: $scheduledCount',
                icon: Icons.schedule_rounded,
              ),
              _HeaderChip(
                label: 'Ongoing: $ongoingCount',
                icon: Icons.directions_car_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeaderChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  final RiderSharingHistoryModel item;

  const _RideHistoryCard({required this.item});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      case 'ongoing':
        return AppColors.info;
      case 'scheduled':
        return AppColors.warning;
      default:
        return AppColors.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.rideStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.10),
                backgroundImage: item.riderPhotoUrl.isNotEmpty
                    ? NetworkImage(item.riderPhotoUrl)
                    : null,
                child: item.riderPhotoUrl.isEmpty
                    ? const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.riderName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.vehicleType.isEmpty
                          ? 'Vehicle not available'
                          : '${item.vehicleType} • ${item.vehicleNumber}',
                      style: const TextStyle(
                        fontSize: 12.8,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: item.rideStatus,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.confirmation_number_rounded,
            label: 'Ride ID',
            value: item.rideId,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.route_rounded,
            label: 'Route',
            value: '${item.pickupLocation} → ${item.destinationLocation}',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniInfoBox(
                  title: 'Date',
                  value: item.rideDate,
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  title: 'Time',
                  value: item.departureTime,
                  icon: Icons.access_time_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniInfoBox(
                  title: 'Seats',
                  value: '${item.bookedSeats}/${item.offeredSeats}',
                  icon: Icons.event_seat_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  title: 'Fare',
                  value: item.fareDisplay,
                  icon: Icons.payments_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.phone_rounded,
            label: 'Rider Phone',
            value: item.riderPhone,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniInfoBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 150),
        Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.error_outline_rounded,
          size: 72,
          color: AppColors.danger,
        ),
        const SizedBox(height: 14),
        const Text(
          'Failed to load ride history',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.history_toggle_off_rounded,
          size: 72,
          color: AppColors.mutedText,
        ),
        const SizedBox(height: 14),
        const Text(
          'No ride history found',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ride sharing history will appear here when your backend sends data.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: onRefresh,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Refresh'),
        ),
      ],
    );
  }
}

class RiderSharingHistoryModel {
  final String rideId;
  final String riderName;
  final String riderPhone;
  final String riderPhotoUrl;
  final String vehicleType;
  final String vehicleNumber;
  final String pickupLocation;
  final String destinationLocation;
  final String departureTime;
  final String rideDate;
  final int offeredSeats;
  final int bookedSeats;
  final double fare;
  final String rideStatus;

  const RiderSharingHistoryModel({
    required this.rideId,
    required this.riderName,
    required this.riderPhone,
    required this.riderPhotoUrl,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.departureTime,
    required this.rideDate,
    required this.offeredSeats,
    required this.bookedSeats,
    required this.fare,
    required this.rideStatus,
  });

  factory RiderSharingHistoryModel.fromJson(Map<String, dynamic> json) {
    return RiderSharingHistoryModel(
      rideId: (json['ride_id'] ?? '').toString(),
      riderName: (json['rider_name'] ?? '').toString(),
      riderPhone: (json['rider_phone'] ?? '').toString(),
      riderPhotoUrl: (json['rider_photo_url'] ?? '').toString(),
      vehicleType: (json['vehicle_type'] ?? '').toString(),
      vehicleNumber: (json['vehicle_number'] ?? '').toString(),
      pickupLocation: (json['pickup_location'] ?? '').toString(),
      destinationLocation: (json['destination_location'] ?? '').toString(),
      departureTime: (json['departure_time'] ?? '').toString(),
      rideDate: (json['ride_date'] ?? '').toString(),
      offeredSeats: _toInt(json['offered_seats']),
      bookedSeats: _toInt(json['booked_seats']),
      fare: _toDouble(json['fare']),
      rideStatus: (json['ride_status'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String get fareDisplay => '৳${fare.toStringAsFixed(0)}';
}

class RiderSharingHistoryService {
  Future<List<RiderSharingHistoryModel>> fetchRideHistory({
    String search = '',
    String status = 'all',
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    throw UnimplementedError(
      'Connect this service with your Node.js + PostgreSQL backend API.',
    );

    /*
    Example backend response:

    [
      {
        "ride_id": "RIDE-1001",
        "rider_name": "Rahim Uddin",
        "rider_phone": "017XXXXXXXX",
        "rider_photo_url": "",
        "vehicle_type": "Bike",
        "vehicle_number": "Dhaka Metro-LA-12-3456",
        "pickup_location": "Main Gate",
        "destination_location": "Academic Building",
        "departure_time": "09:30 AM",
        "ride_date": "2026-03-15",
        "offered_seats": 2,
        "booked_seats": 1,
        "fare": 60,
        "ride_status": "completed"
      }
    ]

    Suggested query params:
    - search
    - status

    Example:
    GET /admin/rider-sharing-history?search=rahim&status=completed
    */
  }
}