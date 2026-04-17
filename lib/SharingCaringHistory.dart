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
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);
}

class SharingCaringHistoryPage extends StatefulWidget {
  const SharingCaringHistoryPage({super.key});

  @override
  State<SharingCaringHistoryPage> createState() =>
      _SharingCaringHistoryPageState();
}

class _SharingCaringHistoryPageState extends State<SharingCaringHistoryPage> {
  late Future<List<SharingCaringHistoryModel>> _futureTrips;
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'all';
  String _selectedSafety = 'all';

  @override
  void initState() {
    super.initState();
    _futureTrips = _loadTrips();
  }

  Future<List<SharingCaringHistoryModel>> _loadTrips() {
    return SharingCaringHistoryService().fetchSharingCaringHistory(
      search: _searchController.text.trim(),
      status: _selectedStatus,
      safety: _selectedSafety,
    );
  }

  Future<void> _refreshTrips() async {
    setState(() {
      _futureTrips = _loadTrips();
    });
    await _futureTrips;
  }

  void _applyFilters() {
    setState(() {
      _futureTrips = _loadTrips();
    });
  }

  int _countByStatus(List<SharingCaringHistoryModel> items, String status) {
    return items.where((e) => e.tripStatus.toLowerCase() == status).length;
  }

  int _countFlagged(List<SharingCaringHistoryModel> items) {
    return items.where((e) => e.hasSafetyFlag).length;
  }

  int _countSafe(List<SharingCaringHistoryModel> items) {
    return items.where((e) => !e.hasSafetyFlag).length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Sharing & Caring History',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshTrips,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _TopFilterSection(
                searchController: _searchController,
                selectedStatus: _selectedStatus,
                selectedSafety: _selectedSafety,
                onSearch: _applyFilters,
                onStatusChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                    _futureTrips = _loadTrips();
                  });
                },
                onSafetyChanged: (value) {
                  setState(() {
                    _selectedSafety = value;
                    _futureTrips = _loadTrips();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<SharingCaringHistoryModel>>(
                future: _futureTrips,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingView();
                  }

                  if (snapshot.hasError) {
                    return _ErrorView(
                      message: snapshot.error.toString(),
                      onRetry: _refreshTrips,
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return _EmptyView(onRefresh: _refreshTrips);
                  }

                  final completedCount = _countByStatus(items, 'completed');
                  final cancelledCount = _countByStatus(items, 'cancelled');
                  final scheduledCount = _countByStatus(items, 'scheduled');
                  final ongoingCount = _countByStatus(items, 'ongoing');
                  final flaggedCount = _countFlagged(items);
                  final safeCount = _countSafe(items);

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      _OverviewCard(
                        totalTrips: items.length,
                        completedCount: completedCount,
                        cancelledCount: cancelledCount,
                        scheduledCount: scheduledCount,
                        ongoingCount: ongoingCount,
                        flaggedCount: flaggedCount,
                        safeCount: safeCount,
                      ),
                      const SizedBox(height: 16),
                      const _SectionTitle(title: 'Shared Trip Records'),
                      const SizedBox(height: 10),
                      ...List.generate(
                        items.length,
                            (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SharingTripCard(item: items[index]),
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
  final String selectedSafety;
  final VoidCallback onSearch;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSafetyChanged;

  const _TopFilterSection({
    required this.searchController,
    required this.selectedStatus,
    required this.selectedSafety,
    required this.onSearch,
    required this.onStatusChanged,
    required this.onSafetyChanged,
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
            hintText: 'Search by creator name, trip ID, pickup, destination',
            hintStyle: const TextStyle(color: AppColors.mutedText),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.mutedText,
            ),
            suffixIcon: IconButton(
              onPressed: onSearch,
              icon: const Icon(
                Icons.tune_rounded,
                color: AppColors.primary,
              ),
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
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.2,
              ),
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
            const SizedBox(width: 10),
            Expanded(
              child: _SafetyDropdown(
                value: selectedSafety,
                onChanged: onSafetyChanged,
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

class _SafetyDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SafetyDropdown({
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
            DropdownMenuItem(value: 'all', child: Text('All Safety')),
            DropdownMenuItem(value: 'safe', child: Text('Safe Trips')),
            DropdownMenuItem(value: 'flagged', child: Text('Flagged Trips')),
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
  final int totalTrips;
  final int completedCount;
  final int cancelledCount;
  final int scheduledCount;
  final int ongoingCount;
  final int flaggedCount;
  final int safeCount;

  const _OverviewCard({
    required this.totalTrips,
    required this.completedCount,
    required this.cancelledCount,
    required this.scheduledCount,
    required this.ongoingCount,
    required this.flaggedCount,
    required this.safeCount,
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
            'Shared Trip Overview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalTrips Total Trips',
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
                icon: Icons.route_rounded,
              ),
              _HeaderChip(
                label: 'Flagged: $flaggedCount',
                icon: Icons.report_problem_rounded,
              ),
              _HeaderChip(
                label: 'Safe: $safeCount',
                icon: Icons.verified_user_rounded,
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

class _SharingTripCard extends StatelessWidget {
  final SharingCaringHistoryModel item;

  const _SharingTripCard({required this.item});

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
    final statusColor = _statusColor(item.tripStatus);

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
                backgroundImage: item.creatorPhotoUrl.isNotEmpty
                    ? NetworkImage(item.creatorPhotoUrl)
                    : null,
                child: item.creatorPhotoUrl.isEmpty
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
                      item.creatorName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.creatorType.isEmpty
                          ? 'Creator type not available'
                          : item.creatorType,
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
                label: item.tripStatus,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.confirmation_number_rounded,
            label: 'Trip ID',
            value: item.tripId,
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
                  value: item.tripDate,
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  title: 'Time',
                  value: item.tripTime,
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
                  title: 'Total Cost',
                  value: item.totalCostDisplay,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  title: 'Per Seat',
                  value: item.perSeatCostDisplay,
                  icon: Icons.payments_rounded,
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
                  value: '${item.joinedMembers}/${item.totalSeats}',
                  icon: Icons.event_seat_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  title: 'Vehicle',
                  value: item.vehicleType.isEmpty ? 'N/A' : item.vehicleType,
                  icon: Icons.directions_car_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.phone_rounded,
            label: 'Contact',
            value: item.creatorPhone,
          ),
          const SizedBox(height: 10),
          _SafetyInfoCard(item: item),
        ],
      ),
    );
  }
}

class _SafetyInfoCard extends StatelessWidget {
  final SharingCaringHistoryModel item;

  const _SafetyInfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final Color color =
    item.hasSafetyFlag ? AppColors.danger : AppColors.success;
    final String title =
    item.hasSafetyFlag ? 'Safety Report Found' : 'No Safety Report';
    final String subtitle = item.hasSafetyFlag
        ? (item.safetyNote.isEmpty ? 'Flagged by system or user report.' : item.safetyNote)
        : 'This trip has no active safety issue.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.hasSafetyFlag
                ? Icons.report_problem_rounded
                : Icons.verified_user_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12.5,
                    height: 1.4,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          'Failed to load trip history',
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
          Icons.groups_rounded,
          size: 72,
          color: AppColors.mutedText,
        ),
        const SizedBox(height: 14),
        const Text(
          'No shared trip history found',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sharing & Caring history will appear here when your backend sends data.',
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

class SharingCaringHistoryModel {
  final String tripId;
  final String creatorName;
  final String creatorType;
  final String creatorPhone;
  final String creatorPhotoUrl;
  final String vehicleType;
  final String pickupLocation;
  final String destinationLocation;
  final String tripDate;
  final String tripTime;
  final int totalSeats;
  final int joinedMembers;
  final double totalCost;
  final double perSeatCost;
  final String tripStatus;
  final bool hasSafetyFlag;
  final String safetyNote;

  const SharingCaringHistoryModel({
    required this.tripId,
    required this.creatorName,
    required this.creatorType,
    required this.creatorPhone,
    required this.creatorPhotoUrl,
    required this.vehicleType,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.tripDate,
    required this.tripTime,
    required this.totalSeats,
    required this.joinedMembers,
    required this.totalCost,
    required this.perSeatCost,
    required this.tripStatus,
    required this.hasSafetyFlag,
    required this.safetyNote,
  });

  factory SharingCaringHistoryModel.fromJson(Map<String, dynamic> json) {
    return SharingCaringHistoryModel(
      tripId: (json['trip_id'] ?? '').toString(),
      creatorName: (json['creator_name'] ?? '').toString(),
      creatorType: (json['creator_type'] ?? '').toString(),
      creatorPhone: (json['creator_phone'] ?? '').toString(),
      creatorPhotoUrl: (json['creator_photo_url'] ?? '').toString(),
      vehicleType: (json['vehicle_type'] ?? '').toString(),
      pickupLocation: (json['pickup_location'] ?? '').toString(),
      destinationLocation: (json['destination_location'] ?? '').toString(),
      tripDate: (json['trip_date'] ?? '').toString(),
      tripTime: (json['trip_time'] ?? '').toString(),
      totalSeats: _toInt(json['total_seats']),
      joinedMembers: _toInt(json['joined_members']),
      totalCost: _toDouble(json['total_cost']),
      perSeatCost: _toDouble(json['per_seat_cost']),
      tripStatus: (json['trip_status'] ?? '').toString(),
      hasSafetyFlag: _toBool(json['has_safety_flag']),
      safetyNote: (json['safety_note'] ?? '').toString(),
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

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    final text = value.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  String get totalCostDisplay => '৳${totalCost.toStringAsFixed(0)}';

  String get perSeatCostDisplay => '৳${perSeatCost.toStringAsFixed(0)}';
}

class SharingCaringHistoryService {
  final AuthApiService _authApiService = AuthApiService();

  Future<List<SharingCaringHistoryModel>> fetchSharingCaringHistory({
    String search = '',
    String status = 'all',
    String safety = 'all',
  }) async {
    final response = await _authApiService.getAdminSharingCaringHistory(
      search: search,
      status: status,
      safety: safety,
    );

    final data = Map<String, dynamic>.from(response['data'] ?? {});
    final items = List<Map<String, dynamic>>.from(data['items'] ?? const []);

    return items
        .map((e) => SharingCaringHistoryModel.fromJson(e))
        .toList();
  }
}