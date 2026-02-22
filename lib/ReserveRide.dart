import 'package:flutter/material.dart';
import 'ReserveRideSearch.dart';

class ReserveRide extends StatelessWidget {
  const ReserveRide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [

          // 🔙 Back Button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),

          // 🔥 Top Image Section
          Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/reserve.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔥 Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Reserve",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔥 Info Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [

                Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Choose your exact pickup time up to 90 days in advance",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Divider(),

                SizedBox(height: 20),

                Row(
                  children: [
                    Icon(Icons.hourglass_empty),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Extra wait time included to meet your ride",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // 🔥 Bottom Button
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
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Reserve a trip",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}