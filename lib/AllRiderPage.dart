import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AllRiderPage extends StatefulWidget {
  const AllRiderPage({super.key});

  @override
  State<AllRiderPage> createState() => _AllRiderPageState();
}

class _AllRiderPageState extends State<AllRiderPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = "All";
  bool isLoading = true;
  bool isUpdatingStatus = false;
  String? errorMessage;

  List<RiderModel> allRiders = [];

  // এখানে তোমার backend URL দাও
  // Android emulator হলে: http://10.0.2.2:5000
  // Localhost web হলে: http://localhost:5000
  // Real device হলে: তোমার PC/Laptop এর local IP দিতে হবে
  static const String baseUrl = "http://10.0.2.2:5000/api";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();
    fetchRiders();
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchRiders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/riders"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List dataList = [];

        if (decoded is List) {
          dataList = decoded;
        } else if (decoded is Map<String, dynamic> && decoded["data"] is List) {
          dataList = decoded["data"] as List;
        } else {
          throw Exception("Invalid API response format");
        }

        final riders =
        dataList.map((e) => RiderModel.fromJson(e)).toList();

        if (!mounted) return;
        setState(() {
          allRiders = riders;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load riders (${response.statusCode})");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> toggleStatus(RiderModel rider) async {
    if (isUpdatingStatus) return;

    setState(() {
      isUpdatingStatus = true;
    });

    try {
      final String newStatus =
      rider.status.toLowerCase() == "suspended" ? "Active" : "Suspended";

      final response = await http.patch(
        Uri.parse("$baseUrl/riders/${rider.id}/status"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "status": newStatus,
        }),
      );

      if (response.statusCode == 200) {
        final index = allRiders.indexWhere((item) => item.id == rider.id);

        if (index != -1) {
          final updatedRider = allRiders[index].copyWith(status: newStatus);

          setState(() {
            allRiders[index] = updatedRider;
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == "Active"
                  ? "Rider activated successfully"
                  : "Rider suspended successfully",
            ),
          ),
        );
      } else {
        String message = "Failed to update status";
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded["message"] != null) {
            message = decoded["message"].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status update failed: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isUpdatingStatus = false;
      });
    }
  }

  bool isRecentlyJoined(DateTime? joinedAt) {
    if (joinedAt == null) return false;
    final now = DateTime.now();
    return now.difference(joinedAt).inDays <= 7;
  }

  List<RiderModel> get filteredRiders {
    final query = searchController.text.trim().toLowerCase();

    return allRiders.where((rider) {
      final bool searchMatch = query.isEmpty ||
          rider.name.toLowerCase().contains(query) ||
          rider.location.toLowerCase().contains(query) ||
          rider.phone.toLowerCase().contains(query);

      bool filterMatch = true;

      if (selectedFilter == "Due Payment") {
        filterMatch = rider.due > 0;
      } else if (selectedFilter == "Active") {
        filterMatch = rider.status.toLowerCase() == "active";
      } else if (selectedFilter == "Suspended") {
        filterMatch = rider.status.toLowerCase() == "suspended";
      } else if (selectedFilter == "Recently Joined") {
        filterMatch = isRecentlyJoined(rider.joinedAt);
      }

      return searchMatch && filterMatch;
    }).toList();
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green;
      case "suspended":
        return Colors.red;
      case "inactive":
        return Colors.orange;
      case "pending":
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "N/A";
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final riders = filteredRiders;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF0F766E),
              Color(0xFF14B8A6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            "All Riders",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: fetchRiders,
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search by name, phone or location...",
                        hintStyle: const TextStyle(color: Colors.white60),
                        prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                          const BorderSide(color: Colors.cyanAccent),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: selectedFilter,
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Filter",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                          const BorderSide(color: Colors.cyanAccent),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        "All",
                        "Due Payment",
                        "Active",
                        "Suspended",
                        "Recently Joined",
                      ].map((e) {
                        return DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedFilter = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }

                          if (errorMessage != null) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 42,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Failed to load riders",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    ElevatedButton(
                                      onPressed: fetchRiders,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF14B8A6),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text("Retry"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (allRiders.isEmpty) {
                            return const Center(
                              child: Text(
                                "No riders found",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          if (riders.isEmpty) {
                            return const Center(
                              child: Text(
                                "No matching riders found",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: fetchRiders,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: riders.length,
                              itemBuilder: (context, index) {
                                final rider = riders[index];
                                final bool isSuspended =
                                    rider.status.toLowerCase() == "suspended";

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                            const Color(0xFF14B8A6),
                                            child: Text(
                                              rider.name.isNotEmpty
                                                  ? rider.name[0]
                                                  .toUpperCase()
                                                  : "R",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rider.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Joined: ${formatDate(rider.joinedAt)}",
                                                  style: const TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor(rider.status),
                                              borderRadius:
                                              BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              rider.status,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      _infoRow(
                                        icon: Icons.phone,
                                        label: "Phone",
                                        value: rider.phone,
                                      ),
                                      const SizedBox(height: 8),
                                      _infoRow(
                                        icon: Icons.location_on_outlined,
                                        label: "Location",
                                        value: rider.location,
                                      ),
                                      const SizedBox(height: 8),
                                      _infoRow(
                                        icon: Icons.account_balance_wallet_outlined,
                                        label: "Due",
                                        value:
                                        "${rider.due.toStringAsFixed(0)} BDT",
                                      ),

                                      const SizedBox(height: 14),

                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: isUpdatingStatus
                                              ? null
                                              : () => toggleStatus(rider),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSuspended
                                                ? Colors.green
                                                : Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            isSuspended
                                                ? "Activate"
                                                : "Suspend",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class RiderModel {
  final int id;
  final String name;
  final String phone;
  final String location;
  final String status;
  final double due;
  final DateTime? joinedAt;

  RiderModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.status,
    required this.due,
    required this.joinedAt,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: _parseInt(json["id"]),
      name: (json["name"] ?? "").toString(),
      phone: (json["phone"] ?? "").toString(),
      location: (json["location"] ?? "").toString(),
      status: (json["status"] ?? "Inactive").toString(),
      due: _parseDouble(json["due"]),
      joinedAt: _parseDate(json["joined_at"] ?? json["joinedAt"]),
    );
  }

  RiderModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? location,
    String? status,
    double? due,
    DateTime? joinedAt,
  }) {
    return RiderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      status: status ?? this.status,
      due: due ?? this.due,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}