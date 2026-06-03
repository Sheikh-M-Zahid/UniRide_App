import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'services/activity_socket_service.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final AuthApiService _api = AuthApiService();

  String selectedType = "All";
  String selectedTime = "Today";

  bool _isLoading = true;
  bool _isLoadingMore = false;

  int _page = 1;
  final int _limit = 20;
  int _totalPages = 1;

  int totalCount = 0;
  int completedCount = 0;
  int cancelledCount = 0;
  double totalEarnings = 0;

  List<Map<String, dynamic>> allActivities = [];

  List<Map<String, dynamic>> get filteredActivities => allActivities;

  String _mapTypeToApi(String value) {
    switch (value) {
      case "Completed":
        return "completed";
      case "Cancelled":
        return "cancelled";
      case "Reserved":
        return "reserved";
      case "Send Item":
        return "send_item";
      default:
        return "all";
    }
  }

  String _mapTimeToApi(String value) {
    switch (value) {
      case "This Week":
        return "this_week";
      case "This Month":
        return "this_month";
      default:
        return "today";
    }
  }

  String _mapApiTypeToUi(String value) {
    switch (value) {
      case "completed":
        return "Completed";
      case "cancelled":
        return "Cancelled";
      case "reserved":
        return "Reserved";
      case "send_item":
        return "Send Item";
      default:
        return "Activity";
    }
  }

  Future<void> _loadActivity({bool reset = false}) async {
    try {
      if (reset) {
        _page = 1;
        setState(() {
          _isLoading = true;
        });
      } else {
        setState(() {
          _isLoadingMore = true;
        });
      }

      final response = await _api.getActivityDashboard(
        type: _mapTypeToApi(selectedType),
        time: _mapTimeToApi(selectedTime),
        page: _page,
        limit: _limit,
      );

      final data = response['data'] ?? response;
      final summary = data['summary'] ?? {};
      final filters = data['filters'] ?? {};
      final activitiesRaw = data['activities'] as List? ?? [];

      final mappedActivities = activitiesRaw.map<Map<String, dynamic>>((item) {
        final map = Map<String, dynamic>.from(item as Map);
        map['uiType'] = _mapApiTypeToUi((map['type'] ?? '').toString());
        return map;
      }).toList();

      setState(() {
        totalCount = (summary['total'] ?? 0) as int;
        completedCount = (summary['completed'] ?? 0) as int;
        cancelledCount = (summary['cancelled'] ?? 0) as int;
        totalEarnings = ((summary['earnings'] ?? 0) as num).toDouble();
        _totalPages = (filters['totalPages'] ?? 1) as int;

        if (reset) {
          allActivities = mappedActivities;
        } else {
          allActivities.addAll(mappedActivities);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    if (_page >= _totalPages) return;

    _page++;
    await _loadActivity();
  }

  Future<void> _connectSocket() async {
    await ActivitySocketService.instance.connect();
    ActivitySocketService.instance.joinActivityRoom();
    ActivitySocketService.instance.onActivityUpdated((_) {
      _loadActivity(reset: true);
    });
  }

  Color _statusColor(String type) {
    switch (type) {
      case "Completed":
        return const Color(0xFF0F766E);
      case "Cancelled":
        return Colors.red;
      case "Reserved":
        return Colors.orange;
      case "Send Item":
        return Colors.blue;
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadActivity(reset: true);
    _connectSocket();
  }

  IconData _statusIcon(String type) {
    switch (type) {
      case "Completed":
        return Icons.check_circle;
      case "Cancelled":
        return Icons.cancel;
      case "Reserved":
        return Icons.schedule;
      case "Send Item":
        return Icons.local_shipping;
      default:
        return Icons.info;
    }
  }

  @override
  void dispose() {
    ActivitySocketService.instance.leaveActivityRoom();
    ActivitySocketService.instance.offActivityUpdated();
    ActivitySocketService.instance.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activities = filteredActivities;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Activity",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// Summary cards - full width, auto size
                Row(
                  children: [
                    Expanded(child: _SummaryCard(title: "Total", value: totalCount.toString(), icon: Icons.list_alt)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(title: "Completed", value: completedCount.toString(), icon: Icons.check_circle_outline)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(title: "Cancelled", value: cancelledCount.toString(), icon: Icons.cancel_outlined)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(title: "Earnings", value: "৳${totalEarnings.toStringAsFixed(0)}", icon: Icons.account_balance_wallet_outlined)),
                  ],
                ),

                const SizedBox(height: 16),

                /// Type filter - full width
                Row(
                  children: [
                    Expanded(child: _filterChip("All")),
                    Expanded(child: _filterChip("Completed")),
                    Expanded(child: _filterChip("Cancelled")),
                    Expanded(child: _filterChip("Reserved")),
                    Expanded(child: _filterChip("Send Item")),
                    const SizedBox(width: 8),
                    _filterButton(),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          Expanded(
            child: activities.isEmpty
                ? const Center(
              child: Text(
                "No activity found",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = activities[index];
                final statusColor = _statusColor(item["type"]);

                return Container(
                  padding: const EdgeInsets.all(16),
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
                      /// header
                      Row(
                        children: [
                          Icon(
                            _statusIcon(item["type"]),
                            color: statusColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item["title"],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item["type"],
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _activityRow("Passenger", item["name"]),
                      _activityRow("Phone", item["phone"]),
                      _activityRow("Pickup", item["pickup"]),
                      _activityRow("Destination", item["destination"]),
                      _activityRow("Time", item["time"]),
                      _activityRow(
                        "Fare",
                        "৳${(item["fare"] as double).toStringAsFixed(0)}",
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String title) {
    final bool isSelected = selectedType == title;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () async {
          setState(() {
            selectedType = title;
          });
          await _loadActivity(reset: true);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF14B8A6) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF14B8A6)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeButton(String title) {
    final bool isSelected = selectedTime == title;

    return InkWell(
      onTap: () async {
        setState(() {
          selectedTime = title;
        });
        await _loadActivity(reset: true);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF14B8A6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF14B8A6)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterButton() {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        setState(() {
          selectedTime = value;
        });
        await _loadActivity(reset: true);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 44),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF374151)),
            const SizedBox(width: 6),
            Text(
              selectedTime,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _popupItem("Today"),
        _popupItem("This Week"),
        _popupItem("This Month"),
      ],
    );
  }

  PopupMenuItem<String> _popupItem(String value) {
    final bool isSelected = selectedTime == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (isSelected)
            const Icon(Icons.check, size: 16, color: Color(0xFF14B8A6))
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF14B8A6)
                  : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}