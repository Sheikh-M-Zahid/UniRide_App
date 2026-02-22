import 'package:flutter/material.dart';
import 'ChatPage.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: 5, // backend থেকে আসবে
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text("Ride User $index"),
            subtitle: const Text("Last message..."),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15),
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
          );
        },
      ),
    );
  }
}