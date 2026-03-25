import 'package:flutter/material.dart';

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

  List<Map<String, dynamic>> activeRiders = [
    {
      "name": "Rahim Uddin",
      "phone": "01700000000",
      "location": "Dhaka - Dhanmondi",
      "activeSince": "10:30 AM",
      "vehicle": "Private Car",
      "todayRide": 5,
      "earning": 1200,
    },
    {
      "name": "Karim Hasan",
      "phone": "01800000000",
      "location": "Chittagong - GEC",
      "activeSince": "09:15 AM",
      "vehicle": "CNG",
      "todayRide": 3,
      "earning": 800,
    },
  ];

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
                        statBox("Total Active",
                            activeRiders.length.toString()),
                        SizedBox(width: 10),
                        statBox("Avg Time", "2h 30m"),
                        SizedBox(width: 10),
                        statBox("Today Active", "12"),
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
                        setState(() {});
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
                      },
                    ),

                    SizedBox(height: 20),

                    /// ===== Rider List =====
                    Expanded(
                      child: ListView.builder(
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