import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

enum PaymentStatus {
  pending,
  confirmed,
  declined,
}

class PaymentRequestModel {
  final String paymentDbId;
  final DateTime dateTime;
  final String userName;
  final String userType; // Passenger / Rider
  final String paymentMethod; // bKash / Nagad
  final String transactionId;
  final double amount;
  PaymentStatus status;
  String? actionAdminName;

  PaymentRequestModel({
    required this.paymentDbId,
    required this.dateTime,
    required this.userName,
    required this.userType,
    required this.paymentMethod,
    required this.transactionId,
    required this.amount,
    required this.status,
    this.actionAdminName,
  });
}

class AdminPaymentApproval extends StatefulWidget {
  const AdminPaymentApproval({super.key});

  @override
  State<AdminPaymentApproval> createState() =>
      _AdminPaymentApprovalState();
}

class _AdminPaymentApprovalState extends State<AdminPaymentApproval> {

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'All';

  final AuthApiService _authApiService = AuthApiService();

  List<PaymentRequestModel> _allPayments = [];

  bool isLoading = true;
  bool isActionLoading = false;
  String? errorMessage;

  int pendingCount = 0;
  int confirmedCount = 0;
  int declinedCount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPayments() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final data = await _authApiService.getPaymentRequests();

      final summary = data['data']['summary'];
      final items = data['data']['items'] as List;

      setState(() {
        pendingCount = summary['pending'] ?? 0;
        confirmedCount = summary['confirmed'] ?? 0;
        declinedCount = summary['declined'] ?? 0;

        _allPayments = items.map((item) {
          return PaymentRequestModel(
            paymentDbId: item['paymentDbId'],
            dateTime: DateTime.parse(item['dateTime']),
            userName: item['userName'] ?? '',
            userType: item['userType'] ?? '',
            paymentMethod: item['paymentMethod'] ?? '',
            transactionId: item['transactionId'] ?? '',
            amount: (item['amount'] as num).toDouble(),
            status: item['status'] == 'confirmed'
                ? PaymentStatus.confirmed
                : item['status'] == 'declined'
                ? PaymentStatus.declined
                : PaymentStatus.pending,
            actionAdminName: item['actionAdminName'],
          );
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<PaymentRequestModel> get _filteredPayments {
    final query = _searchController.text.trim().toLowerCase();

    List<PaymentRequestModel> list = _allPayments.where((payment) {
      final matchesSearch =
      payment.transactionId.toLowerCase().contains(query);

      final matchesFilter = switch (selectedFilter) {
        'Pending' => payment.status == PaymentStatus.pending,
        'Confirmed' => payment.status == PaymentStatus.confirmed,
        'Declined' => payment.status == PaymentStatus.declined,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    list.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // newest first
    return list;
  }

  Future<void> _confirmPayment(PaymentRequestModel payment) async {
    setState(() => isActionLoading = true);
    try {
      await _authApiService.confirmPayment(paymentDbId: payment.paymentDbId);
      setState(() {
        payment.status = PaymentStatus.confirmed;
        confirmedCount++;
        pendingCount = (pendingCount - 1).clamp(0, pendingCount);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => isActionLoading = false);
    }
  }

  Future<void> _declinePayment(PaymentRequestModel payment) async {
    setState(() => isActionLoading = true);
    try {
      await _authApiService.declinePayment(paymentDbId: payment.paymentDbId);
      setState(() {
        payment.status = PaymentStatus.declined;
        declinedCount++;
        pendingCount = (pendingCount - 1).clamp(0, pendingCount);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment declined successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => isActionLoading = false);
    }
  }
  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();

    int hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$day/$month/$year  $hour:$minute $amPm';
  }

  Color _statusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return const Color(0xFFF59E0B);
      case PaymentStatus.confirmed:
        return const Color(0xFF14B8A6);
      case PaymentStatus.declined:
        return const Color(0xFFEF4444);
    }
  }

  String _statusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.confirmed:
        return 'Confirmed';
      case PaymentStatus.declined:
        return 'Declined';
    }
  }

  Widget _summaryCard({
    required String title,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF14B8A6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF14B8A6)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _paymentCard(PaymentRequestModel payment) {
    final statusColor = _statusColor(payment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  payment.userName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(payment.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _infoRow('Date & Time', _formatDateTime(payment.dateTime)),
          _infoRow('Role', payment.userType),
          _infoRow('Payment Method', payment.paymentMethod),
          _infoRow('Transaction ID', payment.transactionId),
          _infoRow(
            'Action By',
            payment.actionAdminName ?? 'Not yet processed',
          ),

          const SizedBox(height: 14),

          if (payment.status == PaymentStatus.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isActionLoading ? null : () => _declinePayment(payment),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isActionLoading ? null : () => _confirmPayment(payment),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF14B8A6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
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
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payments = _filteredPayments;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          'Payment Requests',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                _summaryCard(
                  title: 'Pending',
                  value: pendingCount,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  title: 'Confirmed',
                  value: confirmedCount,
                  color: const Color(0xFF14B8A6),
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  title: 'Declined',
                  value: declinedCount,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by transaction ID',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF14B8A6),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('All'),
                _filterChip('Pending'),
                _filterChip('Confirmed'),
                _filterChip('Declined'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: payments.isEmpty
                ? const Center(
              child: Text(
                'No payment request found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                return _paymentCard(payments[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}