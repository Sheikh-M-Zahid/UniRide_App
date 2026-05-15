import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_api_service.dart';

class FareManagementPage extends StatefulWidget {
  const FareManagementPage({Key? key}) : super(key: key);

  @override
  State<FareManagementPage> createState() => _FareManagementPageState();
}

class _FareManagementPageState extends State<FareManagementPage>
    with SingleTickerProviderStateMixin {
  final AuthApiService _authApiService = AuthApiService();

  // ── Bike controllers ──
  final TextEditingController _bikeBaseFareController = TextEditingController();
  final TextEditingController _bikePerKmController = TextEditingController();

  // ── Car controllers ──
  final TextEditingController _carBaseFareController = TextEditingController();
  final TextEditingController _carPerKmController = TextEditingController();

  // ── Current active fare (display only) ──
  double _currentBikeBase = 0;
  double _currentBikePerKm = 0;
  double _currentCarBase = 0;
  double _currentCarPerKm = 0;
  String _bikeEffectiveFrom = '';
  String _carEffectiveFrom = '';

  bool _isLoading = true;
  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _loadFares();
  }

  @override
  void dispose() {
    _animController.dispose();
    _bikeBaseFareController.dispose();
    _bikePerKmController.dispose();
    _carBaseFareController.dispose();
    _carPerKmController.dispose();
    super.dispose();
  }

  // ── Load current fares from API ──
  Future<void> _loadFares() async {
    setState(() => _isLoading = true);
    try {
      final response = await _authApiService.getFareSettings();
      final data = response['data'] ?? {};
      final bike = data['bike'] ?? {};
      final car = data['car'] ?? {};

      final bBase  = (bike['baseFare']  ?? 0).toDouble();
      final bPerKm = (bike['perKm']     ?? 0).toDouble();
      final cBase  = (car['baseFare']   ?? 0).toDouble();
      final cPerKm = (car['perKm']      ?? 0).toDouble();

      setState(() {
        // current display values
        _currentBikeBase   = bBase;
        _currentBikePerKm  = bPerKm;
        _currentCarBase    = cBase;
        _currentCarPerKm   = cPerKm;
        _bikeEffectiveFrom = _formatDate(bike['effectiveFrom']);
        _carEffectiveFrom  = _formatDate(car['effectiveFrom']);
      });

      // editable fields pre-filled
      _bikeBaseFareController.text = bBase.toString();
      _bikePerKmController.text    = bPerKm.toString();
      _carBaseFareController.text  = cBase.toString();
      _carPerKmController.text     = cPerKm.toString();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }

  // ── Save updated fares ──
  Future<void> _saveFares() async {
    if (_bikeBaseFareController.text.trim().isEmpty ||
        _bikePerKmController.text.trim().isEmpty ||
        _carBaseFareController.text.trim().isEmpty ||
        _carPerKmController.text.trim().isEmpty) {
      _showSnack("Please fill in all fields.", isError: true);
      return;
    }

    final bikeBase  = double.tryParse(_bikeBaseFareController.text.trim());
    final bikePerKm = double.tryParse(_bikePerKmController.text.trim());
    final carBase   = double.tryParse(_carBaseFareController.text.trim());
    final carPerKm  = double.tryParse(_carPerKmController.text.trim());

    if (bikeBase == null || bikePerKm == null ||
        carBase == null  || carPerKm == null) {
      _showSnack("Please enter numbers only.", isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authApiService.updateFareSettings({
        'bike': {'baseFare': bikeBase, 'perKm': bikePerKm},
        'car':  {'baseFare': carBase,  'perKm': carPerKm},
      });
      if (!mounted) return;

      // update display values after successful save
      setState(() {
        _currentBikeBase  = bikeBase;
        _currentBikePerKm = bikePerKm;
        _currentCarBase   = carBase;
        _currentCarPerKm  = carPerKm;
        _bikeEffectiveFrom = _formatDate(DateTime.now().toIso8601String());
        _carEffectiveFrom  = _formatDate(DateTime.now().toIso8601String());
      });

      _showSnack("Fare has been updated successfully ✓");
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
        isError ? Colors.redAccent : Colors.cyanAccent.shade700,
        content: Text(msg,
            style: TextStyle(
                color: isError ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Fare Management",
            style:
            TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            tooltip: "Reload",
            onPressed: _loadFares,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff0f2027),
              Color(0xff203a43),
              Color(0xff2c5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
              child:
              CircularProgressIndicator(color: Colors.cyanAccent))
              : FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Info banner ──
                    _infoBanner(),
                    const SizedBox(height: 20),

                    // ══ CURRENT ACTIVE FARE CARD ══
                    _currentFareSummaryCard(),
                    const SizedBox(height: 28),

                    // ── divider with label ──
                    _dividerLabel("Update Fare"),
                    const SizedBox(height: 20),

                    // ── Bike Section ──
                    _sectionHeader(
                        icon: Icons.two_wheeler_rounded,
                        label: "Bike",
                        color: Colors.cyanAccent),
                    const SizedBox(height: 14),
                    _fareCard(children: [
                      _fareField(
                        controller: _bikeBaseFareController,
                        label: "Base Fare",
                        hint: "e.g: 30",
                        icon: Icons.flag_outlined,
                        suffix: "৳",
                      ),
                      const SizedBox(height: 16),
                      _fareField(
                        controller: _bikePerKmController,
                        label: "Per Kilometer Fare",
                        hint: "e.g: 12",
                        icon: Icons.route_outlined,
                        suffix: "৳/km",
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // ── Car Section ──
                    _sectionHeader(
                        icon: Icons.directions_car_rounded,
                        label: "Private Car",
                        color: Colors.orangeAccent),
                    const SizedBox(height: 14),
                    _fareCard(
                      accentColor: Colors.orangeAccent,
                      children: [
                        _fareField(
                          controller: _carBaseFareController,
                          label: "Base Fare",
                          hint: "e.g: 50",
                          icon: Icons.flag_outlined,
                          suffix: "৳",
                          accentColor: Colors.orangeAccent,
                        ),
                        const SizedBox(height: 16),
                        _fareField(
                          controller: _carPerKmController,
                          label: "Per Kilometer Fare",
                          hint: "e.g: 20",
                          icon: Icons.route_outlined,
                          suffix: "৳/km",
                          accentColor: Colors.orangeAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // ── Save Button ──
                    _saveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  CURRENT ACTIVE FARE SUMMARY CARD  ← নতুন
  // ══════════════════════════════════════════════
  Widget _currentFareSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.price_check_rounded,
                    color: Colors.cyanAccent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                "Current Active Fare",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle,
                        color: Colors.greenAccent, size: 8),
                    SizedBox(width: 4),
                    Text("Active",
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Bike row ──
          _fareRowItem(
            icon: Icons.two_wheeler_rounded,
            label: "Bike",
            iconColor: Colors.cyanAccent,
            baseFare: _currentBikeBase,
            perKm: _currentBikePerKm,
            effectiveFrom: _bikeEffectiveFrom,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white12, height: 1),
          ),

          // ── Car row ──
          _fareRowItem(
            icon: Icons.directions_car_rounded,
            label: "Private Car",
            iconColor: Colors.orangeAccent,
            baseFare: _currentCarBase,
            perKm: _currentCarPerKm,
            effectiveFrom: _carEffectiveFrom,
          ),
        ],
      ),
    );
  }

  Widget _fareRowItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required double baseFare,
    required double perKm,
    required String effectiveFrom,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Base Fare chip
            Expanded(
              child: _fareChip(
                label: "Base Fare",
                value: "৳ ${baseFare.toStringAsFixed(2)}",
                color: iconColor,
              ),
            ),
            const SizedBox(width: 10),
            // Per KM chip
            Expanded(
              child: _fareChip(
                label: "Per KM",
                value: "৳ ${perKm.toStringAsFixed(2)}",
                color: iconColor,
              ),
            ),
          ],
        ),
        if (effectiveFrom.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  color: Colors.white30, size: 12),
              const SizedBox(width: 4),
              Text(
                "Last updated: $effectiveFrom",
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _fareChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // ── Section Divider Label ──
  Widget _dividerLabel(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }

  // ── Info Banner ──
  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.cyanAccent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "If fuel prices change, update the fares below. "
                  "The changes will take effect immediately.",
              style: TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _sectionHeader({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ── Fare Card ──
  Widget _fareCard({
    required List<Widget> children,
    Color accentColor = Colors.cyanAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(children: children),
    );
  }

  // ── Fare Text Field ──
  Widget _fareField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String suffix,
    Color accentColor = Colors.cyanAccent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: Icon(icon, color: accentColor, size: 20),
            suffixText: suffix,
            suffixStyle: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 13),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Save Button ──
  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveFares,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          disabledBackgroundColor:
          Colors.cyanAccent.withOpacity(0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              color: Colors.black, strokeWidth: 2.5),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_rounded,
                color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text("Save Fare Settings",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}