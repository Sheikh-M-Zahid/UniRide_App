import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String selectedRange = "Today";

  double rating = 4.8;
  double todayEarnings = 450;
  double weekEarnings = 1850;
  double monthEarnings = 7200;
  int completedRides = 58;

  /// 6 AM to 11 PM = 18 values
  final List<double> todayData = [
    20,
    30,
    50,
    10,
    80,
    40,
    70,
    60,
    20,
    30,
    10,
    15,
    25,
    40,
    50,
    60,
    20,
    10,
  ];

  /// Sun to Sat
  final List<double> weeklyData = [
    400,
    300,
    250,
    500,
    450,
    350,
    600,
  ];

  late List<double> monthlyData;

  @override
  void initState() {
    super.initState();
    monthlyData = List.generate(
      _daysInCurrentMonth(),
          (index) => (index + 1) * 20.0,
    );
  }

  int _daysInCurrentMonth() {
    final now = DateTime.now();
    final firstDayNextMonth = now.month < 12
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);

    final lastDayCurrentMonth =
    firstDayNextMonth.subtract(const Duration(days: 1));

    return lastDayCurrentMonth.day;
  }

  List<double> getChartData() {
    switch (selectedRange) {
      case "Today":
        return todayData;
      case "Weekly":
        return weeklyData;
      case "Monthly":
        return monthlyData;
      default:
        return todayData;
    }
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

  String _formatTodayHourLabel(int index) {
    final hour24 = index + 6;

    if (hour24 == 0) return "12AM";
    if (hour24 == 12) return "12PM";
    if (hour24 > 12) return "${hour24 - 12}PM";
    return "${hour24}AM";
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    final data = getChartData();

    if (index < 0 || index >= data.length) {
      return const SizedBox.shrink();
    }

    const TextStyle style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: Color(0xFF1F2937),
    );

    if (selectedRange == "Today") {
      if (index % 2 != 0) {
        return const SizedBox.shrink();
      }

      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          _formatTodayHourLabel(index),
          style: style,
        ),
      );
    }

    if (selectedRange == "Weekly") {
      const List<String> days = [
        "Sun",
        "Mon",
        "Tue",
        "Wed",
        "Thu",
        "Fri",
        "Sat",
      ];

      if (index >= days.length) {
        return const SizedBox.shrink();
      }

      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          days[index],
          style: style,
        ),
      );
    }

    if (!(index == 0 ||
        index == 4 ||
        index == 9 ||
        index == 14 ||
        index == 19 ||
        index == 24 ||
        index == data.length - 1)) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        "${index + 1}",
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
      body: SingleChildScrollView(
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