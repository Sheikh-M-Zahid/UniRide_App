import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/auth_api_service.dart';

class SendItemTrackingPage extends StatefulWidget {
  final String sId;

  const SendItemTrackingPage({super.key, required this.sId});

  @override
  State<SendItemTrackingPage> createState() => _SendItemTrackingPageState();
}

class _SendItemTrackingPageState extends State<SendItemTrackingPage> {
  final AuthApiService _api = AuthApiService();

  Map<String, dynamic>? itemData;
  bool isLoading = true;
  bool isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final response = await _api.getSendItemDetails(sId: widget.sId);
      final data = response['data'];

      if (!mounted) return;

      setState(() {
        itemData = data != null ? Map<String, dynamic>.from(data) : null;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _cancelItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Delivery?'),
        content: const Text(
            'Are you sure you want to cancel this delivery request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isCancelling = true);

    try {
      await _api.cancelSendItem(sId: widget.sId);
      await _loadDetails();

      if (!mounted) return;
      setState(() => isCancelling = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery request cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _callRider() async {
    final phone = (itemData?['rider_phone'] ?? '').toString();
    if (phone.isEmpty) return;

    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'accepted':
        return const Color(0xFF0EA5E9);
      case 'picked_up':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'picked_up':
        return 'Picked Up';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// 4-step progress tracker
  int _stepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'accepted':
        return 1;
      case 'picked_up':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  bool get _canCancel {
    final s = (itemData?['status'] ?? '').toString().toLowerCase();
    return s == 'pending' || s == 'accepted';
  }

  bool get _hasRider {
    return (itemData?['rider_id'] ?? '').toString().isNotEmpty;
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
          'Track Delivery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
      )
          : itemData == null
          ? const Center(child: Text('Item not found'))
          : RefreshIndicator(
        color: const Color(0xFF14B8A6),
        onRefresh: _loadDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// Status Banner
              _StatusBanner(
                status:
                (itemData!['status'] ?? '').toString(),
                statusLabel: _statusLabel(
                    (itemData!['status'] ?? '').toString()),
                statusColor: _statusColor(
                    (itemData!['status'] ?? '').toString()),
              ),

              const SizedBox(height: 16),

              /// Progress Tracker (only if not cancelled)
              if ((itemData!['status'] ?? '')
                  .toString()
                  .toLowerCase() !=
                  'cancelled')
                _ProgressTracker(
                  currentStep: _stepIndex(
                      (itemData!['status'] ?? '').toString()),
                ),

              const SizedBox(height: 16),

              /// Item Details Card
              _SectionCard(
                title: 'Item Details',
                icon: Icons.inventory_2_outlined,
                children: [
                  _DetailRow(
                      label: 'Item',
                      value: (itemData!['item_type'] ?? '—')
                          .toString()),
                  _DetailRow(
                      label: 'Weight',
                      value:
                      '${itemData!['item_weight'] ?? '—'} kg'),
                  _DetailRow(
                      label: 'Fee',
                      value:
                      '৳${itemData!['delivery_fee'] ?? 0}'),
                ],
              ),

              const SizedBox(height: 14),

              /// Location Card
              _SectionCard(
                title: 'Locations',
                icon: Icons.map_outlined,
                children: [
                  _DetailRow(
                    label: 'Pickup',
                    value:
                    (itemData!['pickup_location'] ?? '—')
                        .toString(),
                    valueColor: const Color(0xFF0F766E),
                  ),
                  _DetailRow(
                    label: 'Drop',
                    value:
                    (itemData!['drop_location'] ?? '—')
                        .toString(),
                    valueColor: const Color(0xFFDC2626),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// Receiver Card
              _SectionCard(
                title: 'Receiver',
                icon: Icons.person_outline,
                children: [
                  _DetailRow(
                      label: 'Name',
                      value:
                      (itemData!['receiver_name'] ?? '—')
                          .toString()),
                  _DetailRow(
                      label: 'Email',
                      value:
                      (itemData!['receiver_email'] ?? '—')
                          .toString()),
                ],
              ),

              /// Rider Card (only if rider assigned)
              if (_hasRider) ...[
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Assigned Rider',
                  icon: Icons.directions_bike_outlined,
                  children: [
                    _DetailRow(
                        label: 'Name',
                        value:
                        (itemData!['rider_name'] ?? '—')
                            .toString()),
                    _DetailRow(
                        label: 'Phone',
                        value:
                        (itemData!['rider_phone'] ?? '—')
                            .toString()),
                  ],
                ),

                const SizedBox(height: 14),

                /// Call Rider Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _callRider,
                    icon: const Icon(Icons.call),
                    label: const Text('Call Rider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],

              /// Cancel Button
              if (_canCancel) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isCancelling ? null : _cancelItem,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(
                          color: Color(0xFFDC2626)),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isCancelling
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFDC2626),
                      ),
                    )
                        : const Text('Cancel Delivery Request'),
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────── Sub-widgets ─────────────────────────── */

class _StatusBanner extends StatelessWidget {
  final String status;
  final String statusLabel;
  final Color statusColor;

  const _StatusBanner({
    required this.status,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping_outlined,
                color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Status',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressTracker extends StatelessWidget {
  final int currentStep; // 0=pending, 1=accepted, 2=picked_up, 3=delivered

  const _ProgressTracker({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'label': 'Pending', 'icon': Icons.hourglass_empty_rounded},
      {'label': 'Accepted', 'icon': Icons.check_circle_outline},
      {'label': 'Picked Up', 'icon': Icons.directions_bike_outlined},
      {'label': 'Delivered', 'icon': Icons.done_all_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isDone = i <= currentStep;
          final isLast = i == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF14B8A6)
                              : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFF14B8A6)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: Icon(
                          steps[i]['icon'] as IconData,
                          size: 17,
                          color: isDone
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i]['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isDone
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isDone
                              ? const Color(0xFF14B8A6)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: i < currentStep
                          ? const Color(0xFF14B8A6)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}