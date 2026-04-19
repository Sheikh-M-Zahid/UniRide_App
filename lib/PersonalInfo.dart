import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final AuthApiService _authApiService = AuthApiService();

  bool isEditing = false;
  bool bloodGroupLocked = false;
  bool isSaving = false;

  String profileImageUrl = "";
  String firstName = "";
  String lastName = "";
  String occupation = "";
  String universityEmail = "";

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController secondaryPhoneController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();
  final TextEditingController presentAreaController = TextEditingController();
  final TextEditingController permanentAddressController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();

  String? selectedBloodGroup;
  String? selectedGender;

  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-"
  ];

  final List<String> genderList = [
    "Male",
    "Female",
  ];

  Future<bool> _requestPermission(ImageSource source) async {
    Permission permission;

    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      if (Platform.isAndroid) {
        permission = Permission.storage;
      } else {
        permission = Permission.photos;
      }
    }

    PermissionStatus status = await permission.status;

    if (status.isGranted) return true;

    status = await permission.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Permission permanently denied. Please enable it from settings.",
          ),
        ),
      );
      await openAppSettings();
    }

    return false;
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    if (!isEditing) return;

    final hasPermission = await _requestPermission(source);
    if (!hasPermission) return;

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        profileImageUrl = "";
      });
    }
  }

  void _showImageOptions() {
    if (!isEditing) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library,
                      color: AppColors.primary),
                  title: const Text("Choose from Gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt,
                      color: AppColors.primary),
                  title: const Text("Take a Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.camera);
                  },
                ),
                if (_imageFile != null || profileImageUrl.isNotEmpty)
                  ListTile(
                    leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text("Remove Photo"),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imageFile = null;
                        profileImageUrl = "";
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDateOfBirth() async {
    if (!isEditing) return;

    DateTime initialDate = DateTime(2000, 1, 1);

    if (dateOfBirthController.text.isNotEmpty) {
      final raw = dateOfBirthController.text.trim();
      final safe = raw.length >= 10 ? raw.substring(0, 10) : raw;
      final parsed = DateTime.tryParse(safe);
      if (parsed != null) {
        initialDate = parsed;
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        dateOfBirthController.text =
        "${pickedDate.year.toString().padLeft(4, '0')}-"
            "${pickedDate.month.toString().padLeft(2, '0')}-"
            "${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  String? _phoneValidator(String? value, {bool isRequired = true}) {
    final text = value?.trim() ?? '';

    if (!isRequired && text.isEmpty) return null;

    if (text.isEmpty) {
      return 'This field is required';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(text)) {
      return 'Only digits are allowed';
    }

    if (text.length < 11) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _authApiService.getMyProfile();
      final data = response['data'];

      if (!mounted) return;

      setState(() {
        firstName = (data['first_name'] ?? data['firstName'] ?? '').toString();
        lastName = (data['last_name'] ?? data['lastName'] ?? '').toString();
        occupation = (data['occupation'] ?? '').toString();

        universityEmail =
            (data['university_email'] ?? data['universityEmail'] ?? '').toString();

        final rawProfilePicture =
        (data['profile_picture'] ?? data['profilePicture'] ?? '').toString();
        profileImageUrl = rawProfilePicture;

        phoneController.text = (data['phone'] ?? '').toString();

        secondaryPhoneController.text =
            (data['recovery_phone'] ?? data['secondaryPhoneNumber'] ?? '')
                .toString();

        emergencyContactController.text =
            (data['emergency_phone'] ?? data['emergencyContactNumber'] ?? '')
                .toString();

        presentAreaController.text =
            (data['hostel_address'] ?? '').toString();

        permanentAddressController.text =
            (data['home_address'] ?? '').toString();

        /// ✅ DATE FIX
        final rawDob =
        (data['date_of_birth'] ?? data['dateOfBirth'] ?? '').toString();

        dateOfBirthController.text =
        rawDob.isNotEmpty && rawDob.length >= 10
            ? rawDob.substring(0, 10)
            : rawDob;

        /// ✅ GENDER FIX
        final rawGender = (data['gender'] ?? '').toString().trim();
        selectedGender = rawGender.isNotEmpty
            ? "${rawGender[0].toUpperCase()}${rawGender.substring(1).toLowerCase()}"
            : null;

        /// ✅ BLOOD GROUP FIX
        selectedBloodGroup =
        (data['blood_group'] ?? '').toString().trim().isNotEmpty
            ? data['blood_group'].toString()
            : null;

        bloodGroupLocked = selectedBloodGroup != null &&
            selectedBloodGroup!.trim().isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile')),
      );
    }
  }

  Future<void> _saveInformation() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isSaving = true;
    });

    try {
      await _authApiService.updateMyProfile(
        phone: phoneController.text.trim(),
        recoveryPhone: secondaryPhoneController.text.trim(),
        emergencyPhone: emergencyContactController.text.trim(),
        gender: (selectedGender ?? '').toLowerCase(),
        dateOfBirth: dateOfBirthController.text.trim(),
        homeAddress: permanentAddressController.text.trim(),
        hostelAddress: presentAreaController.text.trim(),
        campusAddress: '',
        bloodGroup: bloodGroupLocked ? null : selectedBloodGroup,
      );

      if (_imageFile != null) {
        final imageResponse = await _authApiService.updateProfilePicture(_imageFile!);
        final updatedPath = (imageResponse['data']?['profilePicture'] ??
            imageResponse['data']?['profile_picture'] ??
            '')
            .toString();

        if (updatedPath.isNotEmpty) {
          profileImageUrl = updatedPath;
        }
      }

      if (!mounted) return;

      setState(() {
        if (selectedBloodGroup != null) {
          bloodGroupLocked = true;
        }
        isEditing = false;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Information updated successfully"),
        ),
      );
      Navigator.pop(context, {
        'gender': selectedGender,
        'emergencyContactNumber': emergencyContactController.text.trim(),
        'universityEmail': universityEmail,
        'dateOfBirth': dateOfBirthController.text.trim(),
        'secondaryPhoneNumber': secondaryPhoneController.text.trim(),
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    phoneController.dispose();
    secondaryPhoneController.dispose();
    emergencyContactController.dispose();
    presentAreaController.dispose();
    permanentAddressController.dispose();
    dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Personal Information",
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// ================= PROFILE IMAGE =================
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: AppColors.inputFill,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (profileImageUrl.isNotEmpty
                            ? NetworkImage(_authApiService.getFullImageUrl(profileImageUrl))
                            : null)
                        as ImageProvider?,
                        child: (_imageFile == null && profileImageUrl.isEmpty)
                            ? const Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.mutedText,
                        )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageOptions,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isEditing
                                  ? AppColors.primary
                                  : AppColors.mutedText,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// ================= FULL NAME =================
                  _buildReadOnlyField(
                    label: "Full Name",
                    value: "$firstName $lastName".trim(),
                  ),

                  const SizedBox(height: 15),

                  /// ================= UNIVERSITY EMAIL =================
                  _buildReadOnlyField(
                    label: "University Email",
                    value: universityEmail,
                  ),

                  const SizedBox(height: 15),

                  /// ================= PHONE =================
                  _buildTextField(
                    label: "Phone Number",
                    controller: phoneController,
                    enabled: isEditing,
                    keyboardType: TextInputType.phone,
                    validator: (value) => _phoneValidator(value),
                  ),

                  const SizedBox(height: 15),

                  /// ================= SECONDARY PHONE =================
                  _buildTextField(
                    label: "Secondary Phone Number (Optional)",
                    controller: secondaryPhoneController,
                    enabled: isEditing,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        _phoneValidator(value, isRequired: false),
                  ),

                  const SizedBox(height: 15),

                  /// ================= EMERGENCY CONTACT =================
                  _buildTextField(
                    label: "Emergency Contact Number",
                    controller: emergencyContactController,
                    enabled: isEditing,
                    keyboardType: TextInputType.phone,
                    validator: (value) => _phoneValidator(value),
                  ),

                  const SizedBox(height: 15),

                  /// ================= OCCUPATION (LOCKED) =================
                  _buildReadOnlyField(
                    label: "Occupation",
                    value: occupation,
                  ),

                  const SizedBox(height: 15),

                  /// ================= GENDER =================
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: InputDecoration(
                      labelText: "Gender",
                      labelStyle:
                      const TextStyle(color: AppColors.mutedText),
                      filled: true,
                      fillColor:
                      isEditing ? Colors.white : AppColors.inputFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColors.border),
                      ),
                    ),
                    dropdownColor: Colors.white,
                    items: genderList
                        .map(
                          (gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(
                          gender,
                          style:
                          const TextStyle(color: AppColors.text),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: isEditing
                        ? (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    }
                        : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  /// ================= DATE OF BIRTH =================
                  GestureDetector(
                    onTap: isEditing ? _selectDateOfBirth : null,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        label: "Date of Birth",
                        controller: dateOfBirthController,
                        enabled: isEditing,
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Date of birth is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// ================= PRESENT AREA =================
                  _buildTextField(
                    label: "Present Area",
                    controller: presentAreaController,
                    enabled: isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Present area is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  /// ================= PERMANENT ADDRESS (OPTIONAL) =================
                  _buildTextField(
                    label: "Permanent Address",
                    controller: permanentAddressController,
                    enabled: isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Permanent address is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  /// ================= BLOOD GROUP =================
                  DropdownButtonFormField<String>(
                    value: selectedBloodGroup,
                    decoration: InputDecoration(
                      labelText: "Blood Group (Optional)",
                      labelStyle:
                      const TextStyle(color: AppColors.mutedText),
                      filled: true,
                      fillColor:
                      isEditing ? Colors.white : AppColors.inputFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColors.border),
                      ),
                    ),
                    dropdownColor: Colors.white,
                    items: bloodGroups
                        .map(
                          (group) => DropdownMenuItem(
                        value: group,
                        child: Text(
                          group,
                          style:
                          const TextStyle(color: AppColors.text),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (isEditing && !bloodGroupLocked)
                        ? (value) {
                      setState(() {
                        selectedBloodGroup = value;
                      });
                    }
                        : null,
                  ),

                  const SizedBox(height: 30),

                  /// ================= EDIT BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                        if (isEditing) {
                          await _saveInformation();
                        } else {
                          setState(() {
                            isEditing = true;
                          });
                        }
                      },
                      child: Text(
                        isEditing ? "Save Changes" : "Edit Information",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ================= DATABASE SYNC LOADING INDICATOR =================
          if (isSaving)
            Container(
              color: Colors.black.withOpacity(0.12),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Syncing with database...",
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ================= READ ONLY FIELD =================
  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.mutedText),
        filled: true,
        fillColor: AppColors.inputFill,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  /// ================= EDITABLE FIELD =================
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.text),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.mutedText),
        filled: true,
        fillColor: enabled ? Colors.white : AppColors.inputFill,
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}