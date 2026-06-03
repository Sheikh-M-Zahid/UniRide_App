import 'package:flutter/material.dart';
import 'WalletPage.dart';
import 'report_problem_page.dart';
import 'services/auth_api_service.dart';

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
      emailVerified: json['emailVerified'] == true,
      emergencyContact: (json['emergencyContact'] ?? '').toString(),
      hasDuePayment: json['hasDuePayment'] == true,
      dueAmount: (json['dueAmount'] is num)
          ? (json['dueAmount'] as num).toDouble()
          : double.tryParse('${json['dueAmount'] ?? 0}') ?? 0,
    );
  }
}

/* ================= UI ================= */

class _SecurityPageState extends State<SecurityPage> {
  final AuthApiService _api = AuthApiService();

  late Future<SecurityData> securityData;

  static const Color primary    = Color(0xFF14B8A6);
  static const Color secondary  = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text       = Color(0xFF1F2937);
  static const Color inputFill  = Color(0xFFF1F5F9);
  static const Color border     = Color(0xFFD1D5DB);
  static const Color mutedText  = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    securityData = _loadSecurityData();
  }

  Future<SecurityData> _loadSecurityData() async {
    final response = await _api.getSecuritySummary();
    final data = response['data'] ?? {};
    return SecurityData.fromJson(Map<String, dynamic>.from(data));
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
            return Center(
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
              ),
            );
          }

          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              _tile(
                icon: Icons.lock_outline,
                title: "Change Password",
                subtitle: "Update your account password",
                onTap: _changePassword,
              ),

              _tile(
                icon: Icons.history,
                title: "Login Activity",
                subtitle: "Currently unavailable",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Login Activity is not available yet"),
                    ),
                  );
                },
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
                          Icon(Icons.warning_amber_rounded, color: Colors.red),
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

  /* ================= INPUT DECORATION HELPER ================= */

  InputDecoration _inputDecoration({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: mutedText),
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  /* ================= DIALOG STYLE HELPER ================= */

  AlertDialog _styledDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Text(
        title,
        style: const TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: content,
      actions: actions,
    );
  }

  /* ================= BUTTON HELPERS ================= */

  Widget _cancelButton({required bool isSaving, required VoidCallback onTap}) {
    return TextButton(
      onPressed: isSaving ? null : onTap,
      child: const Text(
        "Cancel",
        style: TextStyle(color: mutedText),
      ),
    );
  }

  Widget _saveButton({
    required bool isSaving,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: isSaving ? null : onPressed,
      child: isSaving
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Text(
        "Save",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  /* ================= CHANGE PASSWORD ================= */

  void _changePassword() {
    final currentPassController = TextEditingController();
    final newPassController     = TextEditingController();
    final confirmPassController = TextEditingController();

    bool isSaving      = false;
    bool showCurrent   = false;
    bool showNew       = false;
    bool showConfirm   = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {

          void toggleCurrent()  => setDialogState(() => showCurrent  = !showCurrent);
          void toggleNew()      => setDialogState(() => showNew      = !showNew);
          void toggleConfirm()  => setDialogState(() => showConfirm  = !showConfirm);

          return _styledDialog(
            title: "Change Password",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Current Password
                TextField(
                  controller: currentPassController,
                  obscureText: !showCurrent,
                  style: const TextStyle(color: text),
                  decoration: _inputDecoration(
                    label: "Current Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        showCurrent ? Icons.visibility : Icons.visibility_off,
                        color: mutedText,
                        size: 20,
                      ),
                      onPressed: toggleCurrent,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // New Password
                TextField(
                  controller: newPassController,
                  obscureText: !showNew,
                  style: const TextStyle(color: text),
                  decoration: _inputDecoration(
                    label: "New Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNew ? Icons.visibility : Icons.visibility_off,
                        color: mutedText,
                        size: 20,
                      ),
                      onPressed: toggleNew,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Confirm Password
                TextField(
                  controller: confirmPassController,
                  obscureText: !showConfirm,
                  style: const TextStyle(color: text),
                  decoration: _inputDecoration(
                    label: "Confirm Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirm ? Icons.visibility : Icons.visibility_off,
                        color: mutedText,
                        size: 20,
                      ),
                      onPressed: toggleConfirm,
                    ),
                  ),
                ),

              ],
            ),
            actions: [
              _cancelButton(
                isSaving: isSaving,
                onTap: () => Navigator.pop(dialogContext),
              ),
              _saveButton(
                isSaving: isSaving,
                onPressed: () async {
                  final currentPassword = currentPassController.text.trim();
                  final newPassword     = newPassController.text.trim();
                  final confirmPassword = confirmPassController.text.trim();

                  if (currentPassword.isEmpty ||
                      newPassword.isEmpty ||
                      confirmPassword.isEmpty) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text("All fields are required")),
                    );
                    return;
                  }

                  if (newPassword != confirmPassword) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text("New passwords do not match"),
                      ),
                    );
                    return;
                  }

                  try {
                    setDialogState(() => isSaving = true);

                    await _api.changeSecurityPassword(
                      currentPassword: currentPassword,
                      newPassword: newPassword,
                    );

                    if (!mounted) return;
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text("Password changed successfully"),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    setDialogState(() => isSaving = false);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /* ================= EMERGENCY CONTACT ================= */

  void _addEmergencyContact() {
    final controller = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _styledDialog(
          title: "Emergency Contact",
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: text),
            decoration: _inputDecoration(label: "Enter phone number"),
          ),
          actions: [
            _cancelButton(
              isSaving: isSaving,
              onTap: () => Navigator.pop(dialogContext),
            ),
            _saveButton(
              isSaving: isSaving,
              onPressed: () async {
                final phone = controller.text.trim();

                if (phone.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text("Phone number is required")),
                  );
                  return;
                }

                try {
                  setDialogState(() => isSaving = true);

                  await _api.updateEmergencyContact(phone: phone);

                  if (!mounted) return;
                  Navigator.pop(dialogContext);

                  setState(() {
                    securityData = _loadSecurityData();
                  });

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text("Emergency contact updated"),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  setDialogState(() => isSaving = false);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}