import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'SendItemLocation.dart';
import 'services/auth_api_service.dart';

class SendItemForm extends StatefulWidget {
  const SendItemForm({super.key});

  @override
  State<SendItemForm> createState() => _SendItemFormState();
}

class _SendItemFormState extends State<SendItemForm> {
  final _formKey = GlobalKey<FormState>();
  final AuthApiService _authApiService = AuthApiService();

  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController senderPhoneController = TextEditingController();
  final TextEditingController receiverNameController = TextEditingController();
  final TextEditingController receiverPhoneController = TextEditingController();
  final TextEditingController receiverEmailController = TextEditingController();
  final TextEditingController itemWeightController = TextEditingController();

  String? selectedItem;
  bool isCheckingReceiver = false;

  final List<String> itemList = [
    "Book",
    "Assignment",
    "Research Paper",
    "Food",
    "Documents",
    "Laptop",
    "Clothes",
    "Medicine",
    "Parcel",
    "Others",
  ];

  String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter phone number";
    }

    final phone = value.trim();

    final only11Digits = RegExp(r'^01\d{9}$');
    final with88 = RegExp(r'^\+8801\d{9}$');

    if (only11Digits.hasMatch(phone) || with88.hasMatch(phone)) {
      return null;
    }

    return "Enter valid phone number";
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter email";
    }

    final email = value.trim().toLowerCase();

    final isStudent = email.endsWith('@std.ewubd.edu');
    final isFacultyOrStaff = email.endsWith('@ewubd.edu');

    if (!isStudent && !isFacultyOrStaff) {
      return "Enter valid university email";
    }

    return null;
  }

  Future<void> goToLocationPage() async {
    if (!_formKey.currentState!.validate() || selectedItem == null) {
      return;
    }

    setState(() {
      isCheckingReceiver = true;
    });

    try {
      final response = await _authApiService.validateSendItemReceiver(
        receiverEmail: receiverEmailController.text.trim(),
      );

      final receiverData = response['data'] ?? {};

      if (!mounted) return;

      setState(() {
        isCheckingReceiver = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendItemLocation(
            senderName: senderNameController.text.trim(),
            senderPhone: senderPhoneController.text.trim(),
            receiverName: receiverData['name']?.toString().isNotEmpty == true
                ? receiverData['name'].toString()
                : receiverNameController.text.trim(),
            receiverEmail: receiverData['receiver_email']?.toString() ??
                receiverEmailController.text.trim(),
            itemName: selectedItem!,
            itemWeight: itemWeightController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCheckingReceiver = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  void dispose() {
    senderNameController.dispose();
    senderPhoneController.dispose();
    receiverNameController.dispose();
    receiverPhoneController.dispose();
    receiverEmailController.dispose();
    itemWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        title: const Text(
          "Send Item",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: senderNameController,
                decoration: const InputDecoration(
                  labelText: "Sender Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Enter sender name" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: senderPhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: const InputDecoration(
                  labelText: "Sender Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: validatePhoneNumber,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: receiverNameController,
                decoration: const InputDecoration(
                  labelText: "Receiver Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: receiverPhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: const InputDecoration(
                  labelText: "Receiver Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: validatePhoneNumber,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: receiverEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Receiver Email",
                  border: OutlineInputBorder(),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedItem,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
                items: itemList
                    .map(
                      (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedItem = value;
                  });
                },
                validator: (value) => value == null ? "Select item" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: itemWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Item Weight (kg)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter weight";
                  }

                  final weight = double.tryParse(value.trim());

                  if (weight == null) {
                    return "Enter valid weight";
                  }

                  if (weight <= 0) {
                    return "Weight must be greater than 0";
                  }

                  return null;
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                  ),
                  onPressed: isCheckingReceiver ? null : goToLocationPage,
                  child: isCheckingReceiver
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}