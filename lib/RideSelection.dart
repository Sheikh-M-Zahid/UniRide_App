import 'package:flutter/material.dart';
import 'PrivateCarRegistration.dart';
import 'BikeRegistration.dart';

class UniRideSelectionScreen extends StatefulWidget {
  const UniRideSelectionScreen({super.key});

  @override
  State<UniRideSelectionScreen> createState() =>
      _UniRideSelectionScreenState();
}

class _UniRideSelectionScreenState extends State<UniRideSelectionScreen> {

  // 0 = Nothing selected
  // 1 = Private Car
  // 2 = Motorbike
  int selectedOption = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "UniRide",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 25),

            const Text(
              "Choose how you want to\nearn with UniRide",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            /// ================= PRIVATE CAR =================
            _buildOptionCard(
              index: 1,
              title: "Private Car Owner",
              subtitle:
              "Use your white license plate car to begin earning on UniRide",
              icon: Icons.directions_car,
            ),

            const SizedBox(height: 20),

            /// ================= BIKE =================
            _buildOptionCard(
              index: 2,
              title: "Motorbike (2 wheeler)",
              subtitle:
              "Drive your motorcycle or scooter and start sharing rides",
              icon: Icons.motorcycle,
            ),

            const Spacer(),

            /// ================= CONTINUE BUTTON =================
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedOption == 0
                        ? Colors.grey
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  onPressed: selectedOption == 0
                      ? null
                      : () {

                    if (selectedOption == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const PrivateCarRegistration(),
                        ),
                      );
                    }

                    if (selectedOption == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const BikeRegistration(),
                        ),
                      );
                    }

                  },

                  child: const Text(
                    "Continue",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= OPTION CARD =================
  Widget _buildOptionCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {

    bool isSelected = selectedOption == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = index;
        });
      },

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
        ),

        child: Row(
          children: [

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Icon(
              icon,
              size: 45,
              color: isSelected
                  ? Colors.black
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}