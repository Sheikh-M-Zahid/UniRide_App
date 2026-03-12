import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_storage.dart';

class SavedPlacesPage extends StatefulWidget {
  const SavedPlacesPage({super.key});

  @override
  State<SavedPlacesPage> createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  final TextEditingController homeController = TextEditingController();
  final TextEditingController campusController = TextEditingController();
  final TextEditingController hallController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    final data = await AppStorage.getUserData();
    homeController.text = data['home'] ?? '';
    campusController.text = data['campus'] ?? '';
    hallController.text = data['hall'] ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _savePlaces() async {
    await AppStorage.saveSavedPlaces(
      home: homeController.text.trim(),
      campus: campusController.text.trim(),
      hall: hallController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved places updated')),
    );
  }

  @override
  void dispose() {
    homeController.dispose();
    campusController.dispose();
    hallController.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
          style: TextStyle(color: AppColors.text),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field('Home', homeController),
            const SizedBox(height: 16),
            _field('Campus', campusController),
            const SizedBox(height: 16),
            _field('Hall', hallController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _savePlaces,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Save Places',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}