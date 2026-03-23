import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'WalletPage.dart';
import 'report_problem_page.dart';

class SecurityPage extends StatefulWidget {
  final WalletUserRole userRole;
  const SecurityPage({
    super.key,
    required this.userRole,
  });

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}


/* ================= MODEL ================= */

class SecurityData {
  final bool emailVerified;
  final String? emergencyContact;
  final bool hasDuePayment;
  final double dueAmount;

  SecurityData({
    required this.emailVerified,
    required this.emergencyContact,
    required this.hasDuePayment,
    required this.dueAmount,
  });

  factory SecurityData.fromJson(Map<String, dynamic> json) {
    return SecurityData(
      emailVerified: json['emailVerified'],
      emergencyContact: json['emergencyContact'],
      hasDuePayment: json['hasDuePayment'],
      dueAmount: json['dueAmount'].toDouble(),
    );
  }
}

/* ================= SERVICE ================= */

class SecurityService {

  static Future<SecurityData> getSecurityData() async {

    final response = await http.get(
      Uri.parse("https://yourapi.com/security-data"),
    );

    if (response.statusCode == 200) {
      return SecurityData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load security data");
    }
  }

  static Future<void> saveEmergencyContact(String phone) async {

    await http.post(
      Uri.parse("https://yourapi.com/emergency-contact"),
      body: {"phone": phone},
    );

  }
}

/* ================= UI ================= */

class _SecurityPageState extends State<SecurityPage> {

  late Future<SecurityData> securityData;

  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    securityData = SecurityService.getSecurityData();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        title: const Text(
          "Security",
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: text),
      ),

      body: FutureBuilder<SecurityData>(
        future: securityData,

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load security data"));
          }

          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              _tile(
                icon: Icons.lock_outline,
                title: "Change Password",
                subtitle: "Update your account password",
                onTap: () {},
              ),

              _tile(
                icon: Icons.history,
                title: "Login Activity",
                subtitle: "View recent login devices",
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.verified_user, color: primary),
                title: const Text("Account Verification"),
                subtitle: Text(
                  data.emailVerified
                      ? "Verified with university email"
                      : "Verification pending",
                ),
              ),

              _tile(
                icon: Icons.emergency,
                title: "Emergency Contact",
                subtitle: data.emergencyContact ?? "Add emergency contact",
                onTap: () {
                  _addEmergencyContact();
                },
              ),

              _tile(
                icon: Icons.report_problem_outlined,
                title: "Report Security Issue",
                subtitle: "Report suspicious or unsafe activity",
                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportProblemPage(),
                    ),
                  );

                },
              ),

              const SizedBox(height: 25),

              if (data.hasDuePayment)

                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Row(
                        children: [

                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Payment Reminder",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: text,
                            ),
                          ),

                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "You have a due payment of ৳${data.dueAmount}. "
                            "If it is not paid within 7 days, your account may be suspended.",
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                        ),

                        onPressed: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WalletPage(
                                userRole: widget.userRole,
                              ),
                            ),
                          );

                        },

                        child: const Text("Pay Now"),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /* ================= TILE ================= */

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: ListTile(
        leading: Icon(icon, color: primary),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: text,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /* ================= EMERGENCY CONTACT ================= */

  void _addEmergencyContact() {

    final controller = TextEditingController();

    showDialog(
      context: context,

      builder: (_) => AlertDialog(
        title: const Text("Emergency Contact"),

        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: "Enter phone number",
          ),
        ),

        actions: [

          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          ElevatedButton(
            child: const Text("Save"),

            onPressed: () async {

              await SecurityService.saveEmergencyContact(
                controller.text,
              );

              Navigator.pop(context);

              setState(() {
                securityData = SecurityService.getSecurityData();
              });
            },
          ),

        ],
      ),
    );
  }
}