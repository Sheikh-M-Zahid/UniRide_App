import 'package:flutter/material.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  final TextEditingController searchController = TextEditingController();

  String selectedRange = "Today";
  DateTime selectedMonth = DateTime.now();

  /// Later এই list database থেকে আসবে
  final List<Map<String, dynamic>> allRides = [
    {
      "pickupDate": DateTime.now(),
      "passengerName": "Rahim",
      "phoneNumber": "01712345678",
      "pickupLocation": "Hall Gate",
      "destination": "Main Gate",
      "distance": 2.5,
      "earning": 80.0,
    },
    {
      "pickupDate": DateTime.now().subtract(const Duration(days: 1)),
      "passengerName": "Karim",
      "phoneNumber": "01899887766",
      "pickupLocation": "Library",
      "destination": "CSE Building",
      "distance": 3.2,
      "earning": 100.0,
    },
    {
      "pickupDate": DateTime.now().subtract(const Duration(days: 3)),
      "passengerName": "Nusrat",
      "phoneNumber": "01911112222",
      "pickupLocation": "Dormitory",
      "destination": "Business Faculty",
      "distance": 4.1,
      "earning": 120.0,
    },
    {
      "pickupDate": DateTime.now().subtract(const Duration(days: 15)),
      "passengerName": "Sadia",
      "phoneNumber": "01655554444",
      "pickupLocation": "Admin Building",
      "destination": "University Gate",
      "distance": 1.8,
      "earning": 60.0,
    },
    {
      "pickupDate": DateTime.now().subtract(const Duration(days: 25)),
      "passengerName": "Tamim",
      "phoneNumber": "01577778888",
      "pickupLocation": "Central Mosque",
      "destination": "Hall Gate",
      "distance": 2.9,
      "earning": 90.0,
    },
  ];

  List<Map<String, dynamic>> get filteredRides {
    List<Map<String, dynamic>> rides = List.from(allRides);
    final String query = searchController.text.trim().toLowerCase();

    /// Search by passenger name or phone number
    if (query.isNotEmpty) {
      rides = rides.where((ride) {
        final String name =
        ride["passengerName"].toString().toLowerCase();
        final String phone =
        ride["phoneNumber"].toString().toLowerCase();

        return name.contains(query) || phone.contains(query);
      }).toList();
    }

    final now = DateTime.now();

    if (selectedRange == "Today") {
      rides = rides.where((ride) {
        final DateTime date = ride["pickupDate"];
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();
    } else if (selectedRange == "This Week") {
      final DateTime startOfWeek =
      now.subtract(Duration(days: now.weekday - 1));
      final DateTime weekStart =
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final DateTime weekEnd = weekStart.add(const Duration(days: 7));

      rides = rides.where((ride) {
        final DateTime date = ride["pickupDate"];
        return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            date.isBefore(weekEnd);
      }).toList();
    } else if (selectedRange == "This Month") {
      rides = rides.where((ride) {
        final DateTime date = ride["pickupDate"];
        return date.year == selectedMonth.year &&
            date.month == selectedMonth.month;
      }).toList();
    }

    rides.sort((a, b) =>
        (b["pickupDate"] as DateTime).compareTo(a["pickupDate"] as DateTime));

    return rides;
  }

  String getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  bool get canGoNextMonth {
    final now = DateTime.now();
    return selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);
  }

  void goToPreviousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    });
  }

  void goToNextMonth() {
    if (!canGoNextMonth) return;

    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rides = filteredRides;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Ride History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          /// Top Filter Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
            ),
            child: Column(
              children: [
                /// Search
                TextField(
                  controller: searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: "Search by name or phone number",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: Color(0xFF14B8A6), width: 1.3),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// Filter Range
                Row(
                  children: [
                    Expanded(
                      child: _filterButton("Today"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _filterButton("This Week"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _filterButton("This Month"),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                /// Month Navigator
                if (selectedRange == "This Month")
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: goToPreviousMonth,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text("Prev Month"),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "${getMonthName(selectedMonth.month)} ${selectedMonth.year}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: canGoNextMonth ? goToNextMonth : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text("Next Month"),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            disabledForegroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          /// Ride History List
          Expanded(
            child: rides.isEmpty
                ? const Center(
              child: Text(
                "No ride history found",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: rides.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final ride = rides[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
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
                      /// Top row
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDate(ride["pickupDate"]),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "৳${(ride["earning"] as double).toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Color(0xFF0F766E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _historyRow(
                        "Passenger Name",
                        ride["passengerName"],
                      ),
                      _historyRow(
                        "Phone Number",
                        ride["phoneNumber"],
                      ),
                      _historyRow(
                        "Pick Up Location",
                        ride["pickupLocation"],
                      ),
                      _historyRow(
                        "Destination",
                        ride["destination"],
                      ),
                      _historyRow(
                        "Distance",
                        "${ride["distance"]} km",
                      ),
                      _historyRow(
                        "Earning",
                        "৳${(ride["earning"] as double).toStringAsFixed(0)}",
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

  Widget _filterButton(String title) {
    final bool isSelected = selectedRange == title;

    return InkWell(
      onTap: () {
        setState(() {
          selectedRange = title;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
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

  Widget _historyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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