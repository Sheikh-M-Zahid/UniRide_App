import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'services/auth_api_service.dart';
import 'AlumniPage.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class AlumniRegisterPage extends StatefulWidget {
  const AlumniRegisterPage({super.key});

  @override
  State<AlumniRegisterPage> createState() => _AlumniRegisterPageState();
}

class _AlumniRegisterPageState extends State<AlumniRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authApiService = AuthApiService();
  final _picker = ImagePicker();

  // ── Degree selection ──
  String _degreeType = 'graduation'; // graduation | masters | both

  // ── Graduation fields ──
  final _gradDepartmentCtrl = TextEditingController();
  final _gradMajorCtrl = TextEditingController();
  final _gradYearCtrl = TextEditingController();

  // ── External grad university (only when degreeType == 'masters') ──
  final _gradUniversityCtrl = TextEditingController();

  // ── Masters fields ──
  final _mastersSubjectCtrl = TextEditingController();
  final _mastersYearCtrl = TextEditingController();
  String _mastersStatus = ''; // ongoing | completed | not_started

  // Masters ongoing/completed extra fields
  final _mastersOngoingUniversityCtrl = TextEditingController();
  final _mastersOngoingSubjectCtrl = TextEditingController();

  // ── Professional ──
  final _workplaceCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();

  // ── Location ──
  final _countryCtrl = TextEditingController();
  bool _livesAbroad = false;

  // ── State ──
  bool _isSubmitting = false;
  File? _alumniCardPhoto;
  File? _transcriptPhoto;

  // ── Works ──
  final List<Map<String, TextEditingController>> _works = [
    {'title': TextEditingController(), 'link': TextEditingController()},
    {'title': TextEditingController(), 'link': TextEditingController()},
  ];

  @override
  void dispose() {
    _gradDepartmentCtrl.dispose();
    _gradMajorCtrl.dispose();
    _gradYearCtrl.dispose();
    _gradUniversityCtrl.dispose();
    _mastersSubjectCtrl.dispose();
    _mastersYearCtrl.dispose();
    _mastersOngoingUniversityCtrl.dispose();
    _mastersOngoingSubjectCtrl.dispose();
    _workplaceCtrl.dispose();
    _positionCtrl.dispose();
    _countryCtrl.dispose();
    for (final w in _works) {
      w['title']!.dispose();
      w['link']!.dispose();
    }
    super.dispose();
  }

  Future<File?> _pickImage({required ImageSource source}) async {
    try {
      PermissionStatus status;

      if (source == ImageSource.camera) {
        status = await Permission.camera.request();
      } else {
        if (Platform.isAndroid) {
          // Android 13+ photos, নিচে storage
          status = await Permission.photos.request();
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        } else {
          status = await Permission.photos.request();
        }
      }

      if (status.isGranted || status.isLimited) {
        final XFile? file = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
        );
        if (file != null) return File(file.path);
        return null;
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDialog(
              source == ImageSource.camera ? 'Camera' : 'Photo Gallery');
        }
        return null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(source == ImageSource.camera
              ? 'Camera permission denied.'
              : 'Gallery permission denied.'),
        ));
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick image: $e')));
      }
      return null;
    }
  }

  void _showPermissionDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$permissionName Permission Required'),
        content: Text(
            '$permissionName access is permanently denied. Please enable it from app settings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Open Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<File?> _showImageSourceSheet() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 16),
            const Text('Upload Photo',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.text)),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
              ),
              title: const Text('Take a Photo',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (source == null) return null;
    return await _pickImage(source: source);
  }

  // WORKS
  void _addWork() {
    if (_works.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 10 works allowed.')));
      return;
    }
    setState(() => _works.add({
      'title': TextEditingController(),
      'link': TextEditingController(),
    }));
  }

  void _removeWork(int index) {
    setState(() {
      _works[index]['title']!.dispose();
      _works[index]['link']!.dispose();
      _works.removeAt(index);
    });
  }

  // SUBMIT
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_alumniCardPhoto == null || _transcriptPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Please upload your alumni card and transcript photos.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final worksList = _works
          .where((w) => w['title']!.text.trim().isNotEmpty)
          .map((w) => {
        'work_title': w['title']!.text.trim(),
        'work_link': w['link']!.text.trim().isNotEmpty
            ? w['link']!.text.trim()
            : null,
      })
          .toList();

      // Build masters university for ongoing case
      final String? mastersUnivFinal = () {
        if (_degreeType == 'graduation') {
          if (_mastersStatus == 'ongoing' ||
              _mastersStatus == 'completed') {
            return _mastersOngoingUniversityCtrl.text.trim();
          }
          return null;
        }
        if (_degreeType == 'masters') return 'East West University';
        if (_degreeType == 'both') return 'East West University';
        return null;
      }();

      final String? mastersSubjectFinal = () {
        if (_degreeType == 'masters' || _degreeType == 'both') {
          return _mastersSubjectCtrl.text.trim();
        }
        if (_degreeType == 'graduation') {
          if (_mastersStatus == 'ongoing') {
            return _mastersOngoingSubjectCtrl.text.trim();
          }
          if (_mastersStatus == 'completed') {
            return _mastersSubjectCtrl.text.trim();
          }
        }
        return null;
      }();

      await _authApiService.registerAlumni(
        degreeType: _degreeType,
        graduationUniversity: _degreeType == 'masters'
            ? _gradUniversityCtrl.text.trim()
            : 'East West University',
        // Legacy fields
        department: _gradDepartmentCtrl.text.trim(),
        majorSubject: _gradMajorCtrl.text.trim(),
        legacyGraduationYear: int.tryParse(_gradYearCtrl.text.trim()) ?? 0,
        mastersStatus:
        _mastersStatus.isNotEmpty ? _mastersStatus : null,
        mastersUniversity: mastersUnivFinal,
        mastersSubject: mastersSubjectFinal,
        mastersCompletionYear: () {
          if (_degreeType == 'masters' || _degreeType == 'both') {
            return int.tryParse(_mastersYearCtrl.text.trim());
          }
          if (_mastersStatus == 'completed') {
            return int.tryParse(_mastersYearCtrl.text.trim());
          }
          return null;
        }(),
        currentWorkplace: _workplaceCtrl.text.trim(),
        currentPosition: _positionCtrl.text.trim(),
        livesAbroad: _livesAbroad,
        country: _livesAbroad ? _countryCtrl.text.trim() : 'Bangladesh',
        alumniCardPhoto: _alumniCardPhoto!,
        transcriptPhoto: _transcriptPhoto!,
        works: worksList,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Application submitted! Pending admin review.'),
        backgroundColor: Colors.green,
      ));
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AlumniPage()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // BUILD
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
        title: const Text('Join as Alumni',
            style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your application will be reviewed by admin. Fill in accurate information.',
                        style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ── DEGREE TYPE ──
              _sectionTitle('Your Degree from This University'),
              const SizedBox(height: 6),
              const Text(
                'Hint: Which degree did you obtain from East West University?',
                style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              _buildDropdown<String>(
                value: _degreeType,
                label: 'Degree Type',
                items: const [
                  DropdownMenuItem(
                      value: 'graduation', child: Text('Graduation')),
                  DropdownMenuItem(
                      value: 'masters', child: Text('Masters')),
                  DropdownMenuItem(
                      value: 'both',
                      child: Text('Both (Graduation + Masters)')),
                ],
                onChanged: (val) => setState(() {
                  _degreeType = val ?? 'graduation';
                  _mastersStatus = '';
                }),
              ),

              const SizedBox(height: 26),

              // ── GRADUATION INFO ──
              // Show for 'graduation' and 'both'
              if (_degreeType == 'graduation' ||
                  _degreeType == 'both') ...[
                _sectionTitle('Graduation Information'),
                const SizedBox(height: 12),
                _buildReadOnly(
                    label: 'University',
                    value: 'East West University'),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _gradDepartmentCtrl,
                    label: 'Department',
                    hint: 'e.g. Computer Science & Engineering',
                    required: true),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _gradMajorCtrl,
                    label: 'Major Subject',
                    hint: 'e.g. Software Engineering',
                    required: true),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _gradYearCtrl,
                    label: 'Graduation Year',
                    hint: 'e.g. 2021',
                    required: true,
                    keyboard: TextInputType.number,
                    validator: _yearValidator),
                const SizedBox(height: 26),
              ],

              // ── MASTERS (when degree == 'masters') ──
              if (_degreeType == 'masters') ...[
                _sectionTitle('Graduation Information'),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _gradUniversityCtrl,
                    label: 'Graduation University',
                    hint: 'e.g. BUET, DU, BRAC University...',
                    required: true),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _gradDepartmentCtrl,
                    label: 'Department',
                    hint: 'e.g. Computer Science & Engineering',
                    required: true),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _gradMajorCtrl,
                    label: 'Major Subject',
                    hint: 'e.g. Software Engineering',
                    required: true),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _gradYearCtrl,
                    label: 'Graduation Year',
                    hint: 'e.g. 2018',
                    required: true,
                    keyboard: TextInputType.number,
                    validator: _yearValidator),
                const SizedBox(height: 26),
                _sectionTitle('Masters Information'),
                const SizedBox(height: 12),
                _buildReadOnly(
                    label: 'Masters University',
                    value: 'East West University'),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _mastersSubjectCtrl,
                    label: 'Masters Subject',
                    hint: 'e.g. Computer Science',
                    required: true),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _mastersYearCtrl,
                    label: 'Masters Completion Year',
                    hint: 'e.g. 2022',
                    required: true,
                    keyboard: TextInputType.number,
                    validator: _yearValidator),
                const SizedBox(height: 26),
              ],

              // ── BOTH ──
              if (_degreeType == 'both') ...[
                _sectionTitle('Masters Information'),
                const SizedBox(height: 12),
                _buildReadOnly(
                    label: 'Masters University',
                    value: 'East West University'),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _mastersSubjectCtrl,
                    label: 'Masters Subject',
                    hint: 'e.g. Computer Science',
                    required: true),
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _mastersYearCtrl,
                    label: 'Masters Completion Year',
                    hint: 'e.g. 2024',
                    required: true,
                    keyboard: TextInputType.number,
                    validator: _yearValidator),
                const SizedBox(height: 26),
              ],

              // ── MASTERS STATUS (only for 'graduation') ──
              if (_degreeType == 'graduation') ...[
                _sectionTitle('Masters Status'),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  value: _mastersStatus.isNotEmpty
                      ? _mastersStatus
                      : null,
                  label: 'Masters Status',
                  hint: 'Select your masters status',
                  items: const [
                    DropdownMenuItem(
                        value: 'ongoing',
                        child: Text('Ongoing')),
                    DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed')),
                    DropdownMenuItem(
                        value: 'not_started',
                        child: Text('I haven’t started yet.')),
                  ],
                  onChanged: (val) =>
                      setState(() => _mastersStatus = val ?? ''),
                ),

                if (_mastersStatus == 'ongoing') ...[
                  const SizedBox(height: 14),
                  _buildField(
                      ctrl: _mastersOngoingUniversityCtrl,
                      label: 'Masters University',
                      hint: 'e.g. DU, NSU, BRAC University...',
                      required: true),
                  const SizedBox(height: 12),
                  _buildField(
                      ctrl: _mastersOngoingSubjectCtrl,
                      label: 'Masters Subject',
                      hint: 'e.g. Computer Science',
                      required: true),
                ],

                if (_mastersStatus == 'completed') ...[
                  const SizedBox(height: 14),
                  _buildField(
                      ctrl: _mastersOngoingUniversityCtrl,
                      label: 'Masters University',
                      hint: 'e.g. DU, NSU, BRAC University...',
                      required: true),
                  const SizedBox(height: 12),
                  _buildField(
                      ctrl: _mastersSubjectCtrl,
                      label: 'Masters Subject',
                      hint: 'e.g. Computer Science',
                      required: true),
                  const SizedBox(height: 12),
                  _buildField(
                      ctrl: _mastersYearCtrl,
                      label: 'Masters Completion Year',
                      hint: 'e.g. 2023',
                      required: true,
                      keyboard: TextInputType.number,
                      validator: _yearValidator),
                ],

                const SizedBox(height: 26),
              ],

              // ── PROFESSIONAL INFO ──
              _sectionTitle('Professional Information'),
              const SizedBox(height: 14),
              _buildField(
                  ctrl: _workplaceCtrl,
                  label: 'Current Workplace',
                  hint: 'e.g. Google Bangladesh Ltd.'),
              const SizedBox(height: 12),
              _buildField(
                  ctrl: _positionCtrl,
                  label: 'Current Position',
                  hint: 'e.g. Senior Software Engineer'),

              const SizedBox(height: 26),

              // ── LOCATION ──
              _sectionTitle('Location'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                child: CheckboxListTile(
                  value: _livesAbroad,
                  onChanged: (val) =>
                      setState(() => _livesAbroad = val ?? false),
                  activeColor: AppColors.primary,
                  title: const Text('I currently live outside Bangladesh',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  subtitle: !_livesAbroad
                      ? const Text('Default: Bangladesh',
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 12))
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              if (_livesAbroad) ...[
                const SizedBox(height: 12),
                _buildField(
                    ctrl: _countryCtrl,
                    label: 'Country',
                    hint: 'e.g. United States',
                    required: true),
              ],

              const SizedBox(height: 26),

              // ── REMARKABLE WORKS ──
              _sectionTitle('Remarkable Works (Optional)'),
              const SizedBox(height: 6),
              const Text(
                  'Add up to 10 of your notable works, publications, or projects.',
                  style:
                  TextStyle(color: AppColors.mutedText, fontSize: 13)),
              const SizedBox(height: 14),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _works.length,
                itemBuilder: (context, i) => Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Work ${i + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                                fontSize: 13)),
                        const Spacer(),
                        if (_works.length > 2)
                          GestureDetector(
                            onTap: () => _removeWork(i),
                            child: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                                size: 20),
                          ),
                      ]),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _works[i]['title'],
                        decoration:
                        _decor('Work / Project Name'),
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _works[i]['link'],
                        keyboardType: TextInputType.url,
                        decoration:
                        _decor('Published Link (optional)'),
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              if (_works.length < 10)
                TextButton.icon(
                  onPressed: _addWork,
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 20),
                  label: const Text('Add Another Work',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),

              const SizedBox(height: 26),

              // ── VERIFICATION DOCUMENTS ──
              _sectionTitle('Verification Documents'),
              const SizedBox(height: 6),
              const Text(
                  'Upload clear photos of your alumni card and official transcript.',
                  style:
                  TextStyle(color: AppColors.mutedText, fontSize: 13)),
              const SizedBox(height: 14),
              _docTile(
                label: 'Alumni Card Photo',
                file: _alumniCardPhoto,
                required: true,
                onTap: () async {
                  final f = await _showImageSourceSheet();
                  if (f != null) setState(() => _alumniCardPhoto = f);
                },
                onRemove: () => setState(() => _alumniCardPhoto = null),
              ),
              const SizedBox(height: 12),
              _docTile(
                label: 'Official Transcript Photo',
                file: _transcriptPhoto,
                required: true,
                onTap: () async {
                  final f = await _showImageSourceSheet();
                  if (f != null) setState(() => _transcriptPhoto = f);
                },
                onRemove: () => setState(() => _transcriptPhoto = null),
              ),

              const SizedBox(height: 36),

              // ── SUBMIT ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : const Text('Submit Verification Request',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET HELPERS
  String? _yearValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final yr = int.tryParse(v);
    if (yr == null || yr < 1970 || yr > DateTime.now().year) {
      return 'Enter a valid year';
    }
    return null;
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.text));

  InputDecoration _decor(String hint, {String? label}) => InputDecoration(
    hintText: hint,
    labelText: label,
    hintStyle:
    const TextStyle(color: AppColors.mutedText, fontSize: 14),
    filled: true,
    fillColor: AppColors.inputFill,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: AppColors.primary, width: 1.5)),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(color: AppColors.text, fontSize: 14),
        decoration: _decor(hint ?? label, label: label),
        validator: validator ??
            (required
                ? (v) => (v == null || v.isEmpty)
                ? 'This field is required'
                : null
                : null),
      );

  Widget _buildReadOnly({required String label, required String value}) =>
      Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.mutedText, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.lock_outline,
                color: AppColors.mutedText, size: 16),
          ],
        ),
      );

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    String? hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) =>
      DropdownButtonFormField<T>(
        value: value,
        decoration: _decor(hint ?? label, label: label),
        style: const TextStyle(color: AppColors.text, fontSize: 14),
        icon: const Icon(Icons.keyboard_arrow_down,
            color: AppColors.mutedText),
        dropdownColor: Colors.white,
        items: items,
        onChanged: onChanged,
      );

  Widget _docTile({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    bool required = false,
  }) {
    if (file != null) {
      // ── ছবি selected হলে full preview দেখাবে ──
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              // Full image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  file,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              // Top-right buttons: Edit + Remove
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    // Edit button
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Remove button
                    GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Remove',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom success badge
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Photo selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ── ছবি নেই হলে upload tile দেখাবে ──
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.upload_file_outlined,
                  color: AppColors.mutedText, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    required ? 'Required — Tap to upload' : 'Tap to upload',
                    style: const TextStyle(
                        color: AppColors.mutedText, fontSize: 12),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      'Gallery or Camera',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.camera_alt_outlined,
                color: AppColors.mutedText, size: 20),
          ],
        ),
      ),
    );
  }
}
