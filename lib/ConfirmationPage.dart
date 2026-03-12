import 'package:flutter/material.dart';
import 'RideSelection.dart';
import 'UserHome.dart';

class ConfirmationPage extends StatefulWidget {
  const ConfirmationPage({super.key});

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {

  // 0 = Nothing selected
  // 1 = Rider
  // 2 = Passenger
  int selectedRole = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1F2937)),
        centerTitle: true,
        title: const Text(
          "Confirmation",
          style: TextStyle(color: Color(0xFF1F2937)),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "How would you like to use UniRide?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 30),

            /// ================= Rider Option =================
            _buildSelectionCard(
              index: 1,
              icon: Icons.directions_car,
              title: "Ride Sharer",
              subtitle: "I want to share my bike/car with others.",
            ),

            const SizedBox(height: 20),

            /// ================= Passenger Option =================
            _buildSelectionCard(
              index: 2,
              icon: Icons.person_pin_circle,
              title: "Passenger",
              subtitle: "I am looking for a ride to campus.",
            ),

            const Spacer(),

            /// ================= NEXT BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRole == 0
                      ? const Color(0xFFB0BEC5)
                      : const Color(0xFF14B8A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: selectedRole == 0
                    ? null
                    : () {

                  if (selectedRole == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const UniRideSelectionScreen(),
                      ),
                    );
                  }

                  if (selectedRole == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const UniRideHomePage(),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= Selection Card =================
  Widget _buildSelectionCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {

    bool isSelected = selectedRole == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = index;
        });
      },

      child: Container(
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF14B8A6)
                : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F2937).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          children: [

            Icon(
              icon,
              size: 40,
              color: isSelected
                  ? const Color(0xFF0F766E)
                  : Colors.grey,
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  const SizedBox(),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF14B8A6),
              ),
          ],
        ),
      ),
    );
  }
}