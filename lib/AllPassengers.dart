import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AllPassengersPage extends StatefulWidget {
  const AllPassengersPage({super.key});

  @override
  State<AllPassengersPage> createState() => _AllPassengersPageState();
}

class _AllPassengersPageState extends State<AllPassengersPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = "All";
  bool isLoading = true;
  String? errorMessage;

  List<PassengerModel> allPassengers = [];

  // এখানে তোমার backend URL বসাবে
  // Android Emulator -> http://10.0.2.2:5000
  // Flutter Web -> http://localhost:5000
  // Real Device -> তোমার PC এর local IP
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
    fetchPassengers();
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPassengers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/passengers"),
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

        final passengers =
        dataList.map((e) => PassengerModel.fromJson(e)).toList();

        if (!mounted) return;
        setState(() {
          allPassengers = passengers;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load passengers (${response.statusCode})");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  List<PassengerModel> get filteredPassengers {
    final query = searchController.text.trim().toLowerCase();

    return allPassengers.where((passenger) {
      final bool searchMatch =
          query.isEmpty || passenger.name.toLowerCase().contains(query);

      bool filterMatch = true;

      if (selectedFilter == "Student") {
        filterMatch = passenger.userType.toLowerCase() == "student";
      } else if (selectedFilter == "Faculty") {
        filterMatch = passenger.userType.toLowerCase() == "faculty";
      } else if (selectedFilter == "Staff") {
        filterMatch = passenger.userType.toLowerCase() == "staff";
      }

      return searchMatch && filterMatch;
    }).toList();
  }

  Color userTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case "student":
        return Colors.lightBlueAccent;
      case "faculty":
        return Colors.deepPurpleAccent;
      case "staff":
        return Colors.orangeAccent;
      default:
        return Colors.blueGrey;
    }
  }

  Color riderBadgeColor(bool isRider) {
    return isRider ? Colors.greenAccent : Colors.white70;
  }

  String riderBadgeText(bool isRider) {
    return isRider ? "Rider" : "Non-Rider";
  }

  String formatDate(DateTime? date) {
    if (date == null) return "N/A";
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final passengers = filteredPassengers;

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
                            "All Passengers",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: fetchPassengers,
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
                        hintText: "Search by passenger name...",
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
                        labelText: "Filter by user type",
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
                        "Student",
                        "Faculty",
                        "Staff",
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
                                      "Failed to load passengers",
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
                                      onPressed: fetchPassengers,
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

                          if (allPassengers.isEmpty) {
                            return const Center(
                              child: Text(
                                "No passengers found",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          if (passengers.isEmpty) {
                            return const Center(
                              child: Text(
                                "No matching passengers found",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: fetchPassengers,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: passengers.length,
                              itemBuilder: (context, index) {
                                final passenger = passengers[index];

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
                                              passenger.name.isNotEmpty
                                                  ? passenger.name[0]
                                                  .toUpperCase()
                                                  : "P",
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
                                                  passenger.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Joined: ${formatDate(passenger.joinedAt)}",
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
                                              color:
                                              userTypeColor(passenger.userType),
                                              borderRadius:
                                              BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              passenger.userType,
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
                                        value: passenger.phone,
                                      ),
                                      const SizedBox(height: 8),
                                      _infoRow(
                                        icon: Icons.email_outlined,
                                        label: "Email",
                                        value: passenger.email,
                                      ),
                                      const SizedBox(height: 8),
                                      _infoRow(
                                        icon: Icons.location_on_outlined,
                                        label: "Location",
                                        value: passenger.location,
                                      ),

                                      const SizedBox(height: 12),

                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: riderBadgeColor(
                                                passenger.isRider,
                                              ),
                                              borderRadius:
                                              BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              riderBadgeText(passenger.isRider),
                                              style: TextStyle(
                                                color: passenger.isRider
                                                    ? Colors.black
                                                    : Colors.black87,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              passenger.isRider
                                                  ? "This passenger is also registered as a rider."
                                                  : "This passenger is currently using the app as a non-rider user.",
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                        ],
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class PassengerModel {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String location;
  final String userType;
  final bool isRider;
  final DateTime? joinedAt;

  PassengerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.location,
    required this.userType,
    required this.isRider,
    required this.joinedAt,
  });

  factory PassengerModel.fromJson(Map<String, dynamic> json) {
    return PassengerModel(
      id: _parseInt(json["id"]),
      name: (json["name"] ?? "").toString(),
      phone: (json["phone"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
      location: (json["location"] ?? "").toString(),
      userType: (json["user_type"] ?? json["userType"] ?? "Student").toString(),
      isRider: _parseBool(json["is_rider"] ?? json["isRider"]),
      joinedAt: _parseDate(json["joined_at"] ?? json["joinedAt"]),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == "true" || lower == "1" || lower == "yes";
    }
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}