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

  Widget _feeRow(String label, String fee) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
            ),
          ),
          Text(
            fee,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 15),

              // ── Delivery Fee Chart ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FFFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF0F766E),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Delivery Fee Structure",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _feeRow("Up to 2 kg", "৳50"),
                    _feeRow("2 – 3 kg", "৳60"),
                    _feeRow("3 – 4 kg", "৳70"),
                    _feeRow("4 – 5 kg", "৳80"),
                    _feeRow("Each extra 1 kg", "+৳10"),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Next Button ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isCheckingReceiver ? null : goToLocationPage,
                  child: isCheckingReceiver
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
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
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}