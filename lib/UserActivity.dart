import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'UserOffer.dart';
import 'UserHome.dart';
import 'UserProfile.dart';
import 'UserServices.dart';
import 'CoRideChatRoom.dart';
import 'CoRideModels.dart';
import 'PassengerLiveMapPage.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final AuthApiService _authApiService = AuthApiService();
  String _selectedType = 'all';
  String _selectedTime = 'today';
  bool isLoading = true;
  String? emptyState;

  Map<String, dynamic> summary = {
    'total': 0,
    'completed': 0,
    'cancelled': 0,
    'earnings': 0,
  };

  List<Map<String, dynamic>> activities = [];

  // ✅ 'coride' যোগ করা হয়েছে
  final List<String> _typeOptions = [
    'all',
    'completed',
    'cancelled',
    'reserved',
    'send_item',
    'coride',
  ];
  final List<String> _timeOptions = ['today', 'this_week', 'this_month'];

  @override
  void initState() {
    super.initState();
    _loadActivityDashboard();
  }

  Future<void> _loadActivityDashboard() async {
    setState(() => isLoading = true);
    try {
      final response = await _authApiService.getActivityDashboard(
        type: _selectedType,
        time: _selectedTime,
      );
      final data = response['data'] ?? {};
      if (!mounted) return;

      setState(() {
        summary = Map<String, dynamic>.from(data['summary'] ?? {});
        activities =
        List<Map<String, dynamic>>.from(data['activities'] ?? []);
        emptyState = data['emptyState'];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _formatTypeLabel(String value) {
    return value
        .split('_')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  String _formatMoney(dynamic value) {
    final num amount =
    (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    return '৳${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.secondary;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      case 'active':
        return AppColors.primary;
      default:
        return AppColors.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Activity",
          style: TextStyle(
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary),
            )
                : activities.isEmpty
                ? Center(
              child: Text(
                emptyState ?? "No activity found",
                style: const TextStyle(
                    color: AppColors.mutedText),
              ),
            )
                : ListView.separated(
              padding:
              const EdgeInsets.symmetric(horizontal: 20),
              itemCount: activities.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildActivityCard(activities[index]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Text(
            "Filter",
            style:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Spacer(),
          _dropDownFilter(_selectedType, _typeOptions, (val) {
            setState(() => _selectedType = val!);
            _loadActivityDashboard();
          }),
          const SizedBox(width: 8),
          _dropDownFilter(_selectedTime, _timeOptions, (val) {
            setState(() => _selectedTime = val!);
            _loadActivityDashboard();
          }),
        ],
      ),
    );
  }

  Widget _dropDownFilter(String value, List<String> options,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: options
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(
              _formatTypeLabel(e),
              style: const TextStyle(fontSize: 12),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _summaryBox(
                      "Total", summary['total'].toString())),
              const SizedBox(width: 10),
              Expanded(
                  child: _summaryBox(
                      "Done", summary['completed'].toString())),
              const SizedBox(width: 10),
              Expanded(
                  child: _summaryBox(
                      "Cancel", summary['cancelled'].toString())),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              "Total Spent: ${_formatMoney(summary['earnings'])}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.mutedText)),
          Text(val,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> item) {
    final type = item['item_type']?.toString() ?? 'ride';
    final status = item['status']?.toString() ?? 'Pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['title'] ?? 'Activity',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const Divider(height: 20),

          // ─────────────────────────────────────
          // SEND ITEM
          // ─────────────────────────────────────
          if (type == 'send_item') ...[
            _infoRow("Sender", item['sender_name'] ?? 'Me'),
            _infoRow("Receiver", item['receiver_email'] ?? 'N/A'),
            _infoRow("Item", item['item_type_label'] ?? 'Parcel'),
            _infoRow("Pickup", item['pickup'] ?? 'N/A'),
            _infoRow("Destination", item['destination'] ?? 'N/A'),

            // ─────────────────────────────────────
            // RESERVE
            // ─────────────────────────────────────
          ] else if (type == 'reserve') ...[
            _infoRow("Route",
                "${item['pickup']} → ${item['destination']}"),
            _infoRow("Distance", "${item['totalDistanceKm']} km"),
            _infoRow("Est. Time",
                "${item['estimatedTravelMinutes']} min"),
            _infoRow(
                "Schedule", "${item['date']} at ${item['time']}"),
            _infoRow(
                "Rider", item['riderName'] ?? "Waiting for rider"),
            if (item['riderPhone'] != null)
              _infoRow("Phone", item['riderPhone']),

            // ─────────────────────────────────────
            // CORIDE — PARTICIPANT
            // ─────────────────────────────────────
          ] else if (type == 'coride') ...[
            _infoRow(
              "Route",
              "${item['pickup'] ?? 'N/A'} → ${item['destination'] ?? 'N/A'}",
            ),
            _infoRow("Creator", item['creator_name'] ?? 'N/A'),
            _infoRow("Fare", _formatMoney(item['fare'])),
            _infoRow("Date", item['date'] ?? ''),
            _infoRow(
              "Seats",
              "${item['booked_seats'] ?? 0}/${item['total_seats'] ?? 0} booked",
            ),

            // Journey started indicator
            if (item['is_started'] == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Journey Started',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // See Message button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final sessionId =
                      item['session_id']?.toString() ?? '';
                  if (sessionId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoRideChatRoomPage(
                        post: CoRidePost(
                          id: sessionId,
                          sessionId: sessionId,
                          creatorId: '',
                          creatorName: item['creator_name'] ?? '',
                          creatorPhoto: '',
                          pickup: item['pickup'] ?? '',
                          destination: item['destination'] ?? '',
                          vehicleType: '',
                          vehicleNumber: '',
                          preferredGender: '',
                          dateText: item['date'] ?? '',
                          timeText: '',
                          totalSeats: item['total_seats'] ?? 2,
                          confirmedSeats: item['booked_seats'] ?? 0,
                          farePerPerson: double.tryParse(
                              item['fare']?.toString() ?? '0') ??
                              0,
                          note: '',
                          confirmedMembers: const [],
                        ),
                        currentUserId: '',
                        currentUserName: '',
                      ),
                    ),
                  );
                },
                icon:
                const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('See Message'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // ✅ Live Map button — See Message এর ঠিক নিচে
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final sessionId =
                      item['session_id']?.toString() ?? '';
                  if (sessionId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PassengerLiveMapPage(
                        sessionId: sessionId,
                        hostName: item['creator_name'] ?? 'Host',
                        destination: item['destination'] ?? '',
                        isCoRide: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Live Map'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0F766E)),
                  foregroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // ─────────────────────────────────────
            // CORIDE — CREATOR (MY POST)
            // ─────────────────────────────────────
          ] else if (type == 'coride_creator') ...[
            _infoRow(
              "Route",
              "${item['pickup'] ?? 'N/A'} → ${item['destination'] ?? 'N/A'}",
            ),
            _infoRow("Fare/Person", _formatMoney(item['fare'])),
            _infoRow("Date", item['date'] ?? ''),
            _infoRow(
              "Seats",
              "${item['booked_seats'] ?? 0}/${item['total_seats'] ?? 0} booked",
            ),

            // Journey started indicator
            if (item['is_started'] == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Journey Started',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // See Message button (creator এর জন্য)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final sessionId =
                      item['session_id']?.toString() ?? '';
                  if (sessionId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoRideChatRoomPage(
                        post: CoRidePost(
                          id: sessionId,
                          sessionId: sessionId,
                          creatorId: '',
                          creatorName: '',
                          creatorPhoto: '',
                          pickup: item['pickup'] ?? '',
                          destination: item['destination'] ?? '',
                          vehicleType: '',
                          vehicleNumber: '',
                          preferredGender: '',
                          dateText: item['date'] ?? '',
                          timeText: '',
                          totalSeats: item['total_seats'] ?? 2,
                          confirmedSeats: item['booked_seats'] ?? 0,
                          farePerPerson: double.tryParse(
                              item['fare']?.toString() ?? '0') ??
                              0,
                          note: '',
                          confirmedMembers: const [],
                        ),
                        currentUserId: '',
                        currentUserName: '',
                      ),
                    ),
                  );
                },
                icon:
                const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('See Message'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // creator এর জন্য Live Map নেই
            // (creator নিজেই SharingCaringPage থেকে map open করে)

            // ─────────────────────────────────────
            // DEFAULT RIDE
            // ─────────────────────────────────────
          ] else ...[
            _infoRow("Route",
                "${item['pickup']} → ${item['destination']}"),
            _infoRow("Driver", item['name'] ?? 'N/A'),
            _infoRow("Time", "${item['time']} min"),
          ],

          // Fare & Date — CoRide ছাড়া সব type এর জন্য
          if (type != 'coride' && type != 'coride_creator') ...[
            _infoRow("Fare", _formatMoney(item['fare'])),
            _infoRow("Date", item['date'] ?? ''),
          ],

          // Cancel button — reserve pending only
          if (type == 'reserve' &&
              status.toLowerCase() == 'pending') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    _handleCancel(item['id'].toString()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Cancel Request",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel(String id) async {
    try {
      await _authApiService.cancelReserve(reserveId: id);
      _loadActivityDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Request cancelled successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.mutedText,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const UniRideHomePage()));
        }
        if (index == 1) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const ServicesPage()));
        }
        if (index == 3) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const OffersPage()));
        }
        if (index == 4) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const UniRideProfilePage()));
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.grid_view), label: "Services"),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long), label: "Activity"),
        BottomNavigationBarItem(
            icon: Icon(Icons.local_offer), label: "Offers"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: "Account"),
      ],
    );
  }
}