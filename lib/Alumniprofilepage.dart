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

class AlumniProfilePage extends StatefulWidget {
  final Map<String, dynamic> alumniData;
  final bool isOwnProfile;

  const AlumniProfilePage({
    super.key,
    required this.alumniData,
    this.isOwnProfile = false,
  });

  @override
  State<AlumniProfilePage> createState() => _AlumniProfilePageState();
}

class _AlumniProfilePageState extends State<AlumniProfilePage> {
  final _authApiService = AuthApiService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoadingRequests = false;
  bool _showRequests = false;

  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.alumniData);
    if (widget.isOwnProfile) _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final res = await _authApiService.getAlumniRequests();
      setState(() {
        _requests = List<Map<String, dynamic>>.from(res['data'] ?? []);
        _isLoadingRequests = false;
      });
    } catch (_) {
      setState(() => _isLoadingRequests = false);
    }
  }

  void _showRequestDetailPopup(Map<String, dynamic> req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RequestDetailSheet(
        request: req,
        onRespond: (action, scheduledTime) async {
          await _authApiService.respondAlumniRequest(
            requestId: req['request_id'],
            action: action,
            scheduledTime: scheduledTime,
          );
          Navigator.pop(ctx);
          _loadRequests();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(action == 'accepted'
                ? 'Request accepted!'
                : 'Request declined.'),
            backgroundColor:
            action == 'accepted' ? Colors.green : Colors.red,
          ));
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EDIT SHEET — শুধু editable fields
  // ─────────────────────────────────────────────
  void _openEditSheet() {
    final workplaceCtrl = TextEditingController(
        text: _data['current_workplace'] ?? '');
    final positionCtrl = TextEditingController(
        text: _data['current_position'] ?? '');
    final countryCtrl =
    TextEditingController(text: _data['country'] ?? 'Bangladesh');
    bool livesAbroad = _data['lives_abroad'] == true;

    // Works — editable titles and links
    final List<Map<String, TextEditingController>> workCtrls = [];
    final works =
    List<Map<String, dynamic>>.from(_data['works'] ?? []);
    for (final w in works) {
      workCtrls.add({
        'title': TextEditingController(text: w['work_title'] ?? ''),
        'link': TextEditingController(text: w['work_link'] ?? ''),
        'work_id': TextEditingController(
            text: w['work_id']?.toString() ?? ''),
      });
    }
    if (workCtrls.isEmpty) {
      workCtrls.add({
        'title': TextEditingController(),
        'link': TextEditingController(),
        'work_id': TextEditingController(),
      });
    }

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.only(
                  bottom:
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                          borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Edit Profile',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.text)),

                  // Non-editable note
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline,
                            color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Department, Major Subject এবং Graduation Year পরিবর্তন করা যাবে না।',
                            style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Workplace ──
                  _editLabel('Current Workplace'),
                  const SizedBox(height: 8),
                  _editField(workplaceCtrl,
                      'e.g. Google Bangladesh Ltd.'),

                  const SizedBox(height: 14),

                  // ── Position ──
                  _editLabel('Current Position'),
                  const SizedBox(height: 8),
                  _editField(positionCtrl,
                      'e.g. Senior Software Engineer'),

                  const SizedBox(height: 14),

                  // ── Location ──
                  _editLabel('Location'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: AppColors.border)),
                    child: CheckboxListTile(
                      value: livesAbroad,
                      onChanged: (val) => setSheet(
                              () => livesAbroad = val ?? false),
                      activeColor: AppColors.primary,
                      title: const Text(
                          'I currently live outside Bangladesh',
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (livesAbroad) ...[
                    const SizedBox(height: 10),
                    _editField(countryCtrl, 'Country name'),
                  ],

                  const SizedBox(height: 20),

                  // ── Works ──
                  _editLabel('Remarkable Works'),
                  const SizedBox(height: 8),
                  ...workCtrls.asMap().entries.map((entry) {
                    final i = entry.key;
                    final w = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius:
                          BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('Work ${i + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.mutedText)),
                            const Spacer(),
                            if (workCtrls.length > 1)
                              GestureDetector(
                                onTap: () => setSheet(() {
                                  w['title']!.dispose();
                                  w['link']!.dispose();
                                  workCtrls.removeAt(i);
                                }),
                                child: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                    size: 18),
                              ),
                          ]),
                          const SizedBox(height: 8),
                          _editField(
                              w['title']!, 'Work / Project Name'),
                          const SizedBox(height: 8),
                          _editField(w['link']!,
                              'Published Link (optional)'),
                        ],
                      ),
                    );
                  }),
                  if (workCtrls.length < 10)
                    TextButton.icon(
                      onPressed: () => setSheet(() => workCtrls.add({
                        'title': TextEditingController(),
                        'link': TextEditingController(),
                        'work_id': TextEditingController(),
                      })),
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppColors.primary, size: 18),
                      label: const Text('Add Work',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),

                  const SizedBox(height: 24),

                  // ── Save button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                        setSheet(() => isSaving = true);
                        try {
                          final updatedWorks = workCtrls
                              .where((w) => w['title']!
                              .text
                              .trim()
                              .isNotEmpty)
                              .map((w) => {
                            'work_id': w['work_id']!
                                .text
                                .trim(),
                            'work_title': w['title']!
                                .text
                                .trim(),
                            'work_link': w['link']!
                                .text
                                .trim()
                                .isNotEmpty
                                ? w['link']!.text.trim()
                                : null,
                          })
                              .toList();

                          await _authApiService
                              .updateAlumniProfile(
                            alumniId: _data['alumni_id'],
                            currentWorkplace: workplaceCtrl
                                .text
                                .trim(),
                            currentPosition:
                            positionCtrl.text.trim(),
                            livesAbroad: livesAbroad,
                            country: livesAbroad
                                ? countryCtrl.text.trim()
                                : 'Bangladesh',
                            works: updatedWorks,
                          );

                          setState(() {
                            _data['current_workplace'] =
                                workplaceCtrl.text.trim();
                            _data['current_position'] =
                                positionCtrl.text.trim();
                            _data['lives_abroad'] =
                                livesAbroad;
                            _data['country'] = livesAbroad
                                ? countryCtrl.text.trim()
                                : 'Bangladesh';
                            _data['works'] = updatedWorks
                                .map((w) => {
                              'work_id':
                              w['work_id'],
                              'work_title':
                              w['work_title'],
                              'work_link':
                              w['work_link'],
                            })
                                .toList();
                          });

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content:
                            Text('Profile updated!'),
                            backgroundColor: Colors.green,
                          ));
                        } catch (e) {
                          setSheet(() => isSaving = false);
                          ScaffoldMessenger.of(ctx)
                              .showSnackBar(SnackBar(
                              content:
                              Text(e.toString())));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2))
                          : const Text('Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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

  Widget _editLabel(String label) => Text(label,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.text));

  Widget _editField(TextEditingController ctrl, String hint) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(color: AppColors.text, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          const TextStyle(color: AppColors.mutedText, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      );

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final fullName =
    '${_data['first_name'] ?? ''} ${_data['last_name'] ?? ''}'
        .trim();
    final works =
    List<Map<String, dynamic>>.from(_data['works'] ?? []);
    final pendingCount =
        _requests.where((r) => r['status'] == 'pending').length;
    final degreeType =
    (_data['degree_type'] ?? 'graduation').toString();

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
                fontSize: 18)),
        centerTitle: true,
        actions: widget.isOwnProfile
            ? [
          // Edit button
          if (!_showRequests)
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary),
              onPressed: _openEditSheet,
              tooltip: 'Edit Profile',
            ),
          // Requests button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.people_outline,
                    color: AppColors.text),
                onPressed: () => setState(
                        () => _showRequests = !_showRequests),
                tooltip: 'Connection Requests',
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text('$pendingCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10)),
                    ),
                  ),
                ),
            ],
          ),
        ]
            : null,
      ),
      body: _showRequests
          ? _buildRequestsList()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ──
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.inputFill,
                    backgroundImage:
                    _data['profile_picture'] != null
                        ? NetworkImage(
                        _data['profile_picture'])
                        : null,
                    child: _data['profile_picture'] == null
                        ? const Icon(Icons.person,
                        size: 54,
                        color: AppColors.mutedText)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(fullName,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary
                              .withOpacity(0.3)),
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
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Graduation Info ──
            if (degreeType == 'graduation' ||
                degreeType == 'both') ...[
              _sectionCard(
                title: 'Graduation Information',
                icon: Icons.school_outlined,
                children: [
                  _infoRow('University',
                      _data['graduation_university'] ??
                          'East West University'),
                  _infoRow('Department',
                      _data['department'] ?? '—'),
                  _infoRow('Major Subject',
                      _data['major_subject'] ?? '—'),
                  _infoRow('Graduation Year',
                      '${_data['graduation_year'] ?? '—'}'),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Masters Info ──
            if (degreeType == 'masters' ||
                degreeType == 'both' ||
                (_data['masters_university'] ?? '').isNotEmpty) ...[
              _sectionCard(
                title: 'Masters Information',
                icon: Icons.menu_book_outlined,
                children: [
                  _infoRow('University',
                      _data['masters_university'] ??
                          'East West University'),
                  if ((_data['masters_subject'] ?? '')
                      .isNotEmpty)
                    _infoRow('Subject',
                        _data['masters_subject']),
                  if (_data['masters_completion_year'] != null)
                    _infoRow('Completion Year',
                        '${_data['masters_completion_year']}'),
                  if ((_data['masters_status'] ?? '')
                      .isNotEmpty)
                    _infoRow('Status',
                        _mastersStatusLabel(
                            _data['masters_status'])),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Professional Info ──
            if ((_data['current_workplace'] ?? '').isNotEmpty ||
                (_data['current_position'] ?? '').isNotEmpty) ...[
              _sectionCard(
                title: 'Professional Information',
                icon: Icons.work_outline,
                children: [
                  if ((_data['current_position'] ?? '')
                      .isNotEmpty)
                    _infoRow('Position',
                        _data['current_position']),
                  if ((_data['current_workplace'] ?? '')
                      .isNotEmpty)
                    _infoRow('Workplace',
                        _data['current_workplace']),
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
                    _data['lives_abroad'] == true
                        ? (_data['country'] ?? 'Unknown')
                        : 'Bangladesh'),
              ],
            ),
            const SizedBox(height: 16),

            // ── Remarkable Works ──
            if (works.isNotEmpty) ...[
              _sectionCard(
                title: 'Remarkable Works',
                icon: Icons.star_outline,
                children: works.asMap().entries.map((entry) {
                  final w = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text('${entry.key + 1}',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(w['work_title'] ?? '',
                                  style: const TextStyle(
                                      color: AppColors.text,
                                      fontWeight:
                                      FontWeight.w600,
                                      fontSize: 14)),
                              if ((w['work_link'] ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () async {
                                    final url = Uri.parse(
                                        w['work_link']);
                                    if (await canLaunchUrl(
                                        url)) {
                                      launchUrl(url);
                                    }
                                  },
                                  child: Text(w['work_link'],
                                      style: const TextStyle(
                                          color:
                                          AppColors.primary,
                                          fontSize: 12,
                                          decoration:
                                          TextDecoration
                                              .underline),
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  String _mastersStatusLabel(String? status) {
    switch (status) {
      case 'ongoing':
        return 'চলতেছে (Ongoing)';
      case 'completed':
        return 'কমপ্লিট (Completed)';
      case 'not_started':
        return 'এখনো শুরু করিনি';
      default:
        return status ?? '—';
    }
  }

  Widget _buildRequestsList() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Text('Connection Requests',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.text)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    setState(() => _showRequests = false),
                child: const Text('Back to Profile',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoadingRequests
              ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary))
              : _requests.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 50,
                    color: AppColors.mutedText
                        .withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text('No requests yet',
                    style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 15)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _requests.length,
            itemBuilder: (_, i) {
              final r = _requests[i];
              final name =
              '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'
                  .trim();
              final isPending = r['status'] == 'pending';
              return GestureDetector(
                onTap: isPending
                    ? () => _showRequestDetailPopup(r)
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(16),
                    border: Border.all(
                        color: isPending
                            ? AppColors.primary
                            .withOpacity(0.4)
                            : AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.inputFill,
                        backgroundImage:
                        r['profile_picture'] != null
                            ? NetworkImage(
                            r['profile_picture'])
                            : null,
                        child: r['profile_picture'] == null
                            ? const Icon(Icons.person,
                            size: 24,
                            color: AppColors.mutedText)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.text)),
                            if ((r['message'] ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(r['message'],
                                  style: const TextStyle(
                                      color:
                                      AppColors.mutedText,
                                      fontSize: 13),
                                  maxLines: 2,
                                  overflow:
                                  TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusBadge(r['status']),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg, textColor;
    String label;
    switch (status) {
      case 'accepted':
        bg = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Accepted';
        break;
      case 'rejected':
        bg = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'Declined';
        break;
      default:
        bg = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Pending';
    }
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
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
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3))
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
                        color: AppColors.text)),
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
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

// ── Request Detail Bottom Sheet ──
class _RequestDetailSheet extends StatefulWidget {
  final Map<String, dynamic> request;
  final Future<void> Function(String action, DateTime? scheduledTime)
  onRespond;

  const _RequestDetailSheet(
      {required this.request, required this.onRespond});

  @override
  State<_RequestDetailSheet> createState() =>
      _RequestDetailSheetState();
}

class _RequestDetailSheetState extends State<_RequestDetailSheet> {
  DateTime? _scheduledTime;
  bool _isResponding = false;

  Future<void> _pickScheduledTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
          data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                  primary: AppColors.primary)),
          child: child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
      TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (ctx, child) => Theme(
          data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                  primary: AppColors.primary)),
          child: child!),
    );
    if (time == null) return;
    setState(() => _scheduledTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final name =
    '${req['first_name'] ?? ''} ${req['last_name'] ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.inputFill,
                  backgroundImage: req['profile_picture'] != null
                      ? NetworkImage(req['profile_picture'])
                      : null,
                  child: req['profile_picture'] == null
                      ? const Icon(Icons.person,
                      size: 28, color: AppColors.mutedText)
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
                              fontSize: 16,
                              color: AppColors.text)),
                      if ((req['requester_department'] ?? '')
                          .isNotEmpty)
                        Text(req['requester_department'],
                            style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 13)),
                      if ((req['university_email'] ?? '').isNotEmpty)
                        Text(req['university_email'],
                            style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            if ((req['message'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('Message',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.mutedText)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(req['message'],
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        height: 1.5)),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Schedule a Chat Time (Optional)',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.text)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickScheduledTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _scheduledTime != null
                      ? AppColors.primary.withOpacity(0.08)
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _scheduledTime != null
                          ? AppColors.primary
                          : AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule,
                        color: _scheduledTime != null
                            ? AppColors.primary
                            : AppColors.mutedText,
                        size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _scheduledTime != null
                          ? '${_scheduledTime!.day}/${_scheduledTime!.month}/${_scheduledTime!.year} at ${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
                          : 'Pick date & time for chat session',
                      style: TextStyle(
                          color: _scheduledTime != null
                              ? AppColors.primary
                              : AppColors.mutedText,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_isResponding)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        setState(() => _isResponding = true);
                        await widget.onRespond('rejected', null);
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
                        setState(() => _isResponding = true);
                        await widget.onRespond(
                            'accepted', _scheduledTime);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Accept',
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
                      color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}