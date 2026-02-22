import 'package:flutter/material.dart';
import 'SendItemLocation.dart';

class SendItemForm extends StatefulWidget {
  const SendItemForm({super.key});

  @override
  State<SendItemForm> createState() => _SendItemFormState();
}

class _SendItemFormState extends State<SendItemForm> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController receiverNameController =
  TextEditingController();
  final TextEditingController receiverEmailController =
  TextEditingController();
  final TextEditingController itemWeightController =
  TextEditingController();

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

  void goToLocationPage() {
    if (_formKey.currentState!.validate() &&
        selectedItem != null) {

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
      appBar: AppBar(
        title: const Text("Send Item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: receiverNameController,
                decoration: const InputDecoration(
                  labelText: "Receiver Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Enter name" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: receiverEmailController,
                decoration: const InputDecoration(
                  labelText: "Receiver Email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.contains("@")
                    ? null
                    : "Enter valid email",
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedItem,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
                items: itemList
                    .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedItem = value;
                  });
                },
                validator: (value) =>
                value == null ? "Select item" : null,
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
                    backgroundColor: Colors.black,
                  ),
                  onPressed: goToLocationPage,
                  child: const Text("Next"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}