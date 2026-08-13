import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

class AlumniProfileViewPage extends StatefulWidget {
  final String alumniId;
  final Map<String, dynamic>? previewData;

  const AlumniProfileViewPage({
    super.key,
    required this.alumniId,
    this.previewData,
  });

  @override
  State<AlumniProfileViewPage> createState() => _AlumniProfileViewPageState();
}

class _AlumniProfileViewPageState extends State<AlumniProfileViewPage> {
  final _authApiService = AuthApiService();

  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res =
      await _authApiService.getAlumniProfileDetails(widget.alumniId);
      setState(() {
        _data = Map<String, dynamic>.from(res['data'] ?? {});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── Connection Request Sheet ──
  void _showConnectSheet() {
    if (_data == null) return;
    final msgCtrl = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final fullName =
            '${_data!['first_name'] ?? ''} ${_data!['last_name'] ?? ''}'
                .trim();

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.inputFill,
                    backgroundImage: _data!['profile_picture'] != null
                        ? NetworkImage(_data!['profile_picture'])
                        : null,
                    child: _data!['profile_picture'] == null
                        ? const Icon(Icons.person,
                        size: 44, color: AppColors.mutedText)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_data!['major_subject'] ?? ''}, ${_data!['department'] ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.mutedText, fontSize: 13),
                  ),
                  if ((_data!['current_position'] ?? '')
                      .toString()
                      .isNotEmpty ||
                      (_data!['current_workplace'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((_data!['current_position'] ?? '')
                            .toString()
                            .isNotEmpty)
                          _data!['current_position'],
                        if ((_data!['current_workplace'] ?? '')
                            .toString()
                            .isNotEmpty)
                          _data!['current_workplace'],
                      ].join(', '),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Why do you want to connect with them?',
                      hintStyle: const TextStyle(
                          color: AppColors.mutedText, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                        // keyboard বন্ধ করে দিচ্ছি আগে — sheet close animation এর সাথে
                        // keyboard dismiss animation একসাথে হলে sheet আটকে গেছে মনে হয়
                        FocusScope.of(ctx).unfocus();
                        setSheetState(() => isSending = true);
                        try {
                          await _authApiService.sendAlumniContactRequest(
                            alumniId:
                            _data!['alumni_id'] ?? widget.alumniId,
                            message: msgCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          Navigator.of(ctx, rootNavigator: true).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request sent successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          setSheetState(() => isSending = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text(e
                                    .toString()
                                    .replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSending
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Send Connection Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── BUILD ──
  @override
  Widget build(BuildContext context) {
    final preview = widget.previewData;
    final fullName = _data != null
        ? '${_data!['first_name'] ?? ''} ${_data!['last_name'] ?? ''}'.trim()
        : (preview != null
        ? '${preview['first_name'] ?? ''} ${preview['last_name'] ?? ''}'
        .trim()
        : '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Alumni Profile',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.mutedText, size: 44),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mutedText)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadProfile,
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      )
          : _buildProfile(fullName),
      bottomNavigationBar: (_isLoading || _error != null)
          ? null
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _showConnectSheet,
              icon: const Icon(Icons.connect_without_contact,
                  color: Colors.white, size: 20),
              label: const Text(
                'Request to Connect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(String fullName) {
    final data = _data!;
    final degreeType = (data['degree_type'] ?? 'graduation').toString();
    final works = List<Map<String, dynamic>>.from(data['works'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo + Name + Position (সবসময় দেখা যাবে) ──
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.inputFill,
                  backgroundImage: data['profile_picture'] != null
                      ? NetworkImage(data['profile_picture'])
                      : null,
                  child: data['profile_picture'] == null
                      ? const Icon(Icons.person,
                      size: 56, color: AppColors.mutedText)
                      : null,
                ),
                const SizedBox(height: 14),
                Text(fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    )),
                if ((data['current_position'] ?? '').toString().isNotEmpty ||
                    (data['current_workplace'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if ((data['current_position'] ?? '')
                          .toString()
                          .isNotEmpty)
                        data['current_position'],
                      if ((data['current_workplace'] ?? '')
                          .toString()
                          .isNotEmpty)
                        data['current_workplace'],
                    ].join(' • '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified,
                          color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text('Verified Alumni',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Educational Status (সবসময় দেখা যাবে) ──
          if (degreeType == 'graduation' || degreeType == 'both') ...[
            _sectionCard(
              title: 'Graduation Information',
              icon: Icons.school_outlined,
              children: [
                _infoRow('University',
                    data['graduation_university'] ?? 'East West University'),
                _infoRow('Department', data['department'] ?? '—'),
                _infoRow('Major Subject', data['major_subject'] ?? '—'),
                _infoRow(
                    'Graduation Year', '${data['graduation_year'] ?? '—'}'),
              ],
            ),
            const SizedBox(height: 16),
          ],

          if (degreeType == 'masters' ||
              degreeType == 'both' ||
              (data['masters_university'] ?? '').toString().isNotEmpty) ...[
            _sectionCard(
              title: 'Masters Information',
              icon: Icons.menu_book_outlined,
              children: [
                _infoRow('University',
                    data['masters_university'] ?? 'East West University'),
                if ((data['masters_subject'] ?? '').toString().isNotEmpty)
                  _infoRow('Subject', data['masters_subject']),
                if (data['masters_completion_year'] != null)
                  _infoRow('Completion Year',
                      '${data['masters_completion_year']}'),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Location ──
          _sectionCard(
            title: 'Location',
            icon: Icons.location_on_outlined,
            children: [
              _infoRow(
                  'Country',
                  data['lives_abroad'] == true
                      ? (data['country'] ?? 'Unknown')
                      : 'Bangladesh'),
            ],
          ),

          const SizedBox(height: 16),

          // ── Remarkable Works — "+" চাপলে expand হবে ──
          if (works.isNotEmpty) ...[
            Row(
              children: const [
                Icon(Icons.star_outline, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Remarkable Works',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3)),
                ],
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: works.asMap().entries.map((entry) {
                    final i = entry.key;
                    final w = entry.value;
                    final hasLink =
                        (w['work_link'] ?? '').toString().isNotEmpty;
                    return Column(
                      children: [
                        if (i != 0)
                          const Divider(height: 1, color: AppColors.border),
                        ExpansionTile(
                          tilePadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          iconColor: AppColors.primary,
                          collapsedIconColor: AppColors.mutedText,
                          title: Text(
                            w['work_title'] ?? '',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: hasLink
                                  ? GestureDetector(
                                onTap: () async {
                                  final url =
                                  Uri.parse(w['work_link']);
                                  if (await canLaunchUrl(url)) {
                                    launchUrl(url);
                                  }
                                },
                                child: Text(
                                  w['work_link'],
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    decoration:
                                    TextDecoration.underline,
                                  ),
                                ),
                              )
                                  : const Text(
                                'No published link provided.',
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    )),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ),
      ],
    ),
  );
}