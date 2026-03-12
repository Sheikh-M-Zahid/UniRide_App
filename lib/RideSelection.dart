import 'package:flutter/material.dart';
import 'PrivateCarRegistration.dart';
import 'BikeRegistration.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "UniRide",
          style: TextStyle(
            color: AppColors.text,
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
                color: AppColors.text,
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
                        ? AppColors.mutedText
                        : AppColors.primary,
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
                      fontSize: 18,
                    ),
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
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              size: 45,
              color: isSelected ? AppColors.primary : AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}