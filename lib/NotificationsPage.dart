import 'RiderDelivery.dart';
import 'RiderMap.dart';
import 'CoRideDetailsPopup.dart';
import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'RideRequestPopup.dart';
import 'UserOffer.dart';
import 'RiderOffers.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color card = Colors.white;
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF0EA5E9);
}

enum UserRole {
  passenger,
  rider,
  admin,
}

enum NotificationType {
  offer,
  reserveRequest,
  reserveAccepted,
  reserveRejected,
  coRide,
  sendItem,
  payment,
  adminNotice,
  verification,
  safety,
  booking,
  general,
}

class NotificationItemModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final bool isImportant;
  final UserRole targetRole;
  final String? relatedId;
  final String? offerStartDate;
  final String? offerEndDate;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    required this.isImportant,
    required this.targetRole,
    this.relatedId,
    this.offerStartDate,
    this.offerEndDate,
  });

  NotificationItemModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    bool? isImportant,
    UserRole? targetRole,
    String? relatedId,
    String? offerStartDate,
    String? offerEndDate,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant ?? this.isImportant,
      targetRole: targetRole ?? this.targetRole,
      relatedId: relatedId ?? this.relatedId,
      offerStartDate: offerStartDate ?? this.offerStartDate,
      offerEndDate: offerEndDate ?? this.offerEndDate,
    );
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: _notificationTypeFromString((json['type'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      isRead: json['isRead'] == true,
      isImportant: json['isImportant'] == true,
      targetRole: _userRoleFromString((json['targetRole'] ?? '').toString()),
      relatedId: (json['relatedId'] ?? '').toString().isEmpty
          ? null
          : (json['relatedId']).toString(),
      offerStartDate: json['offerStartDate']?.toString(),
      offerEndDate: json['offerEndDate']?.toString(),
    );
  }
}

NotificationType _notificationTypeFromString(String value) {
  switch (value.trim().toLowerCase()) {
    case 'offer':
      return NotificationType.offer;
    case 'reserve_request':
    case 'reserverequest':
      return NotificationType.reserveRequest;
    case 'reserve_accepted':
    case 'reserveaccepted':
      return NotificationType.reserveAccepted;
    case 'reserve_rejected':
    case 'reserverejected':
      return NotificationType.reserveRejected;
    case 'co_ride':
    case 'coride':
      return NotificationType.coRide;
    case 'send_item':
    case 'senditem':
      return NotificationType.sendItem;
    case 'payment':
      return NotificationType.payment;
    case 'admin_notice':
    case 'adminnotice':
      return NotificationType.adminNotice;
    case 'verification':
      return NotificationType.verification;
    case 'safety':
      return NotificationType.safety;
    case 'booking':
      return NotificationType.booking;
    default:
      return NotificationType.general;
  }
}

UserRole _userRoleFromString(String value) {
  switch (value.trim().toLowerCase()) {
    case 'passenger':
      return UserRole.passenger;
    case 'rider':
      return UserRole.rider;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.passenger;
  }
}

class NotificationsPage extends StatefulWidget {
  final UserRole userRole;

  const NotificationsPage({
    super.key,
    required this.userRole,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AuthApiService _api = AuthApiService();

  bool isLoading = false;
  int selectedFilterIndex = 0;

  late List<NotificationItemModel> allNotifications;

  final List<String> filters = [
    "All",
    "Unread",
    "Offers",
    "Booking",
    "Payment",
    "Admin",
  ];

  @override
  void initState() {
    super.initState();
    allNotifications = [];
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _api.getNotifications();
      final List rawList = response['data'] ?? [];

      final loadedNotifications = rawList
          .whereType<Map>()
          .map((item) => NotificationItemModel.fromJson(
        Map<String, dynamic>.from(item),
      ))
          .toList();

      if (!mounted) return;

      setState(() {
        allNotifications = loadedNotifications;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  List<NotificationItemModel> get filteredNotifications {
    switch (selectedFilterIndex) {
      case 1:
        return allNotifications.where((item) => !item.isRead).toList();
      case 2:
        return allNotifications
            .where((item) => item.type == NotificationType.offer)
            .toList();
      case 3:
        return allNotifications
            .where(
              (item) =>
          item.type == NotificationType.booking ||
              item.type == NotificationType.reserveRequest ||
              item.type == NotificationType.reserveAccepted ||
              item.type == NotificationType.reserveRejected,
        )
            .toList();
      case 4:
        return allNotifications
            .where((item) => item.type == NotificationType.payment)
            .toList();
      case 5:
        return allNotifications
            .where((item) => item.type == NotificationType.adminNotice)
            .toList();
      default:
        return allNotifications;
    }
  }

  int get unreadCount =>
      allNotifications.where((item) => !item.isRead).length;

  String get roleTitle {
    switch (widget.userRole) {
      case UserRole.passenger:
        return "Passenger Notifications";
      case UserRole.rider:
        return "Rider Notifications";
      case UserRole.admin:
        return "Admin Notifications";
    }
  }

  Future<void> _markAllAsRead() async {
    final previous = List<NotificationItemModel>.from(allNotifications);

    setState(() {
      allNotifications = allNotifications
          .map((item) => item.copyWith(isRead: true))
          .toList();
    });

    try {
      await _api.markAllNotificationsAsRead();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        allNotifications = previous;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markSingleAsRead(String id) async {
    final previous = List<NotificationItemModel>.from(allNotifications);

    setState(() {
      allNotifications = allNotifications.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
    });

    try {
      await _api.markNotificationAsRead(notificationId: id);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        allNotifications = previous;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteNotification(String id) async {
    final previous = List<NotificationItemModel>.from(allNotifications);

    setState(() {
      allNotifications.removeWhere((item) => item.id == id);
    });

    try {
      await _api.deleteNotification(notificationId: id);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        allNotifications = previous;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(NotificationItemModel item) async {
    if (!item.isRead) {
      await _markSingleAsRead(item.id);
    }

    if (!mounted) return;

    // Offer tap → navigate to offers page
    if (item.type == NotificationType.offer) {
      if (widget.userRole == UserRole.rider) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiderOffersPage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OffersPage()),
        );
      }
      return;
    }

    if (widget.userRole == UserRole.rider &&
        item.type == NotificationType.reserveRequest &&
        item.relatedId != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(item.title),
          content: Text(item.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  await _api.acceptReserveRequest(reserveId: item.relatedId!);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reserve request accepted')),
                  );

                  await _loadNotifications();
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      return;
    }

    if (widget.userRole == UserRole.rider &&
        item.type == NotificationType.sendItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RiderDeliveryPage(),
        ),
      );
      return;
    }

    if (item.type == NotificationType.coRide && item.relatedId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CoRideDetailsPopup(sessionId: item.relatedId!),
      );
      return;
    }

    if (widget.userRole == UserRole.rider &&
        item.type == NotificationType.booking &&
        item.relatedId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => RideRequestPopup(requestId: item.relatedId!),
      );
      return;
    }

    if (widget.userRole == UserRole.rider &&
        item.type == NotificationType.booking) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapPage()),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.title),
        content: Text(item.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.offer:
        return Icons.local_offer_outlined;
      case NotificationType.reserveRequest:
        return Icons.event_available_outlined;
      case NotificationType.reserveAccepted:
        return Icons.check_circle_outline;
      case NotificationType.reserveRejected:
        return Icons.cancel_outlined;
      case NotificationType.coRide:
        return Icons.people_alt_outlined;
      case NotificationType.sendItem:
        return Icons.inventory_2_outlined;
      case NotificationType.payment:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.adminNotice:
        return Icons.campaign_outlined;
      case NotificationType.verification:
        return Icons.verified_user_outlined;
      case NotificationType.safety:
        return Icons.shield_outlined;
      case NotificationType.booking:
        return Icons.directions_car_outlined;
      case NotificationType.general:
        return Icons.notifications_none;
    }
  }

  Color _getNotificationIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.offer:
        return AppColors.warning;
      case NotificationType.reserveRequest:
      case NotificationType.booking:
        return AppColors.primary;
      case NotificationType.reserveAccepted:
        return AppColors.success;
      case NotificationType.reserveRejected:
        return AppColors.danger;
      case NotificationType.payment:
        return AppColors.info;
      case NotificationType.adminNotice:
      case NotificationType.verification:
      case NotificationType.safety:
      case NotificationType.coRide:
      case NotificationType.sendItem:
      case NotificationType.general:
        return AppColors.secondary;
    }
  }

  String _formatTime(DateTime time) {
    final difference = DateTime.now().difference(time);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hr ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else {
      return "${difference.inDays} days ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (allNotifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                await _markAllAsRead();
              },
              child: const Text(
                "Mark all read",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshNotifications,
        child: Column(
          children: [
            _HeaderSection(
              title: roleTitle,
              subtitle: unreadCount == 0
                  ? "You are all caught up."
                  : "$unreadCount unread notifications",
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final isSelected = selectedFilterIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilterIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          filters[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: filters.length,
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: isLoading
                  ? const _LoadingView()
                  : notifications.isEmpty
                  ? const _EmptyNotificationView()
                  : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = notifications[index];

                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (_) async {
                      await _deleteNotification(item.id);
                    },
                    child: GestureDetector(
                      onTap: () async => _handleNotificationTap(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? AppColors.card
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.isRead
                                ? AppColors.border
                                : AppColors.primary.withOpacity(0.20),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _getNotificationIconColor(
                                  item.type,
                                ).withOpacity(0.12),
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _getNotificationIcon(item.type),
                                color: _getNotificationIconColor(
                                  item.type,
                                ),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                            FontWeight.w700,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTime(item.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color:
                                          AppColors.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  item.type == NotificationType.offer
                                      ? _OfferCompactInfo(item: item)
                                      : Text(
                                    item.message,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.4,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (item.isImportant)
                                        Container(
                                          padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning
                                                .withOpacity(0.12),
                                            borderRadius:
                                            BorderRadius.circular(
                                                20),
                                          ),
                                          child: const Text(
                                            "Important",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                              AppColors.warning,
                                              fontWeight:
                                              FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      if (!item.isRead) ...[
                                        if (item.isImportant)
                                          const SizedBox(width: 8),
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration:
                                          const BoxDecoration(
                                            color:
                                            AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "Unread",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                            AppColors.primary,
                                            fontWeight:
                                            FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderSection({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notification Center",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotificationView extends StatelessWidget {
  const _EmptyNotificationView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 80),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_none,
            size: 42,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "No notifications yet",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "When something important happens, you will see it here.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedText,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }
}

class _OfferCompactInfo extends StatelessWidget {
  final NotificationItemModel item;

  const _OfferCompactInfo({required this.item});

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDate =
        item.offerStartDate != null || item.offerEndDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title.replaceFirst('New Offer: ', ''),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        if (hasDate) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.date_range_outlined,
                size: 13,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatDate(item.offerStartDate)} → ${_formatDate(item.offerEndDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.touch_app_outlined,
              size: 13,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            const Text(
              'Tap to view full offer',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}