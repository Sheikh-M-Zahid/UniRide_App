import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  List<String> bloodGroups = [
    "A+","A-","B+","B-","AB+","AB-","O+","O-"
  ];

  @override
  Widget build(BuildContext context) {
    Future<void> _pickImage() async {
      final pickedFile =
      await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Personal Information",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? const Icon(Icons.person,
                      size: 60, color: Colors.grey)
                      : null,
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      if (isEditing) {
                        // image picker logic later
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isEditing ? Colors.black : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          size: 18, color: Colors.white),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: bloodGroups
                  .map((group) => DropdownMenuItem(
                value: group,
                child: Text(group),
              ))
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
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                      color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= READ ONLY FIELD =================
  Widget _buildReadOnlyField(
      {required String label, required String value}) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
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
      decoration: InputDecoration(
        labelText: label,
        border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}