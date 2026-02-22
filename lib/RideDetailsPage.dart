import 'package:flutter/material.dart';
import 'ChatPage.dart';

class RideDetailsPage extends StatelessWidget {

  final String rideOwnerName;

  const RideDetailsPage({
    super.key,
    required this.rideOwnerName,
  });

  void acceptRide(BuildContext context) {

    // 🔥 backend এ seat কমাবে
    // 🔥 chat room create করবে

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatPage(receiverName: rideOwnerName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Ride Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const Text(
              "Ride Information Here",
              style: TextStyle(fontSize: 18),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => acceptRide(context),
                child: const Text("Accept Ride"),
              ),
            )
          ],
        ),
      ),
    );
  }
}