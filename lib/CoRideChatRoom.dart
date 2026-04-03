import 'package:flutter/material.dart';
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

  late List<CoRideMessage> messages;

  bool get canChat {
    return widget.post.creatorId == widget.currentUserId ||
        widget.post.confirmedMembers.any((m) => m.id == widget.currentUserId);
  }

  @override
  void initState() {
    super.initState();

    messages = [
      const CoRideMessage(
        id: '1',
        senderId: 'creator_1',
        senderName: 'Arafat',
        text: 'Hello সবাই, please 10 minutes আগে ready থাকবেন.',
        time: '10:10 AM',
        isMine: false,
      ),
      const CoRideMessage(
        id: '2',
        senderId: 'me_1',
        senderName: 'You',
        text: 'ঠিক আছে, আমি time মতো আসবো.',
        time: '10:12 AM',
        isMine: true,
      ),
    ];
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty || !canChat) return;

    setState(() {
      messages.add(
        CoRideMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: widget.currentUserId,
          senderName: widget.currentUserName,
          text: text,
          time: _formatNow(),
          isMine: true,
        ),
      );
      messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatNow() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildMemberStrip() {
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
          children: widget.post.confirmedMembers.map((member) {
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

  Widget _buildMessageBubble(CoRideMessage msg) {
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
          margin: const EdgeInsets.only(bottom: 12),
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
            onTap: _sendMessage,
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
              "${widget.post.pickup} → ${widget.post.destination}",
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
        child: !canChat
            ? _buildNoAccessView()
            : Column(
          children: [
            _buildMemberStrip(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                physics: const BouncingScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Align(
                    alignment: msg.isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _buildMessageBubble(msg),
                  );
                },
              ),
            ),
            _buildInputBox(),
          ],
        ),
      ),
    );
  }
}