// AlumniChatPage.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'services/auth_api_service.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class AlumniChatPage extends StatefulWidget {
  final String sessionId;
  final String otherPersonName;
  final String? otherPersonPhone; // Only alumni can see requester's phone
  final bool isAlumni; // Is current user the alumni?
  final DateTime scheduledAt;
  final String? otherPersonPhoto;

  const AlumniChatPage({
    super.key,
    required this.sessionId,
    required this.otherPersonName,
    this.otherPersonPhone,
    required this.isAlumni,
    required this.scheduledAt,
    this.otherPersonPhoto,
  });

  @override
  State<AlumniChatPage> createState() => _AlumniChatPageState();
}

class _AlumniChatPageState extends State<AlumniChatPage> {
  final _authApiService = AuthApiService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isOtherTyping = false;
  Timer? _typingTimer;

  WebSocketChannel? _channel;
  String? _myUserId;
  String? _authToken;

  bool get _isSessionActive {
    final now = DateTime.now();
    final diff = now.difference(widget.scheduledAt).inMinutes;
    return diff >= -5 && diff <= 120;
  }

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _channel?.sink.close();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initChat() async {
    // Load existing messages
    try {
      final res =
      await _authApiService.getAlumniChatMessages(widget.sessionId);
      final msgs = List<Map<String, dynamic>>.from(res['data'] ?? []);
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoading = false);
    }

    // Get token for WS
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _myUserId = prefs.getString('user_id');

    if (_isSessionActive && _authToken != null) {
      _connectWebSocket();
    }
  }

  void _connectWebSocket() {
    final wsBase =
    AuthApiService.baseUrl.replaceAll('https://', 'wss://').replaceAll(
        'http://', 'ws://');
    final uri = Uri.parse(
        '$wsBase/ws/alumni-chat?token=$_authToken&sessionId=${widget.sessionId}');

    try {
      _channel = IOWebSocketChannel.connect(uri);
      _channel!.stream.listen(
            (data) {
          final msg = jsonDecode(data.toString());
          if (msg['type'] == 'message') {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          } else if (msg['type'] == 'typing') {
            setState(() => _isOtherTyping = true);
            _typingTimer?.cancel();
            _typingTimer = Timer(const Duration(seconds: 2), () {
              if (mounted) setState(() => _isOtherTyping = false);
            });
          }
        },
        onError: (_) {},
        onDone: () {},
      );
    } catch (_) {}
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _channel == null) return;

    _channel!.sink.add(jsonEncode({'type': 'message', 'text': text}));
    _msgCtrl.clear();
  }

  void _sendTyping() {
    _channel?.sink.add(jsonEncode({'type': 'typing'}));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _callPhone() async {
    if (widget.otherPersonPhone == null) return;
    final uri = Uri.parse('tel:${widget.otherPersonPhone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.inputFill,
              backgroundImage: widget.otherPersonPhoto != null
                  ? NetworkImage(widget.otherPersonPhoto!)
                  : null,
              child: widget.otherPersonPhoto == null
                  ? const Icon(Icons.person,
                  size: 20, color: AppColors.mutedText)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherPersonName,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _isSessionActive ? 'Active session' : 'Session ended',
                    style: TextStyle(
                      color:
                      _isSessionActive ? Colors.green : AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Alumni can call requester
          if (widget.isAlumni && widget.otherPersonPhone != null)
            IconButton(
              icon: const Icon(Icons.call, color: AppColors.primary),
              onPressed: _callPhone,
            ),
        ],
      ),
      body: Column(
        children: [
          // Session time banner
          if (!_isSessionActive)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateTime.now().isBefore(widget.scheduledAt)
                          ? 'Chat session starts at ${widget.scheduledAt.hour.toString().padLeft(2, '0')}:${widget.scheduledAt.minute.toString().padLeft(2, '0')}'
                          : 'Chat session has ended (2hr window closed)',
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: _isLoading
                ? const Center(
                child:
                CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty && !_isSessionActive
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 50,
                      color: AppColors.mutedText),
                  const SizedBox(height: 12),
                  Text(
                    'Scheduled: ${widget.scheduledAt.day}/${widget.scheduledAt.month}/${widget.scheduledAt.year} at ${widget.scheduledAt.hour.toString().padLeft(2, '0')}:${widget.scheduledAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: AppColors.mutedText, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount:
              _messages.length + (_isOtherTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isOtherTyping) {
                  return _TypingBubble(
                      name: widget.otherPersonName);
                }
                final msg = _messages[i];
                final isMe = msg['sender_id'] == _myUserId;
                return _MessageBubble(
                  message: msg['text'] ?? msg['message_text'] ?? '',
                  senderName:
                  msg['sender_name'] ?? msg['first_name'] ?? '',
                  isMe: isMe,
                  sentAt: msg['sent_at'],
                );
              },
            ),
          ),

          // Input field
          if (_isSessionActive)
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      onChanged: (_) => _sendTyping(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(
                            color: AppColors.mutedText, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                          const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                          const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final bool isMe;
  final dynamic sentAt;

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.isMe,
    this.sentAt,
  });

  @override
  Widget build(BuildContext context) {
    String timeStr = '';
    if (sentAt != null) {
      try {
        final dt = DateTime.parse(sentAt.toString()).toLocal();
        timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  senderName,
                  style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.text,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            if (timeStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Text(
                  timeStr,
                  style: const TextStyle(
                      color: AppColors.mutedText, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final String name;
  const _TypingBubble({required this.name});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '$name is typing...',
          style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
