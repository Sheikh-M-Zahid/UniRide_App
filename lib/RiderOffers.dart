import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color card = Colors.white;
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
}

class RiderOffersPage extends StatefulWidget {
  const RiderOffersPage({super.key});

  @override
  State<RiderOffersPage> createState() => _RiderOffersPageState();
}

class _RiderOffersPageState extends State<RiderOffersPage> {
  final AuthApiService _api = AuthApiService();

  bool isLoading = true;
  List<Map<String, dynamic>> offers = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _api.getRiderOffers();
      final List rawList = response['data'] ?? [];

      if (!mounted) return;

      setState(() {
        offers = rawList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'N/A';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
    } catch (_) {
      return rawDate.toString();
    }
  }

  String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }

  bool _isActive(Map<String, dynamic> offer) {
    try {
      final end = DateTime.parse(offer['end_date'].toString()).toLocal();
      return DateTime.now().isBefore(end);
    } catch (_) {
      return true;
    }
  }

  Color _statusColor(Map<String, dynamic> offer) {
    return _isActive(offer) ? AppColors.success : AppColors.mutedText;
  }

  String _statusLabel(Map<String, dynamic> offer) {
    return _isActive(offer) ? 'Active' : 'Expired';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Offers',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadOffers,
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        )
            : errorMessage != null
            ? _ErrorView(
          message: errorMessage!,
          onRetry: _loadOffers,
        )
            : offers.isEmpty
            ? _EmptyView()
            : _OffersList(
          offers: offers,
          formatDate: _formatDate,
          isActive: _isActive,
          statusColor: _statusColor,
          statusLabel: _statusLabel,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Offers List
// ─────────────────────────────────────────
class _OffersList extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final String Function(dynamic) formatDate;
  final bool Function(Map<String, dynamic>) isActive;
  final Color Function(Map<String, dynamic>) statusColor;
  final String Function(Map<String, dynamic>) statusLabel;

  const _OffersList({
    required this.offers,
    required this.formatDate,
    required this.isActive,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Header banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Offers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${offers.where((o) => isActive(o)).length} active offer(s)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        ...offers.map((offer) => _OfferCard(
          offer: offer,
          formatDate: formatDate,
          active: isActive(offer),
          statusColor: statusColor(offer),
          statusLabel: statusLabel(offer),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Single Offer Card
// ─────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final String Function(dynamic) formatDate;
  final bool active;
  final Color statusColor;
  final String statusLabel;

  const _OfferCard({
    required this.offer,
    required this.formatDate,
    required this.active,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final name = offer['offer_name']?.toString() ?? 'Offer';
    final type = offer['offer_type']?.toString() ?? '';
    final promo = offer['promo_code']?.toString() ?? '';
    final reward = offer['reward_percentage']?.toString() ?? '0';
    final eligible = offer['eligible_user']?.toString() ?? '';
    final conditions = offer['conditions']?.toString() ?? 'N/A';
    final startDate = formatDate(offer['start_date']);
    final endDate = formatDate(offer['end_date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? AppColors.primary.withOpacity(0.25)
              : AppColors.border,
        ),
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
          // Top colored header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : const LinearGradient(
                colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Promo code highlight
                if (promo.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Promo Code: ',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          promo,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Type',
                  value: type,
                ),
                _DetailRow(
                  icon: Icons.percent,
                  label: 'Discount',
                  value: '$reward%',
                ),
                _DetailRow(
                  icon: Icons.people_outline,
                  label: 'Eligible For',
                  value: eligible.isNotEmpty
                      ? eligible[0].toUpperCase() + eligible.substring(1)
                      : 'All',
                ),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Valid From',
                  value: startDate,
                ),
                _DetailRow(
                  icon: Icons.event_busy_outlined,
                  label: 'Valid Until',
                  value: endDate,
                  valueColor: active ? AppColors.success : AppColors.danger,
                ),
                const Divider(height: 20, color: AppColors.border),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.mutedText,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        conditions,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mutedText),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: AppColors.mutedText),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Empty / Error Views
// ─────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 64,
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'No offers available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Check back later for exciting offers.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: AppColors.danger),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}