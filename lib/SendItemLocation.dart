import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

class SendItemLocation extends StatefulWidget {
  final String receiverName;
  final String receiverEmail;
  final String itemName;
  final String itemWeight;

  const SendItemLocation({
    super.key,
    required this.receiverName,
    required this.receiverEmail,
    required this.itemName,
    required this.itemWeight,
  });

  @override
  State<SendItemLocation> createState() => _SendItemLocationState();
}

class _SendItemLocationState extends State<SendItemLocation> {

  final TextEditingController pickupController =
  TextEditingController();

  final TextEditingController destinationController =
  TextEditingController();

  bool get isFormValid =>
      pickupController.text.isNotEmpty &&
          destinationController.text.isNotEmpty;

  void confirmSendItem() async {

    // 🔥 এখানে backend API call দিবে
    print("===== SEND ITEM DATA =====");
    print("Receiver Name: ${widget.receiverName}");
    print("Receiver Email: ${widget.receiverEmail}");
    print("Item Name: ${widget.itemName}");
    print("Item Weight: ${widget.itemWeight}");
    print("Pickup: ${pickupController.text}");
    print("Destination: ${destinationController.text}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Email sent to receiver"),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Send Item",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [

            const SizedBox(height: 20),

            // Receiver Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.receiverName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CURRENT LOCATION (Editable)
            TextField(
              controller: pickupController,
              decoration: InputDecoration(
                hintText: "Enter Current Location",
                filled: true,
                fillColor: Colors.grey.shade200,
                prefixIcon: const Icon(Icons.my_location),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 15),

            // DESTINATION (Google Autocomplete)
            GooglePlaceAutoCompleteTextField(
              textEditingController: destinationController,
              googleAPIKey: "YOUR_GOOGLE_MAPS_API_KEY",
              inputDecoration: InputDecoration(
                hintText: "Where to?",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              debounceTime: 800,
              countries: const ["bd"],
              isLatLngRequired: false,
              itemClick: (prediction) {
                destinationController.text =
                prediction.description!;
                destinationController.selection =
                    TextSelection.fromPosition(
                      TextPosition(
                          offset:
                          prediction.description!.length),
                    );
                setState(() {});
              },
            ),

            const Spacer(),

            // CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isFormValid
                      ? Colors.black
                      : Colors.grey,
                ),
                onPressed:
                isFormValid ? confirmSendItem : null,
                child: const Text(
                  "Confirm",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}