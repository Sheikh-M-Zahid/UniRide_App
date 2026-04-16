import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'services/auth_api_service.dart';

class UpcomingReservePage extends StatefulWidget {
  const UpcomingReservePage({super.key});

  @override
  State<UpcomingReservePage> createState() => _UpcomingReservePageState();
}

class _UpcomingReservePageState extends State<UpcomingReservePage> {
  final AuthApiService _authApiService = AuthApiService();

  List<Map<String, dynamic>> reserves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReserves();
  }

  Future<void> _loadReserves() async {
    try {
      final response = await _authApiService.getUpcomingReserve();
      final data = response['data'];

      List<Map<String, dynamic>> loadedReserves = [];

      if (data is List) {
        loadedReserves = List<Map<String, dynamic>>.from(data);
      }

      if (!mounted) return;

      setState(() {
        reserves = loadedReserves;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
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
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          'Upcoming Reserve',
          style: TextStyle(color: AppColors.text),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      )
          : reserves.isEmpty
          ? const Center(
        child: Text(
          'No active booking found',
          style: TextStyle(color: AppColors.mutedText),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reserves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reserve = reserves[index];
          final confirmed = reserve['confirmed'] == true;
          final status =
          (reserve['ride_status'] ?? 'active').toString();
          final fare = reserve['fare'];

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (reserve['display_text'] ??
                            '${(reserve['start_location'] ?? '').toString()} → ${(reserve['destination'] ?? '').toString()}')
                            .toString(),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fare: BDT ${(fare ?? 0).toString()}',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          color: status.toLowerCase() == 'reserve'
                              ? Colors.orange
                              : AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        confirmed ? 'Confirmed' : 'Pending confirmation',
                        style: TextStyle(
                          color: confirmed
                              ? AppColors.secondary
                              : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}