import 'package:flutter/material.dart';
import 'ChatPage.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6), // Primary
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF14B8A6), // Primary
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                "Ride User $index",
                style: const TextStyle(
                  color: Color(0xFF1F2937), // Text color
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                "Last message...",
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: Color(0xFF0F766E), // Secondary
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      receiverName: "Ride User $index",
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}