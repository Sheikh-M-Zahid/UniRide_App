import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class PrivateCarRegistration extends StatefulWidget {
  const PrivateCarRegistration({super.key});

  @override
  State<PrivateCarRegistration> createState() =>
      _PrivateCarRegistrationState();
}

class _PrivateCarRegistrationState
    extends State<PrivateCarRegistration> {

  final ImagePicker _picker = ImagePicker();

  String? selectedMake;
  String? selectedModel;
  String? selectedYear;
  final TextEditingController numberPlateController =
  TextEditingController();
  final TextEditingController otherMakeController =
  TextEditingController();
  final TextEditingController otherModelController =
  TextEditingController();

  File? varsityId;
  File? profilePhoto;
  File? drivingLicense;
  File? vehicleRegistration;
  File? taxToken;

  final List<String> makes = [
    "Toyota",
    "Honda",
    "Nissan",
    "Suzuki",
    "Hyundai",
    "Kia",
    "Mitsubishi",
    "Mazda",
    "BMW",
    "Mercedes-Benz",
    "Audi",
    "Lexus",
    "Tata",
    "Mahindra",
    "MG",
    "BYD",
    "Proton",
    "Chery",
    "DFSK",
    "Haval",
    "Others",
  ];

  final Map<String, List<String>> makeModels = {
    "Toyota": [
      "Corolla",
      "Allion",
      "Axio",
      "Premio",
      "Noah",
      "Esquire",
      "Voxy",
      "Fielder",
      "Aqua",
      "Prius",
      "Raize",
      "CHR",
      "Land Cruiser Prado",
      "Hiace",
      "Others",
    ],
    "Honda": [
      "Civic",
      "City",
      "Grace",
      "Vezel",
      "CR-V",
      "Accord",
      "Fit",
      "Freed",
      "Airwave",
      "BR-V",
      "Others",
    ],
    "Nissan": [
      "X-Trail",
      "Sunny",
      "Dayz",
      "Note",
      "Serena",
      "Patrol",
      "Juke",
      "Others",
    ],
    "Suzuki": [
      "Wagon R",
      "Swift",
      "Alto",
      "Ciaz",
      "Ertiga",
      "Every",
      "Spacia",
      "Baleno",
      "Others",
    ],
    "Hyundai": [
      "Tucson",
      "Creta",
      "Santa Fe",
      "Elantra",
      "Accent",
      "H1",
      "Venue",
      "Others",
    ],
    "Kia": [
      "Sportage",
      "Seltos",
      "Sorento",
      "Picanto",
      "Rio",
      "Carnival",
      "Others",
    ],
    "Mitsubishi": [
      "Pajero",
      "Montero",
      "Outlander",
      "Eclipse Cross",
      "L200",
      "Others",
    ],
    "Mazda": [
      "Axela",
      "CX-3",
      "CX-5",
      "CX-8",
      "Demio",
      "Premacy",
      "Others",
    ],
    "BMW": [
      "3 Series",
      "5 Series",
      "X1",
      "X3",
      "X5",
      "Others",
    ],
    "Mercedes-Benz": [
      "C-Class",
      "E-Class",
      "S-Class",
      "GLA",
      "GLC",
      "GLE",
      "Others",
    ],
    "Audi": [
      "A3",
      "A4",
      "A6",
      "Q3",
      "Q5",
      "Q7",
      "Others",
    ],
    "Lexus": [
      "RX",
      "NX",
      "LX",
      "ES",
      "Others",
    ],
    "Tata": [
      "Tiago",
      "Tigor",
      "Nexon",
      "Harrier",
      "Others",
    ],
    "Mahindra": [
      "XUV300",
      "XUV700",
      "Scorpio",
      "Bolero",
      "Others",
    ],
    "MG": [
      "ZS",
      "HS",
      "MG4",
      "Others",
    ],
    "BYD": [
      "Atto 3",
      "Seal",
      "Sealion 6",
      "Sealion 7",
      "Others",
    ],
    "Proton": [
      "Saga",
      "X50",
      "X70",
      "Others",
    ],
    "Chery": [
      "Tiggo 4 Pro",
      "Tiggo 7 Pro",
      "Others",
    ],
    "DFSK": [
      "Glory 560",
      "Glory 580",
      "Others",
    ],
    "Haval": [
      "Jolion",
      "H6",
      "Others",
    ],
    "Others": ["Others"],
  };

  List<String> get models =>
      selectedMake != null ? (makeModels[selectedMake!] ?? ["Others"]) : [];
  List<String> years =
  List.generate(20, (index) => (2025 - index).toString());

  bool get isFormComplete {
    final bool makeOk = selectedMake != null &&
        (selectedMake == "Others"
            ? otherMakeController.text.trim().isNotEmpty
            : true);

    final bool modelOk = selectedMake == "Others"
        ? otherModelController.text.trim().isNotEmpty
        : selectedModel != null &&
        (selectedModel == "Others"
            ? otherModelController.text.trim().isNotEmpty
            : true);

    return makeOk &&
        modelOk &&
        selectedYear != null &&
        numberPlateController.text.isNotEmpty &&
        varsityId != null &&
        profilePhoto != null &&
        drivingLicense != null &&
        vehicleRegistration != null &&
        taxToken != null;
  }

  Future<void> requestCameraPermission() async {
    await Permission.camera.request();
  }

  Future<void> pickFromCamera(Function(File) onPicked) async {
    await requestCameraPermission();
    final XFile? image =
    await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      onPicked(File(image.path));
    }
  }

  Future<void> pickFromGallery(Function(File) onPicked) async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      onPicked(File(image.path));
    }
  }

  void showImageSourceDialog(Function(File) onPicked) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primary,
              ),
              title: const Text(
                "Camera",
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.pop(context);
                pickFromCamera(onPicked);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo,
                color: AppColors.primary,
              ),
              title: const Text(
                "Gallery",
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.pop(context);
                pickFromGallery(onPicked);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUploadTile(
      String title, File? file, Function(File) onPicked,
      {bool cameraOnly = false, bool galleryOnly = false}) {

    return GestureDetector(
      onTap: () {
        if (cameraOnly) {
          pickFromCamera(onPicked);
        } else if (galleryOnly) {
          pickFromGallery(onPicked);
        } else {
          showImageSourceDialog(onPicked);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null
                ? AppColors.primary
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
            if (file != null)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.mutedText,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "UniRide",
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              "Help",
              style: TextStyle(color: AppColors.primary),
            ),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            const Text(
              "Enter your vehicle information",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 25),

            DropdownButtonFormField<String>(
              value: selectedMake,
              decoration: InputDecoration(
                labelText: "Make",
                labelStyle: const TextStyle(color: AppColors.mutedText),
                filled: true,
                fillColor: Colors.white,
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
              ),
              items: makes
                  .map(
                    (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(color: AppColors.text),
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedMake = value;
                  selectedModel = null;
                  otherMakeController.clear();
                  otherModelController.clear();
                });
              },
            ),

            const SizedBox(height: 15),

            if (selectedMake == "Others") ...[
              TextField(
                controller: otherModelController,
                decoration: InputDecoration(
                  labelText: "Write Your Car Model",
                  labelStyle: const TextStyle(color: AppColors.mutedText),
                  filled: true,
                  fillColor: Colors.white,
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
                ),
                onChanged: (_) => setState(() {}),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: selectedModel,
                decoration: InputDecoration(
                  labelText: "Model",
                  labelStyle: const TextStyle(color: AppColors.mutedText),
                  filled: true,
                  fillColor: Colors.white,
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
                ),
                items: models
                    .map(
                      (e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      e,
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedModel = value;
                    otherModelController.clear();
                  });
                },
              ),
              if (selectedModel == "Others") ...[
                const SizedBox(height: 15),
                TextField(
                  controller: otherModelController,
                  decoration: InputDecoration(
                    labelText: "Write Your Car Model",
                    labelStyle: const TextStyle(color: AppColors.mutedText),
                    filled: true,
                    fillColor: Colors.white,
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
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],

            const SizedBox(height: 15),

            DropdownButtonFormField(
              value: selectedYear,
              decoration: InputDecoration(
                labelText: "Year",
                labelStyle: const TextStyle(color: AppColors.mutedText),
                filled: true,
                fillColor: Colors.white,
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
              ),
              items: years
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(color: AppColors.text),
                ),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                });
              },
            ),

            const SizedBox(height: 15),

            if (selectedMake == "Others") ...[
              TextField(
                controller: otherMakeController,
                decoration: InputDecoration(
                  labelText: "Write Your Car Brand",
                  labelStyle: const TextStyle(color: AppColors.mutedText),
                  filled: true,
                  fillColor: Colors.white,
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
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 15),
            ],

            TextField(
              controller: numberPlateController,
              decoration: InputDecoration(
                labelText: "Number Plate",
                labelStyle: const TextStyle(color: AppColors.mutedText),
                filled: true,
                fillColor: Colors.white,
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
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 30),

            const Text(
              "Upload Documents",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 15),

            buildUploadTile(
              "Varsity ID Card",
              varsityId,
                  (file) => setState(() => varsityId = file),
              cameraOnly: true,
            ),

            buildUploadTile(
              "Profile Photo",
              profilePhoto,
                  (file) => setState(() => profilePhoto = file),
              galleryOnly: true,
            ),

            buildUploadTile(
              "Driving License",
              drivingLicense,
                  (file) => setState(() => drivingLicense = file),
            ),

            buildUploadTile(
              "Vehicle Registration",
              vehicleRegistration,
                  (file) => setState(() => vehicleRegistration = file),
            ),

            buildUploadTile(
              "Vehicle Tax Token",
              taxToken,
                  (file) => setState(() => taxToken = file),
            ),



            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormComplete
                      ? AppColors.primary
                      : AppColors.mutedText,
                ),
                onPressed: isFormComplete
                    ? () {
                  Navigator.pop(context);
                }
                    : null,
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    numberPlateController.dispose();
    otherMakeController.dispose();
    otherModelController.dispose();
    super.dispose();
  }
}