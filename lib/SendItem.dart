import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'SendItemLocation.dart';

class SendItemForm extends StatefulWidget {
  const SendItemForm({super.key});

  @override
  State<SendItemForm> createState() => _SendItemFormState();
}

class _SendItemFormState extends State<SendItemForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController senderPhoneController = TextEditingController();
  final TextEditingController receiverNameController = TextEditingController();
  final TextEditingController receiverPhoneController = TextEditingController();
  final TextEditingController receiverEmailController = TextEditingController();
  final TextEditingController itemWeightController = TextEditingController();

  String? selectedItem;

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

    final email = value.trim();
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

    if (!emailRegex.hasMatch(email)) {
      return "Enter valid email";
    }

    return null;
  }

  void goToLocationPage() {
    if (_formKey.currentState!.validate() && selectedItem != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendItemLocation(
            receiverName: receiverNameController.text,
            receiverEmail: receiverEmailController.text,
            itemName: selectedItem!,
            itemWeight: itemWeightController.text,
          ),
        ),
      );
    }
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
                validator: (value) =>
                value!.isEmpty ? "Enter weight" : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                  ),
                  onPressed: goToLocationPage,
                  child: const Text(
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