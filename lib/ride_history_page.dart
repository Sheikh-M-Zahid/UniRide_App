import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'services/auth_api_service.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  List<Map<String, dynamic>> rideHistory = [];
  final AuthApiService _authApiService = AuthApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authApiService.getRideHistory();
      final data = List<Map<String, dynamic>>.from(response['data'] ?? []);

      if (!mounted) return;

      setState(() {
        rideHistory = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          'Ride History',
          style: TextStyle(color: AppColors.text),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : rideHistory.isEmpty
          ? const Center(
        child: Text(
          'No ride history found',
          style: TextStyle(color: AppColors.mutedText),
        ),
      )
          : ListView.builder(
        itemCount: rideHistory.length,
        itemBuilder: (context, index) {
          final ride = rideHistory[index];

          return ListTile(
            leading: const Icon(Icons.history, color: AppColors.primary),
            title: Text(
              ride['display_text'] ?? '',
              style: const TextStyle(color: AppColors.text),
            ),
          );
        },
      ),
    );
  }
}