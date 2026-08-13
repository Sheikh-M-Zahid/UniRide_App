import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'AlumniChatPage.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1D5DB);
  static const Color mutedText = Color(0xFF6B7280);
}

class AlumniChatListPage extends StatefulWidget {
  const AlumniChatListPage({super.key});

  @override
  State<AlumniChatListPage> createState() => _AlumniChatListPageState();
}

class _AlumniChatListPageState extends State<AlumniChatListPage> {
  final _authApiService = AuthApiService();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _authApiService.getMyAlumniChats();
      setState(() {
        _chats = List<Map<String, dynamic>>.from(res['data'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool _isSessionActive(DateTime scheduledAt) {
    final now = DateTime.now();
    final diff = now.difference(scheduledAt).inMinutes;
    return diff >= -5 && diff <= 120;
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
        title: const Text('Alumni Chats',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadChats,
        child: _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
            ? ListView(
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.mutedText, size: 44),
                  const SizedBox(height: 12),
                  Text(_error!,
                      style:
                      const TextStyle(color: AppColors.mutedText)),
                ],
              ),
            ),
          ],
        )
            : _chats.isEmpty
            ? ListView(
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 50,
                      color: AppColors.mutedText.withOpacity(0.5)),
                  const SizedBox(height: 14),
                  const Text('No chats yet',
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 15)),
                ],
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _chats.length,
          itemBuilder: (_, i) {
            final chat = _chats[i];
            final scheduledAt =
            DateTime.parse(chat['scheduled_at']).toLocal();
            final isActive = _isSessionActive(scheduledAt);
            final name = chat['other_person_name'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlumniChatPage(
                      sessionId: chat['session_id'],
                      otherUserId: chat['other_person_id'],
                      otherPersonName: name,
                      otherPersonPhone: chat['other_person_phone'],
                      isAlumni: chat['is_alumni'] == true,
                      scheduledAt: scheduledAt,
                      otherPersonPhoto: chat['other_person_photo'],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isActive
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.inputFill,
                      backgroundImage: chat['other_person_photo'] != null
                          ? NetworkImage(chat['other_person_photo'])
                          : null,
                      child: chat['other_person_photo'] == null
                          ? const Icon(Icons.person,
                          size: 26, color: AppColors.mutedText)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.text,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} at ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: AppColors.mutedText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isActive ? Colors.green : AppColors.mutedText)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Ended',
                        style: TextStyle(
                          color: isActive ? Colors.green : AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}