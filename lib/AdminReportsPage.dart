import 'package:flutter/material.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  // ===== Dummy Data (Backend থেকে আসবে পরে) =====
  List<Map<String, dynamic>> reports = [
    {
      "name": "Zahid",
      "role": "Passenger",
      "message": "App crash when booking ride",
      "isRead": false,
    },
    {
      "name": "Rahim",
      "role": "Rider",
      "message": "Location not updating",
      "isRead": true,
    },
  ];

  int get unreadCount =>
      reports.where((r) => r["isRead"] == false).length;

  void markAsRead(int index) {
    setState(() {
      reports[index]["isRead"] = true;
    });

    // 🔥 এখানে backend call দিবা
    // await api.markReportAsRead(id);

    // 🔥 এখানে email send হবে backend থেকে
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
      body: ListView.builder(
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
                    onPressed: isRead ? null : () => markAsRead(index),
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