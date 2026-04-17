import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'CoRideModels.dart';
import 'CoRideChatRoom.dart';

class CoRideChatListPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const CoRideChatListPage({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<CoRideChatListPage> createState() => _CoRideChatListPageState();
}

class _CoRideChatListPageState extends State<CoRideChatListPage> {
  final AuthApiService _api = AuthApiService();
  List<CoRideChatItem> allItems = [];
  List<CoRideChatItem> filteredItems = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterChats);
    _loadChats();
  }

  void _filterChats() {
    final q = searchController.text.trim().toLowerCase();

    setState(() {
      filteredItems = allItems.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.subtitle.toLowerCase().contains(q) ||
            item.lastMessage.toLowerCase().contains(q);
      }).toList();
    });
  }

  String _formatLastMessageTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    try {
      final dt = DateTime.parse(raw).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  CoRideChatItem _mapChatItem(Map<String, dynamic> json) {
    final postData = json['post'] ?? {};

    return CoRideChatItem(
      sessionId: json['session_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageTime: _formatLastMessageTime(
        json['last_message_time']?.toString(),
      ),
      unreadCount: json['unread_count'] is int
          ? json['unread_count']
          : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      post: CoRidePost(
        id: postData['ride_id']?.toString() ??
            postData['session_id']?.toString() ??
            json['session_id']?.toString() ??
            '',
        sessionId: postData['session_id']?.toString() ??
            json['session_id']?.toString() ??
            '',
        creatorId: postData['creator_id']?.toString() ??
            postData['created_by']?.toString() ??
            '',
        creatorName: postData['creator_name']?.toString() ?? '',
        creatorPhoto: postData['creator_photo']?.toString() ?? '',
        pickup: postData['pickup_location']?.toString() ??
            postData['start_location']?.toString() ??
            '',
        destination: postData['destination_location']?.toString() ??
            postData['destination']?.toString() ??
            '',
        vehicleType: postData['vehicle_type']?.toString() ?? '',
        vehicleNumber: postData['number_plate']?.toString() ?? '',
        preferredGender: postData['gender_preference']?.toString() ?? 'any',
        dateText: postData['travel_date']?.toString() ?? '',
        timeText: postData['travel_time']?.toString() ?? '',
        totalSeats: (postData['total_seats'] is int)
            ? postData['total_seats']
            : int.tryParse(postData['total_seats']?.toString() ?? '0') ?? 0,
        confirmedSeats: (postData['confirmed_seats'] is int)
            ? postData['confirmed_seats']
            : int.tryParse(postData['confirmed_seats']?.toString() ?? '0') ?? 0,
        farePerPerson: (postData['fare_per_person'] is num)
            ? (postData['fare_per_person'] as num).toDouble()
            : (postData['total_fare'] is num)
            ? (postData['total_fare'] as num).toDouble()
            : double.tryParse(postData['total_fare']?.toString() ?? '0') ?? 0,
        note: postData['note']?.toString() ?? '',
        confirmedMembers: const [],
      ),
    );
  }

  Future<void> _loadChats({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await _api.getCoRideChatList();
      final List rawList = response['data'] ?? [];

      final items = rawList
          .map((e) => _mapChatItem(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;

      setState(() {
        allItems = items;
        filteredItems = items;
        isLoading = false;
      });

      _filterChats();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load Co Ride chats'),
        ),
      );
    }
  }

  Future<void> _refreshChats() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
    });

    try {
      await _loadChats(silent: true);
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat(CoRideChatItem item) async {
    try {
      await _api.markCoRideChatAsRead(sessionId: item.sessionId);

      setState(() {
        final index = allItems.indexWhere((e) => e.sessionId == item.sessionId);
        if (index != -1) {
          allItems[index] = allItems[index].copyWith(unreadCount: 0);
        }
      });

      _filterChats();
    } catch (_) {}

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoRideChatRoomPage(
          post: item.post,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
        ),
      ),
    );

    if (!mounted) return;
    await _refreshChats();
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: searchController,
        decoration: const InputDecoration(
          hintText: "Search confirmed Co Ride chats",
          hintStyle: TextStyle(color: AppColors.mutedText),
          prefixIcon: Icon(Icons.search, color: AppColors.secondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildChatCard(CoRideChatItem item) {
    return InkWell(
      onTap: () => _openChat(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.softPrimary,
              child: Text(
                item.title.isNotEmpty ? item.title[0].toUpperCase() : "C",
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Text(
                  item.lastMessageTime.isEmpty ? '' : item.lastMessageTime,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                if (item.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(
                      item.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 54,
            color: AppColors.secondary,
          ),
          SizedBox(height: 12),
          Text(
            "No confirmed Co Ride chat yet",
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Only confirmed creator and confirmed participants will see chats here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          "Co Ride Chats",
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            children: [
              _buildSearchBox(),
              const SizedBox(height: 18),
              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
                    : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refreshChats,
                  child: filteredItems.isEmpty
                      ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildEmptyState(),
                    ],
                  )
                      : ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return _buildChatCard(filteredItems[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}