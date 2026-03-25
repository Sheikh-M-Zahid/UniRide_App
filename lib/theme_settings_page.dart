import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_storage.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  String selectedTheme = 'teal';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    selectedTheme = await AppStorage.getTheme();
    if (mounted) setState(() {});
  }

  Future<void> _saveTheme(String value) async {
    setState(() {
      selectedTheme = value;
    });
    await AppStorage.saveTheme(value);
  }

  Widget _tile(String value, String label) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedTheme,
      activeColor: AppColors.primary,
      title: Text(label),
      onChanged: (newValue) {
        if (newValue != null) {
          _saveTheme(newValue);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          'Theme Settings',
          style: TextStyle(color: AppColors.text),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _tile('teal', 'Teal Theme'),
          _tile('ocean', 'Ocean Theme'),
          _tile('emerald', 'Emerald Theme'),
        ],
      ),
    );
  }
}