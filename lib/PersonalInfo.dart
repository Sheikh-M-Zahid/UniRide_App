import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool isEditing = false;
  bool bloodGroupLocked = false;

  // Dummy data (Later database থেকে আনবে)
  String profileImageUrl = "";
  String firstName = "Zahid";
  String lastName = "Hossain";
  String occupation = "Student";

  final TextEditingController phoneController =
  TextEditingController(text: "01700000000");

  final TextEditingController presentAreaController =
  TextEditingController(text: "Narayanganj");

  final TextEditingController permanentAddressController =
  TextEditingController();

  String? selectedBloodGroup;

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

  Future<void> _pickImage() async {
    if (!isEditing) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        profileImageUrl = "";
      });
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    presentAreaController.dispose();
    permanentAddressController.dispose();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                      ? NetworkImage(profileImageUrl)
                      : null) as ImageProvider?,
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
                    onTap: _pickImage,
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
              value: "$firstName $lastName",
            ),

            const SizedBox(height: 15),

            /// ================= PHONE =================
            _buildTextField(
              label: "Phone Number",
              controller: phoneController,
              enabled: isEditing,
            ),

            const SizedBox(height: 15),

            /// ================= OCCUPATION (LOCKED) =================
            _buildReadOnlyField(
              label: "Occupation",
              value: occupation,
            ),

            const SizedBox(height: 15),

            /// ================= PRESENT AREA =================
            _buildTextField(
              label: "Present Area",
              controller: presentAreaController,
              enabled: isEditing,
            ),

            const SizedBox(height: 15),

            /// ================= PERMANENT ADDRESS (OPTIONAL) =================
            _buildTextField(
              label: "Permanent Address (Optional)",
              controller: permanentAddressController,
              enabled: isEditing,
            ),

            const SizedBox(height: 15),

            /// ================= BLOOD GROUP =================
            DropdownButtonFormField<String>(
              value: selectedBloodGroup,
              decoration: InputDecoration(
                labelText: "Blood Group (Optional)",
                labelStyle: const TextStyle(color: AppColors.mutedText),
                filled: true,
                fillColor:
                isEditing ? Colors.white : AppColors.inputFill,
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
              ),
              dropdownColor: Colors.white,
              items: bloodGroups
                  .map(
                    (group) => DropdownMenuItem(
                  value: group,
                  child: Text(
                    group,
                    style: const TextStyle(color: AppColors.text),
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
                onPressed: () {
                  setState(() {
                    if (isEditing && selectedBloodGroup != null) {
                      bloodGroupLocked = true;
                    }
                    isEditing = !isEditing;
                  });
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
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.mutedText),
        filled: true,
        fillColor: enabled ? Colors.white : AppColors.inputFill,
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
      ),
    );
  }
}