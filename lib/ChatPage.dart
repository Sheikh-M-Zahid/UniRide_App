import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverName;
  final String sessionId;

  const ChatPage({
    super.key,
    required this.receiverName,
    required this.sessionId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String time;
  final bool isMe;
  final String status;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.time,
    required this.isMe,
    required this.status,
  });
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final AuthApiService _api = AuthApiService();

  IO.Socket? socket;

  List<MessageModel> messages = [];
  bool isLoading = true;
  bool isSending = false;

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

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectSocket();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _api.getCoRideChatMessages(
        sessionId: widget.sessionId,
      );

      final List data = response['data'] ?? [];

      setState(() {
        messages = data.map((msg) {
          return MessageModel(
            id: (msg['chat_id'] ?? '').toString(),
            senderId: (msg['sender_id'] ?? '').toString(),
            senderName: (msg['sender_name'] ?? '').toString(),
            text: (msg['message_text'] ?? '').toString(),
            time: _formatTime(msg['sent_at']),
            isMe: msg['is_me'] == true,
            status: (msg['status'] ?? 'sent').toString(),
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) return;

    final socketBaseUrl = AuthApiService.baseUrl.replaceAll('/api', '');

    socket = IO.io(
      socketBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      socket!.emit('join_company_session', widget.sessionId);
    });

    socket!.on('company_message_received', (data) {
      if (!mounted) return;

      final incomingId = (data['chat_id'] ?? '').toString();
      final alreadyExists = messages.any((m) => m.id == incomingId);
      if (alreadyExists) return;

      setState(() {
        messages.add(
          MessageModel(
            id: incomingId,
            senderId: (data['sender_id'] ?? '').toString(),
            senderName: widget.receiverName,
            text: (data['message_text'] ?? '').toString(),
            time: _formatTime(data['sent_at']),
            isMe: false,
            status: 'sent',
          ),
        );
      });
    });
  }

  String _formatTime(dynamic sentAt) {
    if (sentAt == null) return '';
    final dt = DateTime.tryParse(sentAt.toString())?.toLocal();
    if (dt == null) return '';
    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      final response = await _api.sendCoRideChatMessage(
        sessionId: widget.sessionId,
        messageText: text,
      );

      final msg = response['data'];

      setState(() {
        messages.add(
          MessageModel(
            id: (msg['chat_id'] ?? '').toString(),
            senderId: (msg['sender_id'] ?? '').toString(),
            senderName: widget.receiverName,
            text: (msg['message_text'] ?? '').toString(),
            time: _formatTime(msg['sent_at']),
            isMe: true,
            status: (msg['status'] ?? 'sent').toString(),
          ),
        );
      });

      messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
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
                      onPressed: isSending ? null : sendMessage,
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