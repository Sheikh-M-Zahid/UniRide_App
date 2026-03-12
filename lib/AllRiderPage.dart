import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  TextEditingController searchController = TextEditingController();
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  void toggleStatus(String docId, String currentStatus) async {
    await FirebaseFirestore.instance
        .collection("riders")
        .doc(docId)
        .update({
      "status": currentStatus == "Suspended" ? "Active" : "Suspended"
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Container(
        decoration: const BoxDecoration(
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
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const Text(
                          "All Riders",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// ===== Search =====
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search by name or location...",
                        hintStyle:
                        const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                          const BorderSide(color: Colors.white24),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Colors.cyanAccent),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 15),

                    /// ===== Filter =====
                    DropdownButtonFormField<String>(
                      value: selectedFilter,
                      dropdownColor: Colors.black87,
                      decoration: InputDecoration(
                        labelText: "Filter",
                        labelStyle:
                        const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                          const BorderSide(color: Colors.white24),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        "All",
                        "Due Payment",
                        "Active",
                        "Suspended",
                        "Recently Joined"
                      ]
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: const TextStyle(
                                color: Colors.white)),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedFilter = val!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    /// ===== Rider List =====
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("riders")
                            .snapshots(),
                        builder: (context, snapshot) {

                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          var docs = snapshot.data!.docs;

                          var filteredDocs = docs.where((doc) {

                            var data =
                            doc.data() as Map<String, dynamic>;

                            String name =
                                data["name"]?.toLowerCase() ?? "";
                            String location =
                                data["location"]?.toLowerCase() ?? "";
                            String status =
                                data["status"] ?? "";
                            int due = data["due"] ?? 0;

                            bool searchMatch =
                                name.contains(searchController.text.toLowerCase()) ||
                                    location.contains(searchController.text.toLowerCase());

                            bool filterMatch = true;

                            if (selectedFilter == "Due Payment") {
                              filterMatch = due > 0;
                            } else if (selectedFilter == "Active") {
                              filterMatch = status == "Active";
                            } else if (selectedFilter == "Suspended") {
                              filterMatch = status == "Suspended";
                            }

                            return searchMatch && filterMatch;

                          }).toList();

                          return ListView.builder(
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {

                              var doc = filteredDocs[index];
                              var rider =
                              doc.data() as Map<String, dynamic>;

                              return Container(
                                margin: const EdgeInsets.only(
                                    bottom: 15),
                                padding:
                                const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.08),
                                  borderRadius:
                                  BorderRadius.circular(15),
                                  border: Border.all(
                                      color:
                                      Colors.white24),
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
                                          rider["name"] ?? "",
                                          style: const TextStyle(
                                              color:
                                              Colors.cyanAccent,
                                              fontWeight:
                                              FontWeight
                                                  .bold),
                                        ),
                                        Chip(
                                          label: Text(
                                            rider["status"] ?? "",
                                            style:
                                            const TextStyle(
                                                color: Colors
                                                    .black),
                                          ),
                                          backgroundColor:
                                          rider["status"] ==
                                              "Suspended"
                                              ? Colors.red
                                              : Colors.green,
                                        )
                                      ],
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                        "Phone: ${rider["phone"]}",
                                        style: const TextStyle(
                                            color:
                                            Colors.white70)),

                                    Text(
                                        "Location: ${rider["location"]}",
                                        style: const TextStyle(
                                            color:
                                            Colors.white70)),

                                    Text(
                                        "Due: ${rider["due"]} BDT",
                                        style: const TextStyle(
                                            color:
                                            Colors.white70)),

                                    const SizedBox(height: 10),

                                    Align(
                                      alignment:
                                      Alignment.centerRight,
                                      child: ElevatedButton(
                                        style:
                                        ElevatedButton
                                            .styleFrom(
                                          backgroundColor:
                                          rider["status"] ==
                                              "Suspended"
                                              ? Colors
                                              .green
                                              : Colors.red,
                                        ),
                                        onPressed: () =>
                                            toggleStatus(
                                                doc.id,
                                                rider["status"]),
                                        child: Text(
                                          rider["status"] ==
                                              "Suspended"
                                              ? "Activate"
                                              : "Suspend",
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
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
}