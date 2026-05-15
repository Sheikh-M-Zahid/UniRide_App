// AlumniPage.dart
import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'AlumniRegisterPage.dart';
import 'AlumniProfilePage.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class AlumniPage extends StatefulWidget {
  const AlumniPage({super.key});

  @override
  State<AlumniPage> createState() => _AlumniPageState();
}

class _AlumniPageState extends State<AlumniPage> {
  final _authApiService = AuthApiService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _alumniList = [];
  List<String> _departments = ['All'];
  String _selectedDept = 'All';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  bool _hasMore = true;

  Map<String, dynamic>? _myAlumniStatus; // null = not applied
  bool _isMyStatusLoaded = false;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMyStatus();
    _loadDepartments();
    _loadAlumni(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadAlumni();
    }
  }

  Future<void> _loadMyStatus() async {
    try {
      final res = await _authApiService.getAlumniMyStatus();
      setState(() {
        _myAlumniStatus = res['data'];
        _isMyStatusLoaded = true;
      });
    } catch (_) {
      setState(() => _isMyStatusLoaded = true);
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final res = await _authApiService.getAlumniDepartments();
      final depts = List<String>.from(res['data'] ?? []);
      setState(() {
        _departments = ['All', ...depts];
      });
    } catch (_) {}
  }

  Future<void> _loadAlumni({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _alumniList = [];
        _isLoading = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final res = await _authApiService.getAlumniList(
        department: _selectedDept == 'All' ? null : _selectedDept,
        search: _searchCtrl.text.trim().isNotEmpty
            ? _searchCtrl.text.trim()
            : null,
        page: _page,
      );

      final data = List<Map<String, dynamic>>.from(res['data'] ?? []);
      final total = res['total'] ?? 0;

      setState(() {
        if (reset) {
          _alumniList = data;
        } else {
          _alumniList.addAll(data);
        }
        _page++;
        _hasMore = _alumniList.length < total;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _showContactPopup(Map<String, dynamic> alumni) {
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
            '${alumni['first_name'] ?? ''} ${alumni['last_name'] ?? ''}'
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
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile photo
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.inputFill,
                    backgroundImage: alumni['profile_picture'] != null
                        ? NetworkImage(alumni['profile_picture'])
                        : null,
                    child: alumni['profile_picture'] == null
                        ? const Icon(Icons.person, size: 44, color: AppColors.mutedText)
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Name
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Major, Department
                  Text(
                    '${alumni['major_subject'] ?? ''}, ${alumni['department'] ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                    ),
                  ),

                  if ((alumni['current_position'] ?? '').isNotEmpty ||
                      (alumni['current_workplace'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((alumni['current_position'] ?? '').isNotEmpty)
                          alumni['current_position'],
                        if ((alumni['current_workplace'] ?? '').isNotEmpty)
                          alumni['current_workplace'],
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

                  // Message field
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Why do you want to connect with them?',
                      hintStyle: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 14,
                      ),
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

                  // Send Request Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                        setSheetState(() => isSending = true);
                        try {
                          await _authApiService.sendAlumniContactRequest(
                            alumniId: alumni['alumni_id'],
                            message: msgCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request sent successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          setSheetState(() => isSending = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString())),
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

  @override
  Widget build(BuildContext context) {
    final bool isAlumni = _myAlumniStatus != null &&
        _myAlumniStatus!['verification_status'] == 'approved';
    final bool isPending = _myAlumniStatus != null &&
        _myAlumniStatus!['verification_status'] == 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alumni',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isMyStatusLoaded) ...[
            if (isAlumni)
            // Show profile icon → go to alumni profile
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlumniProfilePage(
                          alumniData: _myAlumniStatus!,
                          isOwnProfile: true,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.inputFill,
                    backgroundImage:
                    _myAlumniStatus!['profile_picture'] != null
                        ? NetworkImage(_myAlumniStatus!['profile_picture'])
                        : null,
                    child: _myAlumniStatus!['profile_picture'] == null
                        ? const Icon(Icons.person,
                        size: 20, color: AppColors.mutedText)
                        : null,
                  ),
                ),
              )
            else if (isPending)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Chip(
                  label: const Text(
                    'Under Review',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  side: const BorderSide(color: Colors.orange, width: 1),
                  padding: EdgeInsets.zero,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AlumniRegisterPage()),
                    ).then((_) => _loadMyStatus());
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text(
                    'Join Alumni',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ── SEARCH + FILTER ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) {
                      Future.delayed(const Duration(milliseconds: 400), () {
                        _loadAlumni(reset: true);
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle:
                      TextStyle(color: AppColors.mutedText, fontSize: 14),
                      prefixIcon:
                      Icon(Icons.search, color: AppColors.secondary, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Department Filter
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _departments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final dept = _departments[i];
                      final isSelected = _selectedDept == dept;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedDept = dept);
                          _loadAlumni(reset: true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            dept,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── LIST ──
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
                : _alumniList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined,
                      size: 60,
                      color: AppColors.mutedText.withOpacity(0.5)),
                  const SizedBox(height: 14),
                  const Text(
                    'No alumni found',
                    style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount:
              _alumniList.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _alumniList.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }
                return _AlumniCard(
                  alumni: _alumniList[i],
                  onTap: () =>
                      _showContactPopup(_alumniList[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alumni List Card ──
class _AlumniCard extends StatelessWidget {
  final Map<String, dynamic> alumni;
  final VoidCallback onTap;

  const _AlumniCard({required this.alumni, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fullName =
    '${alumni['first_name'] ?? ''} ${alumni['last_name'] ?? ''}'.trim();

    return GestureDetector(
      onTap: onTap,
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
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${alumni['major_subject'] ?? ''}, ${alumni['department'] ?? ''}',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                  if ((alumni['current_position'] ?? '').isNotEmpty ||
                      (alumni['current_workplace'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((alumni['current_position'] ?? '').isNotEmpty)
                          alumni['current_position'],
                        if ((alumni['current_workplace'] ?? '').isNotEmpty)
                          alumni['current_workplace'],
                      ].join(', '),
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Profile Photo
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.inputFill,
              backgroundImage: alumni['profile_picture'] != null
                  ? NetworkImage(alumni['profile_picture'])
                  : null,
              child: alumni['profile_picture'] == null
                  ? const Icon(Icons.person,
                  size: 30, color: AppColors.mutedText)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
