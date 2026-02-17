import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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

  File? varsityId;
  File? profilePhoto;
  File? drivingLicense;
  File? vehicleRegistration;
  File? taxToken;

  List<String> makes = ["Toyota", "Honda", "Nissan"];
  List<String> models = ["Corolla", "Civic", "X-Trail"];
  List<String> years =
  List.generate(20, (index) => (2025 - index).toString());

  bool get isFormComplete =>
      selectedMake != null &&
          selectedModel != null &&
          selectedYear != null &&
          numberPlateController.text.isNotEmpty &&
          varsityId != null &&
          profilePhoto != null &&
          drivingLicense != null &&
          vehicleRegistration != null &&
          taxToken != null;

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
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                pickFromCamera(onPicked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Gallery"),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null
                ? Colors.green
                : Colors.grey.shade300,
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
                    fontWeight: FontWeight.w500),
              ),
            ),
            if (file != null)
              const Icon(Icons.check_circle,
                  color: Colors.green)
            else
              const Icon(Icons.arrow_forward_ios,
                  size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "UniRide",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("Help",
                style: TextStyle(color: Colors.black)),
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
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            DropdownButtonFormField(
              value: selectedMake,
              decoration:
              const InputDecoration(labelText: "Make"),
              items: makes
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedMake = value;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField(
              value: selectedModel,
              decoration:
              const InputDecoration(labelText: "Model"),
              items: models
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedModel = value;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField(
              value: selectedYear,
              decoration:
              const InputDecoration(labelText: "Year"),
              items: years
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
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
              decoration:
              const InputDecoration(labelText: "Number Plate"),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 30),

            const Text(
              "Upload Documents",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
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
                  (file) =>
                  setState(() => vehicleRegistration = file),
            ),

            buildUploadTile(
              "Vehicle Tax Token",
              taxToken,
                  (file) =>
                  setState(() => taxToken = file),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isFormComplete
                      ? Colors.black
                      : Colors.grey,
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
                      fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}