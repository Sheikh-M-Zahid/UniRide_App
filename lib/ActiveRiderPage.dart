import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class ActiveRiderPage extends StatefulWidget {
  const ActiveRiderPage({super.key});

  @override
  State<ActiveRiderPage> createState() => _ActiveRiderPageState();
}

class _ActiveRiderPageState extends State<ActiveRiderPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  TextEditingController searchController = TextEditingController();
  String selectedFilter = "All Active";
  bool isLoading = true;
  final AuthApiService _authApiService = AuthApiService();
  Map<String, dynamic>? statsData;
  List<Map<String, dynamic>> allActiveRiders = [];

  List<Map<String, dynamic>> activeRiders = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();

    _loadActiveRiders();
  }

  Future<void> _loadActiveRiders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _authApiService.getActiveRiders(
        search: searchController.text.trim(),
        filter: _mapFilter(selectedFilter),
        location: '',
        page: 1,
        limit: 20,
      );

      final data = response['data'] ?? response;

      if (!mounted) return;

      setState(() {
        statsData = data['stats'];
        allActiveRiders =
        List<Map<String, dynamic>>.from(data['riders'] ?? []);
        activeRiders = allActiveRiders;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _mapFilter(String value) {
    switch (value) {
      case "Location Wise":
        return "location_wise";
      case "Longest Active":
        return "longest_active";
      case "Recently Activated":
        return "recently_activated";
      case "All Active":
      default:
        return "all_active";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff0f2027),
              Color(0xff203a43),
              Color(0xff2c5364),
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

                    /// ===== Header =====
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Text(
                          "Active Riders",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Icon(Icons.circle,
                            color: Colors.green, size: 12),
                        SizedBox(width: 6),
                        Text("Live",
                            style:
                            TextStyle(color: Colors.green)),
                      ],
                    ),

                    SizedBox(height: 15),

                    /// ===== Quick Stats =====
                    Row(
                      children: [
                        statBox(
                          "Total Active",
                          "${statsData?['totalActiveRiders'] ?? 0}",
                        ),
                        SizedBox(width: 10),
                        statBox(
                          "Avg Time",
                          "${statsData?['avgActiveTime'] ?? 0} min",
                        ),
                        SizedBox(width: 10),
                        statBox(
                          "Today Active",
                          "${statsData?['todayActiveRiders'] ?? 0}",
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    /// ===== Search =====
                    TextField(
                      controller: searchController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search by name or location",
                        hintStyle:
                        TextStyle(color: Colors.white54),
                        prefixIcon:
                        Icon(Icons.search, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Colors.white24),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.cyanAccent),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        _loadActiveRiders();
                      },
                    ),

                    SizedBox(height: 15),

                    /// ===== Filter =====
                    DropdownButtonFormField<String>(
                      value: selectedFilter,
                      dropdownColor: Colors.black87,
                      decoration: InputDecoration(
                        labelText: "Filter",
                        labelStyle:
                        TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Colors.white24),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        "All Active",
                        "Location Wise",
                        "Longest Active",
                        "Recently Activated",
                      ]
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: TextStyle(
                                color: Colors.white)),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedFilter = val!;
                        });
                        _loadActiveRiders();
                      },
                    ),

                    SizedBox(height: 20),

                    /// ===== Rider List =====
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                        itemCount: activeRiders.length,
                        itemBuilder: (context, index) {

                          var rider = activeRiders[index];

                          return Container(
                            margin:
                            EdgeInsets.only(bottom: 15),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withOpacity(0.08),
                              borderRadius:
                              BorderRadius.circular(15),
                              border: Border.all(
                                  color: Colors.white24),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text(
                                      rider["name"],
                                      style: TextStyle(
                                          color: Colors
                                              .cyanAccent,
                                          fontWeight:
                                          FontWeight.bold),
                                    ),
                                    Chip(
                                      label: Text("Active",
                                          style: TextStyle(
                                              color:
                                              Colors.black)),
                                      backgroundColor:
                                      Colors.green,
                                    )
                                  ],
                                ),

                                SizedBox(height: 5),

                                Text(
                                    "Phone: ${rider["phone"]}",
                                    style: TextStyle(
                                        color:
                                        Colors.white70)),

                                Text(
                                    "Location: ${rider["location"]}",
                                    style: TextStyle(
                                        color:
                                        Colors.white70)),

                                Text(
                                    "Active Since: ${rider["activeSince"]}",
                                    style: TextStyle(
                                        color:
                                        Colors.white70)),

                                Text(
                                    "Vehicle: ${rider["vehicle"]}",
                                    style: TextStyle(
                                        color:
                                        Colors.white70)),

                                Text(
                                    "Today Ride: ${rider["todayRide"]}",
                                    style: TextStyle(
                                        color:
                                        Colors.white70)),

                                Text(
                                    "Earning Today: ${rider["earning"]} BDT",
                                    style: TextStyle(
                                        color:
                                        Colors.white70)),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget statBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}