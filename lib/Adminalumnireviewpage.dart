// AdminAlumniReviewPage.dart
// Add this page to your existing Admin panel
import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class AdminAlumniReviewPage extends StatefulWidget {
  const AdminAlumniReviewPage({super.key});

  @override
  State<AdminAlumniReviewPage> createState() => _AdminAlumniReviewPageState();
}

class _AdminAlumniReviewPageState extends State<AdminAlumniReviewPage> {
  final _authApiService = AuthApiService();
  List<Map<String, dynamic>> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _authApiService.adminGetPendingAlumni();
      setState(() {
        _pending = List<Map<String, dynamic>>.from(res['data'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showReviewDialog(Map<String, dynamic> alumni) {
    final rejectCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            bool isActing = false;
            final name =
            '${alumni['first_name'] ?? ''} ${alumni['last_name'] ?? ''}'
                .trim();
            final works =
            List<Map<String, dynamic>>.from(alumni['works'] ?? []);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollCtrl) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name + Email
                    Text(name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text(alumni['university_email'] ?? '',
                        style: const TextStyle(
                            color: AppColors.mutedText, fontSize: 13)),

                    const SizedBox(height: 20),

                    // Info Grid
                    _reviewRow('Department', alumni['department']),
                    _reviewRow('Major', alumni['major_subject']),
                    _reviewRow('Graduation Year',
                        '${alumni['graduation_year'] ?? ''}'),
                    _reviewRow('Workplace', alumni['current_workplace'] ?? '—'),
                    _reviewRow('Position', alumni['current_position'] ?? '—'),
                    _reviewRow(
                        'Country',
                        alumni['lives_abroad'] == true
                            ? alumni['country'] ?? '?'
                            : 'Bangladesh'),

                    if (works.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Remarkable Works',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.text)),
                      const SizedBox(height: 8),
                      ...works.map(
                            (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 6, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(w['work_title'] ?? '',
                                    style: const TextStyle(
                                        color: AppColors.text,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Document images
                    const Text('Submitted Documents',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.text)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _docImage(
                              'Alumni Card', alumni['alumni_card_photo']),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _docImage(
                              'Transcript', alumni['transcript_photo']),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Rejection reason
                    TextField(
                      controller: rejectCtrl,
                      decoration: InputDecoration(
                        hintText: 'Rejection reason (required if declining)',
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),

                    if (!isActing)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                if (rejectCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please provide a rejection reason.')),
                                  );
                                  return;
                                }
                                setSheet(() => isActing = true);
                                await _authApiService.adminReviewAlumni(
                                  alumniId: alumni['alumni_id'],
                                  action: 'rejected',
                                  rejectionReason: rejectCtrl.text.trim(),
                                );
                                Navigator.pop(ctx);
                                _load();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Decline',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                setSheet(() => isActing = true);
                                await _authApiService.adminReviewAlumni(
                                  alumniId: alumni['alumni_id'],
                                  action: 'approved',
                                );
                                Navigator.pop(ctx);
                                _load();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Alumni approved!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Approve',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _reviewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value ?? '—',
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _docImage(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedText)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: url != null
              ? Image.network(
            url,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: AppColors.inputFill,
              child: const Center(
                  child: Icon(Icons.broken_image,
                      color: AppColors.mutedText)),
            ),
          )
              : Container(
            height: 120,
            color: AppColors.inputFill,
            child: const Center(
                child: Icon(Icons.image_not_supported,
                    color: AppColors.mutedText)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Alumni Applications (${_pending.length})',
          style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.text),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : _pending.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 60,
                color: AppColors.mutedText.withOpacity(0.5)),
            const SizedBox(height: 14),
            const Text('No pending applications',
                style: TextStyle(
                    color: AppColors.mutedText, fontSize: 16)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pending.length,
        itemBuilder: (_, i) {
          final a = _pending[i];
          final name =
          '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'
              .trim();
          return GestureDetector(
            onTap: () => _showReviewDialog(a),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.inputFill,
                    backgroundImage: a['profile_picture'] != null
                        ? NetworkImage(a['profile_picture'])
                        : null,
                    child: a['profile_picture'] == null
                        ? const Icon(Icons.person,
                        size: 26,
                        color: AppColors.mutedText)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.text)),
                        const SizedBox(height: 3),
                        Text(
                          '${a['major_subject'] ?? ''} · ${a['department'] ?? ''}',
                          style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Review',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
