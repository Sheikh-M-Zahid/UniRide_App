import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_storage.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  List<String> rideHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    rideHistory = await AppStorage.getRideHistory();
    if (mounted) setState(() {});
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
      body: rideHistory.isEmpty
          ? const Center(
        child: Text(
          'No ride history found',
          style: TextStyle(color: AppColors.mutedText),
        ),
      )
          : ListView.builder(
        itemCount: rideHistory.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.history, color: AppColors.primary),
            title: Text(
              rideHistory[index],
              style: const TextStyle(color: AppColors.text),
            ),
          );
        },
      ),
    );
  }
}