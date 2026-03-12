import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_storage.dart';

class UpcomingReservePage extends StatefulWidget {
  const UpcomingReservePage({super.key});

  @override
  State<UpcomingReservePage> createState() => _UpcomingReservePageState();
}

class _UpcomingReservePageState extends State<UpcomingReservePage> {
  List<String> reserves = [];

  @override
  void initState() {
    super.initState();
    _loadReserves();
  }

  Future<void> _loadReserves() async {
    reserves = await AppStorage.getReserveHistory();
    if (mounted) setState(() {});
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
          'Upcoming Reserve',
          style: TextStyle(color: AppColors.text),
        ),
      ),
      body: reserves.isEmpty
          ? const Center(
        child: Text(
          'No active booking found',
          style: TextStyle(color: AppColors.mutedText),
        ),
      )
          : ListView.builder(
        itemCount: reserves.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: Text(
              reserves[index],
              style: const TextStyle(color: AppColors.text),
            ),
          );
        },
      ),
    );
  }
}