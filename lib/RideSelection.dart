import 'package:flutter/material.dart';
import 'PrivateCarRegistration.dart';
import 'BikeRegistration.dart';
import 'services/auth_api_service.dart';

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
  final AuthApiService _authApiService = AuthApiService();

  // 0 = Nothing selected
  // 1 = Private Car
  // 2 = Motorbike
  int selectedOption = 0;
  bool isLoadingStatus = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleSelectionStatus();
  }

  Future<void> _loadVehicleSelectionStatus() async {
    try {
      await _authApiService.getVehicleSelectionStatus();

      if (!mounted) return;

      setState(() {
        isLoadingStatus = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingStatus = false;
      });
    }
  }

  Future<void> _continueSelection() async {
    if (selectedOption == 0) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await _authApiService.selectVehicleType(
        selectedVehicleType: selectedOption == 1 ? 'car' : 'bike',
      );

      final data = response['data'] ?? {};
      final nextScreen = data['nextScreen']?.toString();

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (nextScreen == 'private_car_registration') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivateCarRegistration(),
          ),
        );
        return;
      }

      if (nextScreen == 'bike_registration') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BikeRegistration(),
          ),
        );
        return;
      }

      if (nextScreen == 'vehicle_pending_review') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your vehicle is already pending review. Please wait for admin approval.',
            ),
          ),
        );
        return;
      }

      if (nextScreen == 'vehicle_already_exists') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You already added this vehicle type.',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to continue vehicle selection right now.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

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
      body: isLoadingStatus
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      )
          : Padding(
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

            _buildOptionCard(
              index: 1,
              title: "Private Car Owner",
              subtitle:
              "Use your white license plate car to begin earning on UniRide",
              icon: Icons.directions_car,
            ),

            const SizedBox(height: 20),

            _buildOptionCard(
              index: 2,
              title: "Motorbike (2 wheeler)",
              subtitle:
              "Drive your motorcycle or scooter and start sharing rides",
              icon: Icons.motorcycle,
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (selectedOption == 0 || isSubmitting)
                        ? AppColors.mutedText
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: (selectedOption == 0 || isSubmitting)
                      ? null
                      : _continueSelection,
                  child: isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Text(
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
      onTap: isSubmitting
          ? null
          : () {
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