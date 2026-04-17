import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color card = Colors.white;
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);
}

class AppStatsPage extends StatefulWidget {
  const AppStatsPage({super.key});

  @override
  State<AppStatsPage> createState() => _AppStatsPageState();
}

class _AppStatsPageState extends State<AppStatsPage> {
  late Future<AppStatsModel> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = AppStatsService().fetchAppStats();
  }

  Future<void> _refreshStats() async {
    setState(() {
      _statsFuture = AppStatsService().fetchAppStats();
    });
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'App Statistics',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshStats,
        child: FutureBuilder<AppStatsModel>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            }

            if (snapshot.hasError) {
              return _ErrorView(
                message: snapshot.error.toString(),
                onRetry: _refreshStats,
              );
            }

            if (!snapshot.hasData) {
              return _EmptyView(onRefresh: _refreshStats);
            }

            final stats = snapshot.data!;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _HeaderCard(
                  totalUsers: stats.totalUsers,
                  activeUsersToday: stats.activeUsersToday,
                  newUsersThisWeek: stats.newUsersThisWeek,
                  newUsersThisMonth: stats.newUsersThisMonth,
                ),
                const SizedBox(height: 16),

                const _SectionTitle(title: 'Overview'),
                const SizedBox(height: 10),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                  ),
                  children: [
                    _StatCard(
                      title: 'Total Users',
                      value: stats.totalUsers.toString(),
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      title: 'Total Riders',
                      value: stats.totalRiders.toString(),
                      icon: Icons.two_wheeler_rounded,
                      color: AppColors.secondary,
                    ),
                    _StatCard(
                      title: 'Total Passengers',
                      value: stats.totalPassengers.toString(),
                      icon: Icons.person_rounded,
                      color: AppColors.info,
                    ),
                    _StatCard(
                      title: 'Completed Rides',
                      value: stats.totalCompletedRides.toString(),
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    _StatCard(
                      title: 'Cancelled Rides',
                      value: stats.totalCancelledRides.toString(),
                      icon: Icons.cancel_rounded,
                      color: AppColors.danger,
                    ),
                    _StatCard(
                      title: 'Active Today',
                      value: stats.activeUsersToday.toString(),
                      icon: Icons.bolt_rounded,
                      color: AppColors.warning,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const _SectionTitle(title: 'User Category Breakdown'),
                const SizedBox(height: 10),
                _BreakdownCard(
                  items: [
                    _BreakdownItemData(
                      label: 'Student',
                      value: stats.studentCount,
                      total: stats.totalUsers,
                      color: AppColors.primary,
                    ),
                    _BreakdownItemData(
                      label: 'Faculty',
                      value: stats.facultyCount,
                      total: stats.totalUsers,
                      color: AppColors.info,
                    ),
                    _BreakdownItemData(
                      label: 'Staff',
                      value: stats.staffCount,
                      total: stats.totalUsers,
                      color: AppColors.warning,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const _SectionTitle(title: 'Gender Preference Usage'),
                const SizedBox(height: 10),
                _BreakdownCard(
                  items: [
                    _BreakdownItemData(
                      label: 'Male Only',
                      value: stats.malePreferenceCount,
                      total: stats.totalGenderPreferenceUsage,
                      color: AppColors.secondary,
                    ),
                    _BreakdownItemData(
                      label: 'Female Only',
                      value: stats.femalePreferenceCount,
                      total: stats.totalGenderPreferenceUsage,
                      color: AppColors.danger,
                    ),
                    _BreakdownItemData(
                      label: 'No Preference',
                      value: stats.noPreferenceCount,
                      total: stats.totalGenderPreferenceUsage,
                      color: AppColors.success,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const _SectionTitle(title: 'Registration Insights'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SimpleInfoCard(
                        title: 'New This Week',
                        value: stats.newUsersThisWeek.toString(),
                        subtitle: 'Recent registrations in last 7 days',
                        icon: Icons.calendar_view_week_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SimpleInfoCard(
                        title: 'New This Month',
                        value: stats.newUsersThisMonth.toString(),
                        subtitle: 'Recent registrations in current month',
                        icon: Icons.calendar_month_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const _SectionTitle(title: 'Quick Notes'),
                const SizedBox(height: 10),
                _NotesCard(stats: stats),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int totalUsers;
  final int activeUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;

  const _HeaderCard({
    required this.totalUsers,
    required this.activeUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Overview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalUsers Total Users',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderChip(
                label: 'Active Today: $activeUsersToday',
                icon: Icons.bolt_rounded,
              ),
              _HeaderChip(
                label: 'This Week: $newUsersThisWeek',
                icon: Icons.trending_up_rounded,
              ),
              _HeaderChip(
                label: 'This Month: $newUsersThisMonth',
                icon: Icons.calendar_month_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeaderChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
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
              fontSize: 22,
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final List<_BreakdownItemData> items;

  const _BreakdownCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _BreakdownRow(item: item),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final _BreakdownItemData item;

  const _BreakdownRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final double progress =
    item.total <= 0 ? 0 : (item.value / item.total).clamp(0, 1).toDouble();

    final percent = item.total <= 0
        ? '0%'
        : '${((item.value / item.total) * 100).toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              '${item.value}   ($percent)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress,
            backgroundColor: item.color.withOpacity(0.10),
            valueColor: AlwaysStoppedAnimation<Color>(item.color),
          ),
        ),
      ],
    );
  }
}

class _SimpleInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SimpleInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final AppStatsModel stats;

  const _NotesCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final String topUserGroup = _findTopUserGroup(stats);
    final String topGenderPreference = _findTopGenderPreference(stats);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _NoteTile(
            icon: Icons.groups_rounded,
            title: 'Largest User Group',
            value: topUserGroup,
          ),
          const Divider(height: 22),
          _NoteTile(
            icon: Icons.person_pin_circle_rounded,
            title: 'Most Used Preference',
            value: topGenderPreference,
          ),
          const Divider(height: 22),
          _NoteTile(
            icon: Icons.insights_rounded,
            title: 'Ride Completion Summary',
            value:
            '${stats.totalCompletedRides} completed and ${stats.totalCancelledRides} cancelled',
          ),
        ],
      ),
    );
  }

  String _findTopUserGroup(AppStatsModel stats) {
    final data = {
      'Student': stats.studentCount,
      'Faculty': stats.facultyCount,
      'Staff': stats.staffCount,
    };

    String topKey = 'Student';
    int topValue = -1;

    data.forEach((key, value) {
      if (value > topValue) {
        topValue = value;
        topKey = key;
      }
    });

    return topKey;
  }

  String _findTopGenderPreference(AppStatsModel stats) {
    final data = {
      'Male Only': stats.malePreferenceCount,
      'Female Only': stats.femalePreferenceCount,
      'No Preference': stats.noPreferenceCount,
    };

    String topKey = 'No Preference';
    int topValue = -1;

    data.forEach((key, value) {
      if (value > topValue) {
        topValue = value;
        topKey = key;
      }
    });

    return topKey;
  }
}

class _NoteTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _NoteTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        SizedBox(height: 120),
        Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.error_outline_rounded,
          size: 70,
          color: AppColors.danger,
        ),
        const SizedBox(height: 14),
        const Text(
          'Failed to load app statistics',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.insert_chart_outlined_rounded,
          size: 70,
          color: AppColors.mutedText,
        ),
        const SizedBox(height: 14),
        const Text(
          'No statistics available',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'App statistics will appear here when data becomes available from your backend.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: onRefresh,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Refresh'),
        ),
      ],
    );
  }
}

class _BreakdownItemData {
  final String label;
  final int value;
  final int total;
  final Color color;

  _BreakdownItemData({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });
}

class AppStatsModel {
  final int totalUsers;
  final int totalRiders;
  final int totalPassengers;
  final int totalCompletedRides;
  final int totalCancelledRides;
  final int activeUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;

  final int studentCount;
  final int facultyCount;
  final int staffCount;

  final int malePreferenceCount;
  final int femalePreferenceCount;
  final int noPreferenceCount;

  const AppStatsModel({
    required this.totalUsers,
    required this.totalRiders,
    required this.totalPassengers,
    required this.totalCompletedRides,
    required this.totalCancelledRides,
    required this.activeUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.studentCount,
    required this.facultyCount,
    required this.staffCount,
    required this.malePreferenceCount,
    required this.femalePreferenceCount,
    required this.noPreferenceCount,
  });

  factory AppStatsModel.fromJson(Map<String, dynamic> json) {
    return AppStatsModel(
      totalUsers: _toInt(json['total_users']),
      totalRiders: _toInt(json['total_riders']),
      totalPassengers: _toInt(json['total_passengers']),
      totalCompletedRides: _toInt(json['total_completed_rides']),
      totalCancelledRides: _toInt(json['total_cancelled_rides']),
      activeUsersToday: _toInt(json['active_users_today']),
      newUsersThisWeek: _toInt(json['new_users_this_week']),
      newUsersThisMonth: _toInt(json['new_users_this_month']),
      studentCount: _toInt(json['student_count']),
      facultyCount: _toInt(json['faculty_count']),
      staffCount: _toInt(json['staff_count']),
      malePreferenceCount: _toInt(json['male_preference_count']),
      femalePreferenceCount: _toInt(json['female_preference_count']),
      noPreferenceCount: _toInt(json['no_preference_count']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  int get totalGenderPreferenceUsage =>
      malePreferenceCount + femalePreferenceCount + noPreferenceCount;
}

class AppStatsService {
  final AuthApiService _authApiService = AuthApiService();

  Future<AppStatsModel> fetchAppStats() async {
    final response = await _authApiService.getAdminAppStats();
    final data = Map<String, dynamic>.from(response['data'] ?? {});
    return AppStatsModel.fromJson(data);
  }
}