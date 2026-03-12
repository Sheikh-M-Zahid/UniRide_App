import 'package:flutter/material.dart';
import 'RideRequestModel.dart';
import 'RideRequestService.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  String selectedType = "All";
  String selectedTime = "Today";

  /// Later database থেকে আসবে
  final List<Map<String, dynamic>> allActivities = [
    {
      "type": "Completed",
      "title": "Ride Completed",
      "name": "Rahim",
      "phone": "01712345678",
      "pickup": "Hall Gate",
      "destination": "Main Gate",
      "fare": 80.0,
      "time": "10:15 AM",
      "date": DateTime.now(),
    },
    {
      "type": "Cancelled",
      "title": "Ride Cancelled",
      "name": "Karim",
      "phone": "01899887766",
      "pickup": "Library",
      "destination": "CSE Building",
      "fare": 0.0,
      "time": "11:10 AM",
      "date": DateTime.now(),
    },
    {
      "type": "Reserved",
      "title": "Reserved Ride",
      "name": "Nusrat",
      "phone": "01911112222",
      "pickup": "Dormitory",
      "destination": "Business Faculty",
      "fare": 120.0,
      "time": "Tomorrow 8:30 AM",
      "date": DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      "type": "Send Item",
      "title": "Parcel Delivered",
      "name": "Sadia",
      "phone": "01655554444",
      "pickup": "Admin Building",
      "destination": "University Gate",
      "fare": 60.0,
      "time": "02:20 PM",
      "date": DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      "type": "Completed",
      "title": "Ride Completed",
      "name": "Tamim",
      "phone": "01577778888",
      "pickup": "Central Mosque",
      "destination": "Hall Gate",
      "fare": 90.0,
      "time": "04:10 PM",
      "date": DateTime.now().subtract(const Duration(days: 6)),
    },
  ];

  List<Map<String, dynamic>> get filteredActivities {
    List<Map<String, dynamic>> data = List.from(allActivities);

    if (selectedType != "All") {
      data = data.where((item) => item["type"] == selectedType).toList();
    }

    final now = DateTime.now();

    if (selectedTime == "Today") {
      data = data.where((item) {
        final DateTime date = item["date"];
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();
    } else if (selectedTime == "This Week") {
      final DateTime startOfWeek =
      now.subtract(Duration(days: now.weekday - 1));
      final DateTime weekStart =
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final DateTime weekEnd = weekStart.add(const Duration(days: 7));

      data = data.where((item) {
        final DateTime date = item["date"];
        return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            date.isBefore(weekEnd);
      }).toList();
    } else if (selectedTime == "This Month") {
      data = data.where((item) {
        final DateTime date = item["date"];
        return date.year == now.year && date.month == now.month;
      }).toList();
    }

    data.sort(
          (a, b) => (b["date"] as DateTime).compareTo(a["date"] as DateTime),
    );

    return data;
  }

  int get totalRidesToday {
    return allActivities.where((item) {
      final DateTime date = item["date"];
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int get completedToday {
    return allActivities.where((item) {
      final DateTime date = item["date"];
      final now = DateTime.now();
      return item["type"] == "Completed" &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int get cancelledToday {
    return allActivities.where((item) {
      final DateTime date = item["date"];
      final now = DateTime.now();
      return item["type"] == "Cancelled" &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  double get todayEarnings {
    return allActivities.where((item) {
      final DateTime date = item["date"];
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).fold(
      0.0,
          (sum, item) => sum + ((item["fare"] as num).toDouble()),
    );
  }

  void _simulateRideRequest() {
    RideRequestService.addRequest(
      const RideRequestModel(
        passengerName: "Jubayer",
        phoneNumber: "01611224455",
        currentLocation: "Central Mosque",
        destination: "Science Building",
        distanceKm: 3.9,
        fare: 95,
        estimatedMinutes: 13,
      ),
    );
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
                /// Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: "Total",
                        value: totalRidesToday.toString(),
                        icon: Icons.list_alt,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: "Completed",
                        value: completedToday.toString(),
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: "Cancelled",
                        value: cancelledToday.toString(),
                        icon: Icons.cancel_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: "Earnings",
                        value: "৳${todayEarnings.toStringAsFixed(0)}",
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Type filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip("All"),
                      _filterChip("Completed"),
                      _filterChip("Cancelled"),
                      _filterChip("Reserved"),
                      _filterChip("Send Item"),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                /// Time filter
                Row(
                  children: [
                    Expanded(child: _timeButton("Today")),
                    const SizedBox(width: 10),
                    Expanded(child: _timeButton("This Week")),
                    const SizedBox(width: 10),
                    Expanded(child: _timeButton("This Month")),
                  ],
                ),

                const SizedBox(height: 16),

                /// Optional demo button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _simulateRideRequest,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text("Simulate Ride Request"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
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
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedType = title;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeButton(String title) {
    final bool isSelected = selectedTime == title;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTime = title;
        });
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
      height: 92,
      padding: const EdgeInsets.all(14),
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
        children: [
          Icon(icon, size: 26, color: const Color(0xFF0F766E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
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