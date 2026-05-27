import 'package:flutter/material.dart';
import 'UserProfile.dart';
import 'UserHome.dart';
import 'UserActivity.dart';
import 'UserServices.dart';
import 'services/auth_api_service.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
}

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final TextEditingController _offerController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  bool isLoading = true;
  List<Map<String, dynamic>> offers = [];
  String? errorMessage;
  String selectedFilter = 'active'; // 'active' | 'all'

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  List<Map<String, dynamic>> get filteredOffers {
    if (selectedFilter == 'active') {
      return offers.where((o) {
        final endRaw = o['end_date']?.toString();
        if (endRaw == null) return false;
        try {
          return DateTime.parse(endRaw).toLocal().isAfter(DateTime.now());
        } catch (_) {
          return false;
        }
      }).toList();
    }
    return offers; // 'all' — সব দেখাবে
  }

  int get activeCount => offers.where((o) {
    final endRaw = o['end_date']?.toString();
    if (endRaw == null) return false;
    try {
      return DateTime.parse(endRaw).toLocal().isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }).length;

  Future<void> _loadOffers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _authApiService.getPassengerOffers();
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

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  bool _isExpiringSoon(String? endDateRaw) {
    if (endDateRaw == null) return false;
    try {
      final end = DateTime.parse(endDateRaw).toLocal();
      final diff = end.difference(DateTime.now()).inDays;
      return diff <= 3;
    } catch (_) {
      return false;
    }
  }

  Color _getGradientStart(int index) {
    final colors = [
      const Color(0xFF14B8A6),
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF0EA5E9),
    ];
    return colors[index % colors.length];
  }

  Color _getGradientEnd(int index) {
    final colors = [
      const Color(0xFF0F766E),
      const Color(0xFF4F46E5),
      const Color(0xFFD97706),
      const Color(0xFFDB2777),
      const Color(0xFF0284C7),
    ];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.text),
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0, top: 10),
          child: Text(
            "Offers",
            style: TextStyle(
              color: AppColors.text,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadOffers,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadOffers,
        child: Column(
          children: [
            // ── Promo Code Input ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _offerController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: "Enter promo code",
                    hintStyle: const TextStyle(color: AppColors.mutedText),
                    prefixIcon: const Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.secondary,
                    ),
                    suffixIcon: TextButton(
                      onPressed: () {
                        if (_offerController.text.trim().isEmpty) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Promo code feature coming soon!'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            // ── Filter Chips ──
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Active',
                      count: activeCount,
                      isSelected: selectedFilter == 'active',
                      onTap: () => setState(() => selectedFilter = 'active'),
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'All',
                      count: offers.length,
                      isSelected: selectedFilter == 'all',
                      onTap: () => setState(() => selectedFilter = 'all'),
                      activeColor: AppColors.secondary,
                    ),
                  ],
                ),
              ),

            // ── Body ──
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
                  : errorMessage != null
                  ? _buildError()
                  : filteredOffers.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: filteredOffers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final offer = filteredOffers[index];
                  final isExpired = () {
                    final endRaw = offer['end_date']?.toString();
                    if (endRaw == null) return false;
                    try {
                      return DateTime.parse(endRaw).toLocal().isBefore(DateTime.now());
                    } catch (_) {
                      return false;
                    }
                  }();
                  return Opacity(
                      opacity: isExpired ? 0.55 : 1.0,
                      child: _OfferCard(
                        offer: offer,
                    index: index,
                    gradientStart: _getGradientStart(index),
                    gradientEnd: _getGradientEnd(index),
                    formatDate: _formatDate,
                    isExpiringSoon: _isExpiringSoon,
                      ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Nav ──
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedText,
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const UniRideHomePage()));
          } else if (index == 1) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const ServicesPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const ActivityPage()));
          } else if (index == 4) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const UniRideProfilePage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view), label: "Services"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: "Activity"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer), label: "Offers"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_offer_outlined,
                    size: 42, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              const Text(
                "No offers available right now",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text),
              ),
              const SizedBox(height: 8),
              const Text(
                "Check back later for exciting deals!",
                style: TextStyle(fontSize: 14, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style:
            const TextStyle(color: AppColors.mutedText, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOffers,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Offer Card Widget ───────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final int index;
  final Color gradientStart;
  final Color gradientEnd;
  final String Function(String?) formatDate;
  final bool Function(String?) isExpiringSoon;

  const _OfferCard({
    required this.offer,
    required this.index,
    required this.gradientStart,
    required this.gradientEnd,
    required this.formatDate,
    required this.isExpiringSoon,
  });

  @override
  Widget build(BuildContext context) {
    final name = offer['offer_name']?.toString() ?? 'Special Offer';
    final type = offer['offer_type']?.toString() ?? '';
    final reward = offer['reward_percentage']?.toString() ?? '';
    final promoCode = offer['promo_code']?.toString() ?? '';
    final conditions = offer['conditions']?.toString() ?? '';
    final eligibleUser = offer['eligible_user']?.toString() ?? 'all';
    final startDate = offer['start_date']?.toString();
    final endDate = offer['end_date']?.toString();
    final expiringSoon = isExpiringSoon(endDate);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_offer,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      type.isNotEmpty ? type.toUpperCase() : 'OFFER',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                if (expiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Ending Soon',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Offer Name ──
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            // ── Reward Badge ──
            if (reward.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$reward% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Conditions ──
            if (conditions.isNotEmpty)
              Text(
                conditions,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),

            // ── Bottom Info Row ──
            Row(
              children: [
                // Eligible user
                _InfoChip(
                  icon: Icons.people_outline,
                  label: eligibleUser == 'all'
                      ? 'All Users'
                      : eligibleUser.toUpperCase(),
                ),
                const SizedBox(width: 10),

                // Date range
                if (startDate != null || endDate != null)
                  _InfoChip(
                    icon: Icons.date_range_outlined,
                    label:
                    '${formatDate(startDate)} → ${formatDate(endDate)}',
                  ),
              ],
            ),

            // ── Promo Code ──
            if (promoCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                      Text('Promo code "$promoCode" copied!'),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_outlined,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        promoCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: activeColor.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : activeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : activeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}