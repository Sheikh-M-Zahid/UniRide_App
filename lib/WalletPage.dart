import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'NotificationsPage.dart';
import 'services/auth_api_service.dart';

enum WalletUserRole {
  passenger,
  rider,
}

class WalletPage extends StatefulWidget {
  final WalletUserRole userRole;
  final double dueAmount;
  final int activePromotionsCount;

  const WalletPage({
    super.key,
    required this.userRole,
    this.dueAmount = 20.0,
    this.activePromotionsCount = 0,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  static const String bkashNumber = '01962857678';
  static const String nagadNumber = '01962857678';

  late double dueAmount;
  late int activePromotionsCount;
  bool isLoading = true;
  final AuthApiService _authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    dueAmount = widget.dueAmount;
    activePromotionsCount = widget.activePromotionsCount;
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      final response = await _authApiService.getWalletSummary();
      final data = response['data'] ?? {};

      if (!mounted) return;

      setState(() {
        dueAmount = (data['dueAmount'] ?? 0).toDouble();
        activePromotionsCount = (data['activePromotionsCount'] ?? 0).toInt();
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

  UserRole _mapToNotificationRole() {
    switch (widget.userRole) {
      case WalletUserRole.passenger:
        return UserRole.passenger;
      case WalletUserRole.rider:
        return UserRole.rider;
    }
  }

  Future<void> _handleDueTap() async {
    if (dueAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No due payment found'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final bool? submitted = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DuePaymentPage(
          dueAmount: dueAmount,
          bkashNumber: bkashNumber,
          nagadNumber: nagadNumber,
          authApiService: _authApiService,
        ),
      ),
    );

    if (submitted == true && mounted) {
      await _loadWalletData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment request has been submitted. Please note that verification cannot be completed without a valid Transaction ID.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _paymentMethodCard({
    required String title,
    required String number,
    required Color badgeColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _paymentMethodCard(
            title: 'bKash',
            number: bkashNumber,
            badgeColor: const Color(0xFFFCE7F3),
            textColor: const Color(0xFFE2136E),
          ),
          _paymentMethodCard(
            title: 'Nagad',
            number: nagadNumber,
            badgeColor: const Color(0xFFFFF1E6),
            textColor: const Color(0xFFFF7A00),
          ),
          const SizedBox(height: 4),
          const Text(
            'Currently, our available payment methods are bKash and Nagad. If you have any due payments, please tap on “Due Payment” and complete the payment promptly. Otherwise, your account may be suspended.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    String? trailingText,
    String? subtitle,
    required VoidCallback onTap,
    bool showTopBorder = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: showTopBorder
                ? const BorderSide(color: Color(0xFFE5E7EB))
                : BorderSide.none,
            bottom: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 24,
              color: Color(0xFF14B8A6),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  trailingText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dueCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _handleDueTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UniRide Due',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'BDT ${dueAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dueAmount > 0
                        ? 'Tap to pay your due'
                        : 'No due payment pending',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              dueAmount > 0
                  ? Icons.arrow_forward_ios
                  : Icons.check_circle_outline,
              color: dueAmount > 0
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF14B8A6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wallet',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF14B8A6),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadWalletData,
        color: const Color(0xFF14B8A6),
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        child: ListView(
          children: [
            _dueCard(),
          _sectionTitle('Payment methods'),
          _paymentMethodSection(),
          _sectionTitle('Promotions'),
          _menuTile(
            icon: Icons.local_offer_outlined,
            title: 'Promotions',
            trailingText: '$activePromotionsCount',
            showTopBorder: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsPage(
                    userRole: _mapToNotificationRole(),
                  ),
                ),
              );
            },
          ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class DuePaymentPage extends StatefulWidget {
  final double dueAmount;
  final String bkashNumber;
  final String nagadNumber;
  final AuthApiService authApiService;

  const DuePaymentPage({
    super.key,
    required this.dueAmount,
    required this.bkashNumber,
    required this.nagadNumber,
    required this.authApiService,
  });

  @override
  State<DuePaymentPage> createState() => _DuePaymentPageState();
}

class _DuePaymentPageState extends State<DuePaymentPage> {
  final TextEditingController transactionIdController = TextEditingController();
  String selectedMethod = 'bKash';
  bool isSubmitting = false;

  @override
  void dispose() {
    transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _openPaymentApp({
    required String appScheme,
    required String appName,
    required String number,
  }) async {
    final Uri uri = Uri.parse(appScheme);

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await Clipboard.setData(ClipboardData(text: number));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$appName The app could not be opened. The number has been copied: $number',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: number));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$appName The app could not be opened. The number has been copied: $number',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmPayment() async {
    final String transactionId = transactionIdController.text.trim();

    if (transactionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must provide the Transaction ID.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await widget.authApiService.payDue(
        method: selectedMethod,
        referenceId: transactionId,
        amount: widget.dueAmount,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _methodCard({
    required String title,
    required String number,
    required Color badgeColor,
    required Color textColor,
    required bool selected,
    required VoidCallback onTap,
    required VoidCallback onLogoTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF14B8A6) : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onLogoTap,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'When the logo is tapped, the app will attempt to open.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color:
              selected ? const Color(0xFF14B8A6) : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Due Payment',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment by:',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Due Amount: BDT ${widget.dueAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _methodCard(
                      title: 'bKash',
                      number: widget.bkashNumber,
                      badgeColor: const Color(0xFFFCE7F3),
                      textColor: const Color(0xFFE2136E),
                      selected: selectedMethod == 'bKash',
                      onTap: () {
                        setState(() {
                          selectedMethod = 'bKash';
                        });
                      },
                      onLogoTap: () {
                        _openPaymentApp(
                          appScheme: 'bkash://',
                          appName: 'bKash',
                          number: widget.bkashNumber,
                        );
                      },
                    ),
                    _methodCard(
                      title: 'Nagad',
                      number: widget.nagadNumber,
                      badgeColor: const Color(0xFFFFF1E6),
                      textColor: const Color(0xFFFF7A00),
                      selected: selectedMethod == 'Nagad',
                      onTap: () {
                        setState(() {
                          selectedMethod = 'Nagad';
                        });
                      },
                      onLogoTap: () {
                        _openPaymentApp(
                          appScheme: 'nagad://',
                          appName: 'Nagad',
                          number: widget.nagadNumber,
                        );
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Warning: If the Transaction ID is not provided, the payment will not be successful and will not be credited to your account.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: transactionIdController,
                      decoration: InputDecoration(
                        labelText: 'Transaction ID',
                        hintText: 'Enter your transaction ID',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF14B8A6),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _confirmPayment,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF14B8A6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}