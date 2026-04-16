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

class BikeRegistration extends StatefulWidget {
  const BikeRegistration({super.key});

  @override
  State<BikeRegistration> createState() => _BikeRegistrationState();
}

class _BikeRegistrationState extends State<BikeRegistration> {
  final ImagePicker _picker = ImagePicker();
  final AuthApiService _authApiService = AuthApiService();
  bool isSubmitting = false;

  String? selectedBrand;
  String? selectedModel;
  String? selectedYear;
  final TextEditingController numberPlateController =
  TextEditingController();
  final TextEditingController otherBrandController =
  TextEditingController();
  final TextEditingController otherModelController =
  TextEditingController();

  File? varsityId;
  File? profilePhoto;
  File? drivingLicense;
  File? vehicleRegistration;
  File? taxToken;

  final List<String> brands = [
    "Yamaha",
    "Honda",
    "Suzuki",
    "Bajaj",
    "TVS",
    "Hero",
    "Runner",
    "Lifan",
    "Keeway",
    "Roadmaster",
    "H Power",
    "PHP",
    "Speeder",
    "Walton",
    "Benelli",
    "KTM",
    "Royal Enfield",
    "GPX",
    "CFMOTO",
    "Others",
  ];

  final Map<String, List<String>> brandModels = {
    "Yamaha": [
      "R15 V3",
      "R15 V4",
      "R15M",
      "FZS V3",
      "FZS V2",
      "FZ-X",
      "MT-15",
      "Saluto",
      "Ray ZR",
      "Fascino",
      "Others",
    ],
    "Honda": [
      "CB Hornet 160R",
      "CB Shine",
      "SP 125",
      "CBR 150R",
      "CBR 150R ABS",
      "Livo",
      "XBlade",
      "Dream 110",
      "Dio",
      "Others",
    ],
    "Suzuki": [
      "Gixxer",
      "Gixxer SF",
      "Gixxer Monotone",
      "GSX-R150",
      "GSX-S150",
      "Intruder",
      "Hayate EP",
      "Access 125",
      "Burgman Street",
      "Others",
    ],
    "Bajaj": [
      "Pulsar 150",
      "Pulsar NS160",
      "Pulsar N160",
      "Pulsar 220F",
      "Discover 125",
      "Platina 100",
      "CT 100",
      "Avenger Street 160",
      "Others",
    ],
    "TVS": [
      "Apache RTR 160 4V",
      "Apache RTR 160",
      "Apache RTR 165 RP",
      "Apache RTR 180",
      "Apache RTR 200 4V",
      "TVS Raider 125",
      "Metro Plus",
      "Stryker",
      "NTorq 125",
      "Jupiter",
      "Others",
    ],
    "Hero": [
      "Hunk",
      "Splendor Plus",
      "Passion Pro",
      "Ignitor",
      "Glamour",
      "Xtreme 160R",
      "Pleasure",
      "Destini 125",
      "Others",
    ],
    "Runner": [
      "Knight Rider",
      "Bullet",
      "Turbo 125",
      "Cheeta",
      "Skooty",
      "Freedom",
      "AD80S",
      "Others",
    ],
    "Lifan": [
      "KPR 165R",
      "KPT 150",
      "Glint 100",
      "KP Mini",
      "Others",
    ],
    "Keeway": [
      "RKS 150",
      "RKR 165",
      "K-Light",
      "Benda Darkflag",
      "Others",
    ],
    "Roadmaster": [
      "Prime 100",
      "Rapido 150",
      "Velocity",
      "Delight",
      "Others",
    ],
    "H Power": [
      "125",
      "Zaara 110",
      "Recover",
      "Robot",
      "Others",
    ],
    "PHP": [
      "Merkaba",
      "Pride",
      "Commando",
      "Others",
    ],
    "Speeder": [
      "NSX 165R",
      "Countryman",
      "Big Monster",
      "Others",
    ],
    "Walton": [
      "Fusion 125",
      "Stylex",
      "Others",
    ],
    "Benelli": [
      "TNT 150",
      "TNT 135",
      "TRK 251",
      "Others",
    ],
    "KTM": [
      "Duke 125",
      "Duke 200",
      "RC 125",
      "RC 200",
      "Others",
    ],
    "Royal Enfield": [
      "Classic 350",
      "Meteor 350",
      "Hunter 350",
      "Bullet 350",
      "Others",
    ],
    "GPX": [
      "Demon",
      "Legend",
      "Raptor",
      "Others",
    ],
    "CFMOTO": [
      "150NK",
      "250NK",
      "300SR",
      "Others",
    ],
    "Others": ["Others"],
  };

  List<String> get models =>
      selectedBrand != null ? (brandModels[selectedBrand!] ?? ["Others"]) : [];
  List<String> years =
  List.generate(20, (index) => (DateTime.now().year - index).toString());

  bool get isFormComplete {
    final bool brandOk = selectedBrand != null &&
        (selectedBrand == "Others"
            ? otherBrandController.text.trim().isNotEmpty
            : true);

    final bool modelOk = selectedBrand == "Others"
        ? otherModelController.text.trim().isNotEmpty
        : selectedModel != null &&
        (selectedModel == "Others"
            ? otherModelController.text.trim().isNotEmpty
            : true);

    return brandOk &&
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
      String title,
      File? file,
      Function(File) onPicked, {
        bool galleryOnly = false,
      }) {
    return GestureDetector(
      onTap: () {
        if (galleryOnly) {
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
            color: file != null ? AppColors.primary : AppColors.border,
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

  String get finalBrand {
    if (selectedBrand == "Others") {
      return otherBrandController.text.trim();
    }
    return selectedBrand?.trim() ?? '';
  }

  String get finalModel {
    if (selectedBrand == "Others") {
      return otherModelController.text.trim();
    }

    if (selectedModel == "Others") {
      return otherModelController.text.trim();
    }

    return selectedModel?.trim() ?? '';
  }

  Future<void> submitBikeRegistration() async {
    if (!isFormComplete || isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await _authApiService.registerBike(
        company: finalBrand,
        model: finalModel,
        year: selectedYear!.trim(),
        numberPlate: numberPlateController.text.trim(),
        varsityIdPhoto: varsityId!,
        driverProfilePhoto: profilePhoto!,
        drivingLicensePhoto: drivingLicense!,
        vehicleRegistrationPhoto: vehicleRegistration!,
        taxTokenPhoto: taxToken!,
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      final data = response['data'] ?? {};
      final status = data['status']?.toString() ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'pending_verification'
                ? 'Bike registration submitted. Please wait for admin verification.'
                : 'Bike registration submitted successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= BIKE IMAGE =================
            Center(
              child: Icon(
                Icons.motorcycle,
                size: 90,
                color: AppColors.secondary,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Enter your bike information",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 25),

            DropdownButtonFormField(
              value: selectedBrand,
              decoration: InputDecoration(
                labelText: "Brand",
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
              items: brands
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
                  selectedBrand = value;
                  selectedModel = null;
                  otherBrandController.clear();
                  otherModelController.clear();
                });
              },
            ),

            const SizedBox(height: 15),

            if (selectedBrand == "Others") ...[
              TextField(
                controller: otherBrandController,
                decoration: InputDecoration(
                  labelText: "Write Your Bike Brand",
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

            if (selectedBrand == "Others") ...[
              TextField(
                controller: otherModelController,
                decoration: InputDecoration(
                  labelText: "Write Your Bike Model",
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
              DropdownButtonFormField(
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
                    labelText: "Write Your Bike Model",
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

            TextField(
              controller: numberPlateController,
              textCapitalization: TextCapitalization.characters,
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
                  backgroundColor: (isFormComplete && !isSubmitting)
                      ? AppColors.primary
                      : AppColors.mutedText,
                ),
                onPressed: (isFormComplete && !isSubmitting)
                    ? submitBikeRegistration
                    : null,
                child: isSubmitting
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : const Text(
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
    otherBrandController.dispose();
    otherModelController.dispose();
    super.dispose();
  }
}