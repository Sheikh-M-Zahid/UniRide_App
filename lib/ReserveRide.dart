import 'package:flutter/material.dart';
import 'ReserveRideSearch.dart';

class ReserveRide extends StatelessWidget {
  const ReserveRide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2937),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          "Reserve Ride",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image Section
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width * 0.58,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "images/reserve.png",
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Reserve Your Ride",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Book your ride in advance and travel on time with more convenience and confidence.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info Section Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Color(0xFF0F766E),
                            size: 22,
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              "Choose your exact pickup time up to 90 days in advance.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Divider(
                        color: Color(0xFFE5E7EB),
                        thickness: 1,
                      ),
                      SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            color: Color(0xFF0F766E),
                            size: 22,
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              "Extra wait time is included so you can meet your ride more comfortably.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Bottom Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReserveRideSearch(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Reserve a Trip",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}