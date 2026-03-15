import 'package:flutter/material.dart';
import 'UserOffer.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class WalletPage extends StatefulWidget {
  final double dueAmount;
  final int activePromotionsCount;
  final String? bkashNumber;

  const WalletPage({
    super.key,
    this.dueAmount = 0.0,
    this.activePromotionsCount = 0,
    this.bkashNumber,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late double dueAmount;
  late int activePromotionsCount;

  String? bkashNumber;
  bool isBkashAdded = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    dueAmount = widget.dueAmount;
    activePromotionsCount = widget.activePromotionsCount;
    bkashNumber = widget.bkashNumber;
    isBkashAdded = bkashNumber != null && bkashNumber!.trim().isNotEmpty;
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      // TODO:
      // এখানে backend / firebase / api call বসাবে
      // final data = await WalletService.getWalletData();
      //
      // setState(() {
      //   dueAmount = (data['dueAmount'] ?? 0).toDouble();
      //   bkashNumber = data['bkashNumber'];
      //   isBkashAdded = bkashNumber != null && bkashNumber!.trim().isNotEmpty;
      //   activePromotionsCount = data['activePromotionsCount'] ?? 0;
      // });

      await Future.delayed(const Duration(milliseconds: 250));
    } catch (_) {
      // চাইলে এখানে error handle করতে পারো
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _handleDueTap() async {
    if (dueAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No due payment found'),
        ),
      );
      return;
    }

    if (!isBkashAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your bKash number first'),
        ),
      );
      await _showBkashSetupDialog();
      return;
    }

    await _showDuePaymentDialog();
  }

  Future<void> _showDuePaymentDialog() async {
    final bool? shouldPay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Pay Due',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'You have a due of BDT ${dueAmount.toStringAsFixed(2)}.\n\nPay now using bKash (${_maskedBkashNumber()})?',
            style: const TextStyle(
              color: AppColors.text,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.mutedText),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (shouldPay == true) {
      await _processDuePayment();
    }
  }

  Future<void> _processDuePayment() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        );
      },
    );

    try {
      await Future.delayed(const Duration(seconds: 2));

      // TODO:
      // এখানে actual payment API call বসবে
      // await WalletService.payDueWithBkash(
      //   amount: dueAmount,
      //   bkashNumber: bkashNumber!,
      // );

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        dueAmount = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment completed successfully'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again'),
        ),
      );
    }
  }

  String _maskedBkashNumber() {
    if (bkashNumber == null || bkashNumber!.length < 11) {
      return bkashNumber ?? '';
    }

    final String number = bkashNumber!;
    return '${number.substring(0, 5)}******';
  }

  Future<void> _showBkashSetupDialog() async {
    final TextEditingController numberController = TextEditingController(
      text: bkashNumber ?? '',
    );
    final TextEditingController pinController = TextEditingController();

    bool obscurePin = true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Add bKash',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: numberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'bKash Number',
                        hintText: '01XXXXXXXXX',
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: pinController,
                      obscureText: obscurePin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'bKash PIN',
                        hintText: 'Enter PIN',
                        filled: true,
                        fillColor: AppColors.inputFill,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscurePin = !obscurePin;
                            });
                          },
                          icon: Icon(
                            obscurePin
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.mutedText,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String number = numberController.text.trim();
                    final String pin = pinController.text.trim();

                    if (!_isValidBkashNumber(number)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid bKash number'),
                        ),
                      );
                      return;
                    }

                    if (!_isValidPin(pin)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PIN must be 4 to 6 digits'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);
                    await _saveBkashMethod(number: number, pin: pin);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isValidBkashNumber(String number) {
    return number.length == 11 && number.startsWith('01');
  }

  bool _isValidPin(String pin) {
    final RegExp regex = RegExp(r'^[0-9]{4,6}$');
    return regex.hasMatch(pin);
  }

  Future<void> _saveBkashMethod({
    required String number,
    required String pin,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        );
      },
    );

    try {
      await Future.delayed(const Duration(seconds: 2));

      // TODO:
      // এখানে actual backend / bKash verification হবে
      // PIN backend এ verify করবে, plain text আকারে save করবে না
      //
      // await WalletService.addBkashMethod(
      //   number: number,
      //   pin: pin,
      // );

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        bkashNumber = number;
        isBkashAdded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('bKash account added successfully'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add bKash account'),
        ),
      );
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
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
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
            bottom: const BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.primary,
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
                      color: AppColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
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
                    color: AppColors.text,
                  ),
                ),
              ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _showBkashSetupDialog,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFE2136E),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: isBkashAdded
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'bKash',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskedBkashNumber(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                )
                    : const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add bKash',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Set your bKash number and PIN',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.mutedText,
              ),
            ],
          ),
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
          border: Border.all(color: AppColors.border),
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
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'BDT ${dueAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dueAmount > 0
                        ? 'Tap to pay your due'
                        : 'No due payment pending',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
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
                  ? AppColors.mutedText
                  : AppColors.primary,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.text,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wallet',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      )
          : ListView(
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
                  builder: (context) => const OffersPage(),
                ),
              );
            },
          ),

          _sectionTitle('In-Store Offers'),
          _menuTile(
            icon: Icons.confirmation_number_outlined,
            title: 'Offers',
            trailingText: activePromotionsCount == 0 ? '0' : null,
            showTopBorder: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OffersPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}