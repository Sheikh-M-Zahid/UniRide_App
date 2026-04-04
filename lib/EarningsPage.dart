import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/auth_api_service.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String selectedRange = "Today";

  final AuthApiService _authApiService = AuthApiService();

  double rating = 5.0;
  double todayEarnings = 0;
  double weekEarnings = 0;
  double monthEarnings = 0;
  int completedRides = 0;

  bool isLoading = true;
  List<double> chartValues = [];
  List<String> chartLabels = [];

  List<Map<String, dynamic>> chartDataList = [];

  @override
  void initState() {
    super.initState();
    _loadEarningsDashboard();
  }

  Future<void> _loadEarningsDashboard() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _authApiService.getEarningsDashboard(
        range: _mapRange(selectedRange),
      );

      final data = response['data'] ?? response;
      final summary = data['summary'] ?? {};
      final chart = data['chart'] ?? {};
      final List<dynamic> rawChart = chart['data'] ?? [];

      if (!mounted) return;

      setState(() {
        rating = (data['rating'] ?? 5).toDouble();
        todayEarnings = (summary['todayEarnings'] ?? 0).toDouble();
        weekEarnings = (summary['weekEarnings'] ?? 0).toDouble();
        monthEarnings = (summary['monthEarnings'] ?? 0).toDouble();
        completedRides = (summary['completedRides'] ?? 0).toInt();
        chartDataList = List<Map<String, dynamic>>.from(rawChart);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _mapRange(String value) {
    switch (value) {
      case "Weekly":
        return "weekly";
      case "Monthly":
        return "monthly";
      case "Today":
      default:
        return "today";
    }
  }

  List<double> getChartData() {
    return chartDataList
        .map<double>((e) => (e['value'] ?? 0).toDouble())
        .toList();
  }

  double getMaxY() {
    final data = getChartData();
    if (data.isEmpty) return 100;

    final maxValue = data.reduce(max);

    if (maxValue <= 100) return 100;
    return (maxValue * 1.2).ceilToDouble();
  }

  double getYAxisInterval() {
    final maxY = getMaxY();

    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 500;
    return 1000;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= chartDataList.length) {
      return const SizedBox.shrink();
    }

    const TextStyle style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: Color(0xFF1F2937),
    );

    final label = chartDataList[index]['label']?.toString() ?? '';

    if (selectedRange == "Today" && index % 2 != 0) {
      return const SizedBox.shrink();
    }

    if (selectedRange == "Monthly") {
      if (!(index == 0 ||
          index == 4 ||
          index == 9 ||
          index == 14 ||
          index == 19 ||
          index == 24 ||
          index == chartDataList.length - 1)) {
        return const SizedBox.shrink();
      }
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        label,
        style: style,
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return Text(
      "৳${value.toInt()}",
      style: const TextStyle(
        fontSize: 10,
        color: Color(0xFF1F2937),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartData = getChartData();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Earnings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Rating Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Rating",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Earnings Summary
            Row(
              children: [
                Expanded(
                  child: _earningCard("Today", todayEarnings),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _earningCard("Week", weekEarnings),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _earningCard("Month", monthEarnings),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Completed Rides
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "Total Completed Rides",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Text(
                    completedRides.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Chart Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Earnings Chart",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRange,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem<String>(
                        value: "Today",
                        child: Text("Today"),
                      ),
                      DropdownMenuItem<String>(
                        value: "Weekly",
                        child: Text("Weekly"),
                      ),
                      DropdownMenuItem<String>(
                        value: "Monthly",
                        child: Text("Monthly"),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value == null) return;
                      setState(() {
                        selectedRange = value;
                      });
                      _loadEarningsDashboard();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Chart
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: chartData.isEmpty
                  ? const Center(
                child: Text(
                  "No earnings data available",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              )
                  : BarChart(
                BarChartData(
                  maxY: getMaxY(),
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: getYAxisInterval(),
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFE5E7EB),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: getYAxisInterval(),
                        getTitlesWidget: _leftTitleWidgets,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 1,
                        getTitlesWidget: _bottomTitleWidgets,
                      ),
                    ),
                  ),
                  barGroups: chartData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          width: selectedRange == "Monthly" ? 7 : 12,
                          color: const Color(0xFF14B8A6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningCard(String title, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              "৳${amount.toStringAsFixed(0)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}