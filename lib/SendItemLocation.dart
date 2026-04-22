import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_picker_screen.dart';
import 'UserHome.dart';
import 'services/auth_api_service.dart';

class SendItemLocation extends StatefulWidget {
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverEmail;
  final String itemName;
  final String itemWeight;

  const SendItemLocation({
    super.key,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverEmail,
    required this.itemName,
    required this.itemWeight,
  });

  @override
  State<SendItemLocation> createState() => _SendItemLocationState();
}

class _SendItemLocationState extends State<SendItemLocation> {
  final AuthApiService _authApiService = AuthApiService();
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  LatLng? pickupLatLng;
  LatLng? destinationLatLng;
  bool isSubmitting = false;

  bool get isFormValid =>
      pickupController.text.isNotEmpty &&
          destinationController.text.isNotEmpty;

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickPickupLocation() async {
    final LatLng initialPosition =
        pickupLatLng ?? const LatLng(23.8103, 90.4125);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: "AIzaSyCF5mVtZ2woOu8P1Jwf-7IfzRw_QoPilCI",
          initialPosition: initialPosition,
          title: "Select Item Sender Location",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        pickupController.text = result["address"];
        pickupLatLng = result["latLng"];
      });
    }
  }

  Future<void> _pickDestinationLocation() async {
    final LatLng initialPosition =
        destinationLatLng ??
            pickupLatLng ??
            const LatLng(23.8103, 90.4125);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          googleApiKey: "YOUR_GOOGLE_MAPS_API_KEY",
          initialPosition: initialPosition,
          title: "Select Receiver Location",
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        destinationController.text = result["address"];
        destinationLatLng = result["latLng"];
      });
    }
  }

  Future<void> confirmSendItem() async {
    if (!isFormValid) return;

    if (pickupLatLng == null || destinationLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both locations from map")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await _authApiService.createSendItemRequest(
        receiverEmail: widget.receiverEmail,
        itemType: widget.itemName,
        itemWeight: widget.itemWeight,
        senderName: widget.senderName,
        senderPhone: widget.senderPhone,
        pickupLocation: pickupController.text.trim(),
        dropLocation: destinationController.text.trim(),
        pickupLat: pickupLatLng!.latitude,
        pickupLng: pickupLatLng!.longitude,
        destinationLat: destinationLatLng!.latitude,
        destinationLng: destinationLatLng!.longitude,
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Send item request created successfully"),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const UniRideHomePage(),
        ),
            (route) => false,
      );
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Send Item",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE6FFFA),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.receiverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickPickupLocation,
              child: AbsorbPointer(
                child: TextField(
                  controller: pickupController,
                  decoration: InputDecoration(
                    hintText: "Item Sender Location",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.my_location,
                      color: Color(0xFF0F766E),
                    ),
                    suffixIcon: IconButton(
                      onPressed: _pickPickupLocation,
                      icon: const Icon(
                        Icons.map_outlined,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF14B8A6),
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Tap to pick item sender location from map.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(height: 15),

            GestureDetector(
              onTap: _pickDestinationLocation,
              child: AbsorbPointer(
                child: TextField(
                  controller: destinationController,
                  decoration: InputDecoration(
                    hintText: "Receiver Location",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Color(0xFF0F766E),
                    ),
                    suffixIcon: IconButton(
                      onPressed: _pickDestinationLocation,
                      icon: const Icon(
                        Icons.map_outlined,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF14B8A6),
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Tap to pick receiver location from map.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isFormValid ? const Color(0xFF14B8A6) : Colors.grey,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (isFormValid && !isSubmitting) ? confirmSendItem : null,
                child: isSubmitting
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  "Confirm",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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