import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/auth_api_service.dart';
import 'services/socket_service.dart';

class RiderDeliveryPage extends StatefulWidget {
  const RiderDeliveryPage({super.key});

  @override
  State<RiderDeliveryPage> createState() => _RiderDeliveryPageState();
}

class _RiderDeliveryPageState extends State<RiderDeliveryPage> {
  final AuthApiService _authApiService = AuthApiService();

  List<Map<String, dynamic>> deliveryRequests = [];
  Map<String, dynamic>? activeDelivery;

  double todayDeliveryEarnings = 0;
  double weekDeliveryEarnings = 0;

  bool isLoading = true;
  bool isActionLoading = false;

  Future<void> _acceptDelivery(int index) async {
    if (isActionLoading) return;

    final request = deliveryRequests[index];
    final requestId =
    (request['deliveryId'] ?? request['id'] ?? '').toString();

    if (requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request ID not found"),
        ),
      );
      return;
    }

    setState(() {
      isActionLoading = true;
    });

    try {
      await _authApiService.acceptDeliveryRequest(requestId: requestId);
      await _loadDeliveryDashboard();

      if (!mounted) return;

      setState(() {
        isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delivery request accepted"),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _rejectDelivery(int index) async {
    if (isActionLoading) return;

    final request = deliveryRequests[index];
    final requestId =
    (request['deliveryId'] ?? request['id'] ?? '').toString();

    if (requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request ID not found"),
        ),
      );
      return;
    }

    setState(() {
      isActionLoading = true;
    });

    try {
      await _authApiService.rejectDeliveryRequest(requestId: requestId);
      await _loadDeliveryDashboard();

      if (!mounted) return;

      setState(() {
        isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delivery request rejected"),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _markAsPickedUp() async {
    if (isActionLoading || activeDelivery == null) return;

    final deliveryId =
    (activeDelivery!['deliveryId'] ?? activeDelivery!['id'] ?? '').toString();

    if (deliveryId.isEmpty) return;

    setState(() => isActionLoading = true);

    try {
      await _authApiService.markDeliveryAsPickedUp(deliveryId: deliveryId);

      if (!mounted) return;

      // সাথে সাথে local state update
      setState(() {
        activeDelivery = {
          ...activeDelivery!,
          'status': 'picked_up',
        };
        isActionLoading = false;
      });

      // Background এ fresh data load
      _loadDeliveryDashboard();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marked as picked up")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _markAsDelivered() async {
    if (isActionLoading || activeDelivery == null) return;

    final deliveryId =
    (activeDelivery!['deliveryId'] ?? activeDelivery!['id'] ?? '')
        .toString();

    if (deliveryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Delivery ID not found")),
      );
      return;
    }

    // Step 1: OTP পাঠাও
    setState(() => isActionLoading = true);

    try {
      await _authApiService.sendDeliveryOtp(deliveryId: deliveryId);

      if (!mounted) return;
      setState(() => isActionLoading = false);

      // Step 2: OTP input dialog দেখাও
      _showOtpDialog(deliveryId);
    } catch (e) {
      if (!mounted) return;
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showOtpDialog(String deliveryId) {
    final otpController = TextEditingController();
    int secondsLeft = 150; // ২.৫ মিনিট
    bool isVerifying = false;
    bool canResend = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Countdown timer
            Future.delayed(const Duration(seconds: 1), () {
              if (!dialogContext.mounted) return;
              if (secondsLeft > 0) {
                setDialogState(() => secondsLeft--);
                if (secondsLeft == 0) {
                  setDialogState(() => canResend = true);
                }
              }
            });

            // Recursive countdown
            void startCountdown() {
              Future.doWhile(() async {
                await Future.delayed(const Duration(seconds: 1));
                if (!dialogContext.mounted) return false;
                if (secondsLeft <= 0) return false;
                setDialogState(() {
                  secondsLeft--;
                  if (secondsLeft == 0) canResend = true;
                });
                return secondsLeft > 0;
              });
            }

            if (secondsLeft == 149) startCountdown(); // একবারই চালু করো

            final minutes = secondsLeft ~/ 60;
            final seconds = secondsLeft % 60;
            final timeStr =
                '$minutes:${seconds.toString().padLeft(2, '0')}';

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Enter Delivery OTP",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "An OTP has been sent to the receiver's email. Ask the receiver for the OTP to confirm delivery.",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Color(0xFF0F766E),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '______',
                      hintStyle: TextStyle(
                        letterSpacing: 8,
                        color: Colors.grey.shade300,
                        fontSize: 28,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF14B8A6),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF14B8A6),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (secondsLeft > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "OTP expires in $timeStr",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      "OTP expired!",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (canResend) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: isVerifying
                          ? null
                          : () async {
                        setDialogState(() {
                          isVerifying = true;
                          canResend = false;
                        });
                        try {
                          await _authApiService.sendDeliveryOtp(
                              deliveryId: deliveryId);
                          setDialogState(() {
                            secondsLeft = 150;
                            isVerifying = false;
                            otpController.clear();
                          });
                          startCountdown();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("New OTP sent!")),
                          );
                        } catch (e) {
                          setDialogState(() => isVerifying = false);
                        }
                      },
                      icon: const Icon(Icons.refresh,
                          color: Color(0xFF14B8A6)),
                      label: const Text(
                        "Resend OTP",
                        style: TextStyle(color: Color(0xFF14B8A6)),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: (isVerifying || secondsLeft == 0)
                      ? null
                      : () async {
                    final otp = otpController.text.trim();
                    if (otp.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please enter 6-digit OTP")),
                      );
                      return;
                    }

                    setDialogState(() => isVerifying = true);

                    try {
                      await _authApiService.markDeliveryAsDelivered(
                        deliveryId: deliveryId,
                        otp: otp,
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();

                      if (!mounted) return;
                      setState(() => activeDelivery = null);
                      _loadDeliveryDashboard();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Delivery confirmed successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      setDialogState(() => isVerifying = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e
                              .toString()
                              .replaceFirst('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDeliveryDashboard();
    _listenToSocketEvents();
  }

  String _formatMoney(dynamic value) {
    final num amount = (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    return "৳${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}";
  }

  String _formatDistance(dynamic value) {
    final num distance = (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    return "${distance.toStringAsFixed(distance % 1 == 0 ? 0 : 1)} km";
  }

  String _formatMinutes(dynamic value) {
    final num minutes = (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    return "${minutes.toStringAsFixed(0)} min";
  }

  String _formatStatus(dynamic value) {
    final raw = (value ?? '').toString().toLowerCase();

    switch (raw) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'on_the_way':
        return 'On the way';
      case 'delivered':
        return 'Delivered';
      default:
        return raw.isEmpty ? 'Unknown' : raw;
    }
  }

  void _listenToSocketEvents() {
    // যখন কোনো রাইডার একটা request accept করে,
    // বাকি রাইডারদের list থেকে সেই request সরে যাবে
    SocketService.on('send_item:request_taken', (data) {
      if (!mounted) return;

      final takenId = (data['s_id'] ?? '').toString();
      final riderName = (data['rider_name'] ?? 'Another rider').toString();

      if (takenId.isEmpty) return;

      setState(() {
        deliveryRequests.removeWhere(
              (req) =>
          (req['deliveryId'] ?? req['id'] ?? '').toString() == takenId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$riderName has already accepted this delivery request.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    // নতুন delivery request আসলে real-time এ list এ যোগ হবে
    SocketService.on('send_item:new_request', (data) {
      if (!mounted) return;

      final newRequest = Map<String, dynamic>.from(data);

      // আগে থেকে আছে কিনা চেক করো (duplicate এড়াতে)
      final alreadyExists = deliveryRequests.any(
            (req) =>
        (req['deliveryId'] ?? req['id'] ?? '').toString() ==
            (newRequest['s_id'] ?? '').toString(),
      );

      if (!alreadyExists) {
        setState(() {
          deliveryRequests.insert(0, {
            'deliveryId': newRequest['s_id'],
            'id': newRequest['s_id'],
            'item': newRequest['item_type'] ?? '',
            'pickup': newRequest['pickup_location'] ?? '',
            'drop': newRequest['drop_location'] ?? '',
            'fee': newRequest['delivery_fee'] ?? 0,
            'senderName': newRequest['sender_name'] ?? '',
            'senderPhone': newRequest['sender_phone'] ?? '',
            'receiverName': newRequest['receiver_name'] ?? '',
            'receiverPhone': '',
            'distance': 0,
            'time': 0,
            'status': 'pending',
          });
        });
      }
    });
  }

  Future<void> _loadDeliveryDashboard() async {
    try {
      final response = await _authApiService.getRiderDeliveryDashboard();
      final data = response['data'] ?? {};

      if (!mounted) return;

      setState(() {
        todayDeliveryEarnings =
            (data['todayDeliveryEarnings'] as num?)?.toDouble() ?? 0;
        weekDeliveryEarnings =
            (data['weekDeliveryEarnings'] as num?)?.toDouble() ?? 0;
        activeDelivery = data['activeDelivery'] != null
            ? Map<String, dynamic>.from(data['activeDelivery'])
            : null;
        deliveryRequests = data['deliveryRequests'] is List
            ? List<Map<String, dynamic>>.from(data['deliveryRequests'])
            : [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _callPerson(String name, String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open dial pad for $name"),
        ),
      );
    }
  }

  @override
  void dispose() {
    SocketService.off('send_item:request_taken');
    SocketService.off('send_item:new_request');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Delivery Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF14B8A6),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Delivery Earnings
            Row(
              children: [
                Expanded(
                  child: _EarningCard(
                    title: "Today Delivery",
                    value: _formatMoney(todayDeliveryEarnings),
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EarningCard(
                    title: "This Week",
                    value: _formatMoney(weekDeliveryEarnings),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// Active Delivery
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: activeDelivery == null
                  ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Active Delivery",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No active delivery right now",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Active Delivery",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: "Item",
                    value: activeDelivery!["item"],
                  ),
                  _SummaryRow(
                    label: "Pickup",
                    value: activeDelivery!["pickup"],
                  ),
                  _SummaryRow(
                    label: "Drop",
                    value: activeDelivery!["drop"],
                  ),
                  _SummaryRow(
                    label: "Fee",
                    value: _formatMoney(activeDelivery!["fee"]),
                  ),
                  _SummaryRow(
                    label: "Status",
                    value: _formatStatus(activeDelivery!["status"]),
                  ),
                  _SummaryRow(
                    label: "Sender",
                    value: activeDelivery!["senderName"] ?? "",
                  ),
                  _SummaryRow(
                    label: "Receiver",
                    value: activeDelivery!["receiverName"] ?? "",
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isActionLoading ? null : _markAsDelivered,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Mark as Delivered"),
                    ),
                  ),
                  if ((activeDelivery!["status"] ?? '').toString().toLowerCase() == 'accepted')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isActionLoading ? null : _markAsPickedUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("Mark as Picked Up"),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// Contact Option
            if (activeDelivery != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contact Option",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 14),

                    /// Sender
                    _ContactCard(
                      title: "Sender",
                      name: activeDelivery!["senderName"],
                      phone: activeDelivery!["senderPhone"],
                      onCall: () => _callPerson(
                        activeDelivery!["senderName"],
                        activeDelivery!["senderPhone"],
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// Receiver
                    _ContactCard(
                      title: "Receiver",
                      name: activeDelivery!["receiverName"],
                      phone: activeDelivery!["receiverPhone"],
                      onCall: () => _callPerson(
                        activeDelivery!["receiverName"],
                        activeDelivery!["receiverPhone"],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            /// Delivery Requests
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Delivery Requests",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (deliveryRequests.isEmpty)
                    const Text(
                      "No delivery requests available",
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    ...List.generate(
                      deliveryRequests.length,
                          (index) {
                        final request = deliveryRequests[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SummaryRow(
                                label: "Item",
                                value: request["item"],
                              ),
                              _SummaryRow(
                                label: "Pickup",
                                value: request["pickup"],
                              ),
                              _SummaryRow(
                                label: "Drop",
                                value: request["drop"],
                              ),
                              _SummaryRow(
                                label: "Distance",
                                value: _formatDistance(request["distance"]),
                              ),
                              _SummaryRow(
                                label: "Time",
                                value: _formatMinutes(request["time"]),
                              ),
                              _SummaryRow(
                                label: "Fee",
                                value: _formatMoney(request["fee"]),
                              ),
                              _SummaryRow(
                                label: "Sender",
                                value: request["senderName"],
                              ),
                              _SummaryRow(
                                label: "Receiver",
                                value: request["receiverName"],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: isActionLoading
                                          ? null
                                          : () => _rejectDelivery(index),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text("Reject"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: isActionLoading
                                          ? null
                                          : () => _acceptDelivery(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFF14B8A6),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text("Accept"),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _EarningCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F766E), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String title;
  final String name;
  final String phone;
  final VoidCallback onCall;

  const _ContactCard({
    required this.title,
    required this.name,
    required this.phone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE6FFFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call, size: 18),
            label: const Text("Call"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}