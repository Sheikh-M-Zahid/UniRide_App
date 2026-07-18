import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'WalletPage.dart';
import 'UserSetting.dart';
import 'RiderSetting.dart';
import 'PersonalInfo.dart';
import 'LogIn.dart';

class AccountSuspendedPage extends StatelessWidget {
  final bool isRider;

  const AccountSuspendedPage({super.key, this.isRider = false});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UniRideLogin()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text('Account Suspended',
            style: TextStyle(color: Color(0xFF1F2937))),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your account has been suspended due to a pending due payment. '
                          'Please clear your due to regain full access.',
                      style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF1F2937)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _tile(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Pay Due (Wallet)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WalletPage(
                      userRole: isRider
                          ? WalletUserRole.rider
                          : WalletUserRole.passenger,
                    ),
                  ),
                );
              },
            ),
            _tile(
              context,
              icon: Icons.person,
              title: 'Personal Info',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PersonalInformationPage()),
                );
              },
            ),
            _tile(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    isRider ? const RiderSettingsPage() : const SettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF14B8A6)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }
}