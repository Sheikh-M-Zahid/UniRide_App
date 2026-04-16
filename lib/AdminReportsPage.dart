import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final AuthApiService _authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;
  bool isActionLoading = false;
  String? errorMessage;

  int unsolvedCount = 0;
  int solvedCount = 0;


  Future<void> _fetchReports() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _authApiService.getAdminReports();
      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final summary = Map<String, dynamic>.from(data['summary'] ?? {});
      final reportsList = List<Map<String, dynamic>>.from(data['reports'] ?? []);

      setState(() {
        reports = reportsList;
        unsolvedCount = int.tryParse('${summary['unsolvedCount'] ?? 0}') ?? 0;
        solvedCount = int.tryParse('${summary['solvedCount'] ?? 0}') ?? 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> markAsRead(int index) async {
    final reportId = (reports[index]['id'] ?? '').toString();

    if (reportId.isEmpty || isActionLoading) return;

    setState(() {
      isActionLoading = true;
    });

    try {
      await _authApiService.markAdminReportAsSolved(reportId: reportId);
      await _fetchReports();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report marked as solved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark report as solved: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isActionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("User Reports"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      )
          : reports.isEmpty
          ? const Center(
        child: Text(
          "No reports found",
          style: TextStyle(color: Colors.white),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];

          final isRead = report["isRead"];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRead
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Name + Role =====
                Row(
                  children: [
                    Text(
                      report["name"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report["role"],
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ===== Message =====
                Text(
                  report["message"],
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 12),

                // ===== Button =====
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: (isRead || isActionLoading) ? null : () => markAsRead(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRead
                          ? Colors.grey
                          : Colors.cyanAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(isRead ? "Solved" : "Mark as Solved"),
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