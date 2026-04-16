import 'package:flutter/material.dart';

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

class TopLocationPage extends StatefulWidget {
  const TopLocationPage({super.key});

  @override
  State<TopLocationPage> createState() => _TopLocationPageState();
}

class _TopLocationPageState extends State<TopLocationPage> {
  late Future<TopLocationStatsModel> _future;

  @override
  void initState() {
    super.initState();
    _future = TopLocationService().fetchTopLocationStats();
  }

  Future<void> _reload() async {
    setState(() {
      _future = TopLocationService().fetchTopLocationStats();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Top Locations',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _reload,
        child: FutureBuilder<TopLocationStatsModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            }

            if (snapshot.hasError) {
              return _ErrorView(
                message: snapshot.error.toString(),
                onRetry: _reload,
              );
            }

            if (!snapshot.hasData) {
              return _EmptyView(onRefresh: _reload);
            }

            final data = snapshot.data!;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _OverviewHeader(data: data),
                const SizedBox(height: 18),

                const _SectionTitle(title: 'Quick Overview'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Top Pickup',
                        value: data.topPickupLocationName,
                        subtitle: '${data.topPickupLocationCount} selections',
                        icon: Icons.my_location_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Top Destination',
                        value: data.topDestinationLocationName,
                        subtitle: '${data.topDestinationLocationCount} selections',
                        icon: Icons.location_on_rounded,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Highest Demand',
                        value: data.highestDemandLocationName,
                        subtitle: '${data.highestDemandLocationCount} requests',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Most Riders',
                        value: data.highestRiderAvailabilityLocationName,
                        subtitle:
                        '${data.highestRiderAvailabilityLocationCount} riders',
                        icon: Icons.two_wheeler_rounded,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _LocationGroupCard(
                  title: 'Top Pickup Points',
                  icon: Icons.my_location_rounded,
                  iconColor: AppColors.primary,
                  emptyMessage: 'No pickup location data found.',
                  items: data.topPickupPoints,
                  metricLabelBuilder: (item) => '${item.count} pickups',
                ),

                const SizedBox(height: 16),
                _LocationGroupCard(
                  title: 'Top Destination Points',
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.secondary,
                  emptyMessage: 'No destination location data found.',
                  items: data.topDestinationPoints,
                  metricLabelBuilder: (item) => '${item.count} drops',
                ),

                const SizedBox(height: 16),
                _LocationGroupCard(
                  title: 'High Demand Locations',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.warning,
                  emptyMessage: 'No ride demand data found.',
                  items: data.highDemandLocations,
                  metricLabelBuilder: (item) => '${item.count} requests',
                ),

                const SizedBox(height: 16),
                _LocationGroupCard(
                  title: 'High Rider Availability',
                  icon: Icons.directions_bike_rounded,
                  iconColor: AppColors.info,
                  emptyMessage: 'No rider availability data found.',
                  items: data.highRiderAvailabilityLocations,
                  metricLabelBuilder: (item) => '${item.count} riders',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  final TopLocationStatsModel data;

  const _OverviewHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location Insights',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track the most used locations across the platform',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderChip(
                label: 'Pickup Points: ${data.topPickupPoints.length}',
                icon: Icons.my_location_rounded,
              ),
              _HeaderChip(
                label: 'Destinations: ${data.topDestinationPoints.length}',
                icon: Icons.location_on_rounded,
              ),
              _HeaderChip(
                label: 'Demand Zones: ${data.highDemandLocations.length}',
                icon: Icons.local_fire_department_rounded,
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(16),
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
            child: Icon(icon, color: color),
          ),
          const Spacer(),
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
            value.isEmpty ? 'N/A' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationGroupCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<LocationInsightItem> items;
  final String emptyMessage;
  final String Function(LocationInsightItem item) metricLabelBuilder;

  const _LocationGroupCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
    required this.emptyMessage,
    required this.metricLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              return _LocationRankTile(
                rank: index + 1,
                item: item,
                metricLabel: metricLabelBuilder(item),
                isLast: index == items.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _LocationRankTile extends StatelessWidget {
  final int rank;
  final LocationInsightItem item;
  final String metricLabel;
  final bool isLast;

  const _LocationRankTile({
    required this.rank,
    required this.item,
    required this.metricLabel,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 8 : 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.locationName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.subText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.mutedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            metricLabel,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 150),
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
          size: 72,
          color: AppColors.danger,
        ),
        const SizedBox(height: 14),
        const Text(
          'Failed to load location insights',
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
          Icons.location_off_rounded,
          size: 72,
          color: AppColors.mutedText,
        ),
        const SizedBox(height: 14),
        const Text(
          'No location data available',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Top location insights will appear here when your backend sends real data.',
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

class LocationInsightItem {
  final String locationName;
  final int count;
  final String subText;

  const LocationInsightItem({
    required this.locationName,
    required this.count,
    required this.subText,
  });

  factory LocationInsightItem.fromJson(Map<String, dynamic> json) {
    return LocationInsightItem(
      locationName: (json['location_name'] ?? '').toString(),
      count: _toInt(json['count']),
      subText: (json['sub_text'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class TopLocationStatsModel {
  final List<LocationInsightItem> topPickupPoints;
  final List<LocationInsightItem> topDestinationPoints;
  final List<LocationInsightItem> highDemandLocations;
  final List<LocationInsightItem> highRiderAvailabilityLocations;

  const TopLocationStatsModel({
    required this.topPickupPoints,
    required this.topDestinationPoints,
    required this.highDemandLocations,
    required this.highRiderAvailabilityLocations,
  });

  factory TopLocationStatsModel.fromJson(Map<String, dynamic> json) {
    return TopLocationStatsModel(
      topPickupPoints: _parseList(json['top_pickup_points']),
      topDestinationPoints: _parseList(json['top_destination_points']),
      highDemandLocations: _parseList(json['high_demand_locations']),
      highRiderAvailabilityLocations:
      _parseList(json['high_rider_availability_locations']),
    );
  }

  static List<LocationInsightItem> _parseList(dynamic rawList) {
    if (rawList is List) {
      return rawList
          .map((e) => LocationInsightItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  String get topPickupLocationName =>
      topPickupPoints.isNotEmpty ? topPickupPoints.first.locationName : '';

  int get topPickupLocationCount =>
      topPickupPoints.isNotEmpty ? topPickupPoints.first.count : 0;

  String get topDestinationLocationName => topDestinationPoints.isNotEmpty
      ? topDestinationPoints.first.locationName
      : '';

  int get topDestinationLocationCount =>
      topDestinationPoints.isNotEmpty ? topDestinationPoints.first.count : 0;

  String get highestDemandLocationName =>
      highDemandLocations.isNotEmpty ? highDemandLocations.first.locationName : '';

  int get highestDemandLocationCount =>
      highDemandLocations.isNotEmpty ? highDemandLocations.first.count : 0;

  String get highestRiderAvailabilityLocationName =>
      highRiderAvailabilityLocations.isNotEmpty
          ? highRiderAvailabilityLocations.first.locationName
          : '';

  int get highestRiderAvailabilityLocationCount =>
      highRiderAvailabilityLocations.isNotEmpty
          ? highRiderAvailabilityLocations.first.count
          : 0;
}

class TopLocationService {
  Future<TopLocationStatsModel> fetchTopLocationStats() async {
    await Future.delayed(const Duration(milliseconds: 400));

    throw UnimplementedError(
      'Connect this service with your Node.js + PostgreSQL backend API.',
    );

    /*
    Backend response example:

    {
      "top_pickup_points": [
        {
          "location_name": "Main Gate",
          "count": 120,
          "sub_text": "Most selected pickup point"
        },
        {
          "location_name": "Boys Hall",
          "count": 95,
          "sub_text": "Frequently used by students"
        }
      ],
      "top_destination_points": [
        {
          "location_name": "Academic Building",
          "count": 110,
          "sub_text": "Top drop-off point"
        }
      ],
      "high_demand_locations": [
        {
          "location_name": "Library",
          "count": 88,
          "sub_text": "High ride request volume"
        }
      ],
      "high_rider_availability_locations": [
        {
          "location_name": "Transport Area",
          "count": 24,
          "sub_text": "Most riders available here"
        }
      ]
    }
    */
  }
}