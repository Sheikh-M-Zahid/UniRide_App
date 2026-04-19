import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'UserOffer.dart';
import 'UserHome.dart';
import 'UserProfile.dart';
import 'UserServices.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final AuthApiService _authApiService = AuthApiService();

  String _selectedType = 'all';
  String _selectedTime = 'today';

  final List<String> _typeOptions = [
    'all',
    'completed',
    'cancelled',
    'reserved',
    'send_item',
  ];

  final List<String> _timeOptions = [
    'today',
    'this_week',
    'this_month',
  ];

  Map<String, dynamic> summary = {
    'total': 0,
    'completed': 0,
    'cancelled': 0,
    'earnings': 0,
  };

  List<Map<String, dynamic>> activities = [];
  bool isLoading = true;
  String? emptyState;

  @override
  void initState() {
    super.initState();
    _loadActivityDashboard();
  }

  Future<void> _loadActivityDashboard() async {
    try {
      final response = await _authApiService.getActivityDashboard(
        type: _selectedType,
        time: _selectedTime,
      );

      final data = response['data'] ?? {};

      if (!mounted) return;

      setState(() {
        summary = data['summary'] is Map
            ? Map<String, dynamic>.from(data['summary'])
            : {
          'total': 0,
          'completed': 0,
          'cancelled': 0,
          'earnings': 0,
        };

        activities = data['activities'] is List
            ? List<Map<String, dynamic>>.from(data['activities'])
            : [];

        emptyState = data['emptyState']?.toString();
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

  String _formatTypeLabel(String value) {
    switch (value) {
      case 'all':
        return 'All';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'reserved':
        return 'Reserved';
      case 'send_item':
        return 'Send Item';
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      default:
        return value;
    }
  }

  String _formatMoney(dynamic value) {
    final num amount =
    (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    return '৳${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}';
  }

  Color _statusColor(String status) {
    final safe = status.toLowerCase();

    if (safe == 'completed' || safe == 'confirmed') {
      return const Color(0xFF0F766E);
    }

    if (safe == 'cancelled') {
      return Colors.red;
    }

    if (safe == 'pending') {
      return Colors.orange;
    }

    if (safe == 'ongoing') {
      return Colors.blue;
    }

    return AppColors.mutedText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0, top: 10),
          child: Text(
            "Activity",
            style: TextStyle(
              color: AppColors.text,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [
                const Text(
                  "Filter",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.secondary,
                      ),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      onChanged: (String? newValue) async {
                        if (newValue == null) return;
                        setState(() {
                          _selectedType = newValue;
                          isLoading = true;
                        });
                        await _loadActivityDashboard();
                      },
                      items: _typeOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(_formatTypeLabel(value)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTime,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.secondary,
                      ),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      onChanged: (String? newValue) async {
                        if (newValue == null) return;
                        setState(() {
                          _selectedTime = newValue;
                          isLoading = true;
                        });
                        await _loadActivityDashboard();
                      },
                      items: _timeOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(_formatTypeLabel(value)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Total',
                    value: '${summary['total'] ?? 0}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    title: 'Completed',
                    value: '${summary['completed'] ?? 0}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    title: 'Cancelled',
                    value: '${summary['cancelled'] ?? 0}',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Earnings: ${_formatMoney(summary['earnings'] ?? 0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
                : activities.isEmpty
                ? Center(
              child: Text(
                emptyState ?? "No activity found",
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 16,
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = activities[index];
                final status = (item['status'] ?? 'unknown').toString();
                final canCancel = item['canCancel'] == true;
                final riderName =
                (item['riderName'] ?? item['name'] ?? '').toString();
                final riderPhone =
                (item['riderPhone'] ?? item['phone'] ?? '').toString();
                final itemType = (item['item_type'] ?? 'ride').toString();

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (item['title'] ?? 'Activity').toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (itemType == 'reserve') ...[
                        _activityRow(
                          'Route',
                          '${(item['pickup'] ?? '').toString()} → ${(item['destination'] ?? '').toString()}',
                        ),
                        _activityRow(
                          'Distance',
                          item['totalDistanceKm'] == null
                              ? ''
                              : '${item['totalDistanceKm']} km',
                        ),
                        _activityRow(
                          'Estimated Time',
                          item['estimatedTravelMinutes'] == null
                              ? ''
                              : '${item['estimatedTravelMinutes']} min',
                        ),
                        _activityRow(
                          'Fare',
                          _formatMoney(item['fare'] ?? 0),
                        ),
                        _activityRow('Date', (item['date'] ?? '').toString()),
                        _activityRow('Time', (item['time'] ?? '').toString()),
                        _activityRow(
                          'Rider Name',
                          riderName.isEmpty || riderName == 'Waiting for rider'
                              ? 'Waiting for rider'
                              : riderName,
                        ),
                        _activityRow(
                          'Rider Phone',
                          riderPhone.isEmpty || riderPhone == 'Not assigned yet'
                              ? 'Not assigned yet'
                              : riderPhone,
                        ),
                      ] else ...[
                        _activityRow('Name', (item['name'] ?? '').toString()),
                        _activityRow('Phone', (item['phone'] ?? '').toString()),
                        _activityRow('Pickup', (item['pickup'] ?? '').toString()),
                        _activityRow(
                          'Destination',
                          (item['destination'] ?? '').toString(),
                        ),
                        _activityRow('Time', (item['time'] ?? '').toString()),
                        _activityRow(
                          'Fare',
                          _formatMoney(item['fare'] ?? 0),
                        ),
                        _activityRow('Date', (item['date'] ?? '').toString()),
                      ],

                      if (itemType == 'reserve' && canCancel) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              try {
                                final reserveId = (item['id'] ?? '').toString();
                                if (reserveId.isEmpty) return;

                                await _authApiService.cancelReserve(
                                  reserveId: reserveId,
                                );

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Reserve request cancelled successfully.',
                                    ),
                                  ),
                                );

                                setState(() {
                                  isLoading = true;
                                });

                                await _loadActivityDashboard();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst('Exception: ', ''),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel Request',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedText,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {

            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const UniRideHomePage()),
              );
              break;

            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ServicesPage()),
              );
              break;

            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const OffersPage()),
              );
              break;

            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const UniRideProfilePage()),
              );
              break;
          }
        },

        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view), label: "Services"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: "Activity"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer), label: "Offers"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
  Widget _summaryCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}