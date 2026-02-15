import 'package:flutter/material.dart';

class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar থেকে ব্যাক বাটন এবং টাইটেল নিয়ন্ত্রণ করা হয়েছে
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: const Text(
          "Confirmation",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How would you like to use UniRide?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // Ride Sharer অপশন
            _selectionCard(
              context,
              Icons.directions_car,
              "Ride Sharer",
              "I want to share my bike/car with others.",
            ),
            const SizedBox(height: 20),
            // Passenger অপশন
            _selectionCard(
              context,
              Icons.person_pin_circle,
              "Passenger",
              "I am looking for a ride to campus.",
            ),
          ],
        ),
      ),
    );
  }

  // কার্ড ডিজাইনের জন্য হেল্পার ফাংশন
  Widget _selectionCard(BuildContext context, IconData icon, String title, String sub) {
    return InkWell( // ক্লিক করার সুবিধা যোগ করা হয়েছে
      onTap: () {
        // এখানে আপনার লজিক দিন (যেমন: হোম পেজে যাওয়া)
        print("$title selected");
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}