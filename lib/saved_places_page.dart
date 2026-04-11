import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/auth_api_service.dart';

import 'app_colors.dart';
import 'map_picker_screen.dart';

class SavedPlacesPage extends StatefulWidget {
  final String googleApiKey;
  final LatLng initialPosition;

  const SavedPlacesPage({
    super.key,
    required this.googleApiKey,
    required this.initialPosition,
  });

  @override
  State<SavedPlacesPage> createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  final TextEditingController homeController = TextEditingController();
  final TextEditingController campusController = TextEditingController();
  final TextEditingController hallController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authApiService.getSavedPlaces();
      final data = response['data'] ?? {};

      homeController.text = data['home_address'] ?? '';
      campusController.text = data['campus_address'] ?? '';
      hallController.text = data['hostel_address'] ?? '';

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _savePlaces() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _authApiService.updateSavedPlaces(
        homeAddress: homeController.text.trim(),
        campusAddress: campusController.text.trim(),
        hostelAddress: hallController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved places updated'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickLocation({
    required TextEditingController controller,
    required String title,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: widget.googleApiKey,
          initialPosition: widget.initialPosition,
          title: title,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final String address = result["address"] ?? "";

      if (mounted) {
        setState(() {
          controller.text = address;
        });
      }
    }
  }

  Widget _locationField({
    required String label,
    required TextEditingController controller,
    required String pickerTitle,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () {
        _pickLocation(
          controller: controller,
          title: pickerTitle,
        );
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Tap to select location',
        filled: true,
        fillColor: AppColors.inputFill,
        suffixIcon: const Icon(
          Icons.location_on_outlined,
          color: AppColors.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    homeController.dispose();
    campusController.dispose();
    hallController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          'Saved Places',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _locationField(
              label: 'Home',
              controller: homeController,
              pickerTitle: 'Select Home Location',
            ),
            const SizedBox(height: 16),
            _locationField(
              label: 'Campus',
              controller: campusController,
              pickerTitle: 'Select Campus Location',
            ),
            const SizedBox(height: 16),
            _locationField(
              label: 'Hall',
              controller: hallController,
              pickerTitle: 'Select Hall Location',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePlaces,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Save Places',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}