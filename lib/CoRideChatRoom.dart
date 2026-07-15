import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'services/auth_api_service.dart';
import 'CoRideModels.dart';

class CoRideChatRoomPage extends StatefulWidget {
  final CoRidePost post;
  final String currentUserId;
  final String currentUserName;

  const CoRideChatRoomPage({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<CoRideChatRoomPage> createState() => _CoRideChatRoomPageState();
}

class _CoRideChatRoomPageState extends State<CoRideChatRoomPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final AuthApiService _api = AuthApiService();

  IO.Socket? _socket;
  Timer? _pollTimer;

  List<CoRideMessage> messages = [];
  bool isLoading = true;
  bool isSending = false;
  bool hasAccess = true;
  String? loadError;

  List<CoRideMember> get _displayMembers {
    if (widget.post.confirmedMembers.isNotEmpty) {
      return widget.post.confirmedMembers;
    }

    if (widget.post.creatorName.trim().isNotEmpty) {
      return [
        CoRideMember(
          id: widget.post.creatorId,
          name: widget.post.creatorName,
          role: 'creator',
        ),
      ];
    }

    return [];
  }

  bool get canChat => hasAccess;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectSocket();
    _startPollingFallback();
  }

  @override
  void dispose() {
    _socket?.emit('leave_company_session', {
      'sessionId': widget.post.sessionId,
    });
    _pollTimer?.cancel();
    _socket?.dispose();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _connectSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) return;

      final socketBaseUrl = AuthApiService.baseUrl.replaceAll('/api', '');

      _socket = IO.io(
        socketBaseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({
          'Authorization': 'Bearer $token',
        })
            .setQuery({
          'sessionId': widget.post.sessionId,
          'userId': widget.currentUserId,
        })
            .build(),
      );

      _socket!.onConnect((_) {
        // backend এ যদি room join handler থাকে, এই emit গুলো join করাবে
        _socket!.emit('join_company_session', {
          'sessionId': widget.post.sessionId,
        });

        _socket!.emit('join_user_room', {
          'userId': widget.currentUserId,
        });
      });

      _socket!.on('company_message_received', (data) async {
        if (data is! Map) return;

        final incoming = CoRideMessage.fromJson(
          Map<String, dynamic>.from(data),
        ).copyWith(
          time: _formatServerTime((data['time'] ?? '').toString()),
          isMine: (data['sender_id']?.toString() ?? '') == widget.currentUserId,
        );

        if (!mounted) return;

        final alreadyExists = messages.any((m) => m.id == incoming.id);
        if (alreadyExists) return;

        setState(() {
          messages.add(incoming);
        });

        _scrollToBottom();
        await _api.markCoRideChatAsRead(sessionId: widget.post.sessionId);
      });

      _socket!.on('co_ride_chat_list_updated', (_) {
        // এই page-এ আলাদা UI update লাগছে না।
        // ChatList page back করলে refresh নিচ্ছেই।
      });

      _socket!.connect();
    } catch (_) {
      // socket fail করলে নিচের polling fallback কাজ করবে
    }
  }

  void _startPollingFallback() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || !hasAccess) return;
      await _loadMessages(silent: true);
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          isLoading = true;
          loadError = null;
        });
      }


      final response = await _api.getCoRideChatMessages(
        sessionId: widget.post.sessionId,
      );


      final List<dynamic> list = response['data'] ?? [];


      final loadedMessages = list
          .map((e) => CoRideMessage.fromJson(e as Map<String, dynamic>))
          .map(
            (msg) => msg.copyWith(
          time: _formatServerTime(msg.time),
          statusTime: _formatServerTime(msg.statusTime),
        ),
      )
          .toList();


      if (!mounted) return;

      final hasNewMessages = loadedMessages.length != messages.length ||
          (loadedMessages.isNotEmpty &&
              messages.isNotEmpty &&
              loadedMessages.last.id != messages.last.id);


      setState(() {
        hasAccess = true;
        messages = loadedMessages;
        isLoading = false;
        loadError = null;
      });


      await _api.markCoRideChatAsRead(sessionId: widget.post.sessionId);

      if (!silent || hasNewMessages) {
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;


      final text = e.toString().toLowerCase();
      final denied = text.contains('not allowed') ||
          text.contains('cannot access') ||
          text.contains('you are not allowed');


      setState(() {
        hasAccess = !denied ? hasAccess : false;
        isLoading = false;
        loadError = e.toString();
        if (denied) {
          messages = [];
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatServerTime(String rawTime) {
    if (rawTime.trim().isEmpty) return '';

    try {
      final dt = DateTime.parse(rawTime).toLocal();
      final hour24 = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour24 >= 12 ? 'PM' : 'AM';
      final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
      return '$hour12:$minute $period';
    } catch (_) {
      return rawTime;
    }
  }

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || !canChat || isSending) return;

    try {
      setState(() {
        isSending = true;
      });

      messageController.clear();

      final response = await _api.sendCoRideChatMessage(
        sessionId: widget.post.sessionId,
        messageText: text,
      );

      final data = response['data'] as Map<String, dynamic>;
      final newMessage = CoRideMessage.fromJson(data).copyWith(
        time: _formatServerTime((data['time'] ?? '').toString()),
        isMine: true,
      );

      if (!mounted) return;

      final alreadyExists = messages.any((m) => m.id == newMessage.id);
      if (!alreadyExists) {
        setState(() {
          messages.add(newMessage);
        });
      }

      _scrollToBottom();
      await _api.markCoRideChatAsRead(sessionId: widget.post.sessionId);
    } catch (e) {
      if (!mounted) return;
      messageController.text = text;

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

  Widget _buildMemberStrip() {
    if (_displayMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _displayMembers.map((member) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.softPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  member.name,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(CoRideMessage msg, {bool isLast = false}) {
    final alignment =
    msg.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = msg.isMine ? AppColors.primary : Colors.white;
    final textColor = msg.isMine ? Colors.white : AppColors.text;


    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (!msg.isMine)
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 4),
            child: Text(
              msg.senderName,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(msg.isMine ? 18 : 6),
              bottomRight: Radius.circular(msg.isMine ? 6 : 18),
            ),
            border: msg.isMine ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: alignment,
            children: [
              Text(
                msg.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                msg.time,
                style: TextStyle(
                  color: msg.isMine
                      ? Colors.white.withOpacity(0.9)
                      : AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (isLast && msg.isMine)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4),
            child: Text(
              msg.status == 'seen'
                  ? (msg.statusTime.isNotEmpty
                  ? 'Seen ${msg.statusTime}'
                  : 'Seen')
                  : msg.status == 'delivered'
                  ? 'Delivered'
                  : 'Sent',
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInputBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Type a message",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: isSending ? null : _sendMessage,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAccessView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "You cannot access this chat.\nOnly creator and confirmed participants can chat here.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Failed to load messages",
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loadError ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Co Ride Chat",
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "${widget.post.pickupLocation} → ${widget.post.destinationLocation}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: !hasAccess
            ? _buildNoAccessView()
            : Column(
          children: [
            _buildMemberStrip(),
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
                  : loadError != null && messages.isEmpty
                  ? _buildErrorView()
                  : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                physics: const BouncingScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isLast = index == messages.length - 1;
                  return Align(
                    alignment: msg.isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _buildMessageBubble(msg, isLast: isLast),
                  );
                },
              ),
            ),
            widget.post.isActive
                ? _buildInputBox()
                : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: const Color(0xFFF3F4F6),
              child: const Text(
                'This CoRide has been closed. You can view previous messages, but you can no longer send new ones.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}