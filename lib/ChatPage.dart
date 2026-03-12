import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String receiverName;

  const ChatPage({
    super.key,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class MessageModel {
  final String text;
  final String time;
  final bool isMe;
  final String status; // sent, delivered, seen

  MessageModel({
    required this.text,
    required this.time,
    required this.isMe,
    required this.status,
  });
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();

  List<MessageModel> messages = [
    MessageModel(
      text: "Hello, are you going to campus?",
      time: "10:15 AM",
      isMe: false,
      status: "seen",
    ),
    MessageModel(
      text: "Yes, I am going. Where are you now?",
      time: "10:16 AM",
      isMe: true,
      status: "seen",
    ),
    MessageModel(
      text: "I am at the main gate.",
      time: "10:17 AM",
      isMe: false,
      status: "seen",
    ),
  ];

  String getCurrentTime() {
    final now = DateTime.now();
    int hour = now.hour;
    final int minute = now.minute;
    final String period = hour >= 12 ? "PM" : "AM";

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final String minuteText = minute.toString().padLeft(2, '0');
    return "$hour:$minuteText $period";
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case "seen":
        return Icons.done_all;
      case "delivered":
        return Icons.done_all;
      default:
        return Icons.check;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "seen":
        return Colors.lightBlue;
      case "delivered":
        return Colors.white70;
      default:
        return Colors.white70;
    }
  }

  void sendMessage() {
    if (messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add(
          MessageModel(
            text: messageController.text.trim(),
            time: getCurrentTime(),
            isMe: true,
            status: "sent",
          ),
        );
      });

      messageController.clear();

      // এখানে backend / database এ message save করবে
    }
  }

  Widget buildMessageBubble(MessageModel message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: message.isMe
              ? const Color(0xFF14B8A6)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isMe
                      ? Colors.white
                      : const Color(0xFF1F2937),
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: message.isMe
                        ? Colors.white70
                        : Colors.grey.shade600,
                  ),
                ),
                if (message.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    getStatusIcon(message.status),
                    size: 16,
                    color: getStatusColor(message.status),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14B8A6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
              child: Text(
                "No messages yet",
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessageBubble(messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Type a message",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF14B8A6),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF14B8A6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}