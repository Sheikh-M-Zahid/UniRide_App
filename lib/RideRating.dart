import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF9FAFB);
  static const Color text = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color card = Colors.white;
  static const Color softPrimary = Color(0xFFECFEFF);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF16A34A);
}

class RideRatingRequest {
  final String rideId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String fromRole; // rider / passenger
  final String toRole; // rider / passenger
  final String rideTitle;
  final bool alreadyRated;

  const RideRatingRequest({
    required this.rideId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.fromRole,
    required this.toRole,
    required this.rideTitle,
    this.alreadyRated = false,
  });
}

class RideRatingSubmission {
  final String rideId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final int rating;
  final String ratingLabel;
  final String? note;
  final DateTime createdAt;

  const RideRatingSubmission({
    required this.rideId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.rating,
    required this.ratingLabel,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'rating': rating,
      'ratingLabel': ratingLabel,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class RideRatingService {
  RideRatingService._();

  static final RideRatingService instance = RideRatingService._();

  Future<bool> hasUserRated({
    required String rideId,
    required String fromUserId,
    required String toUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // TODO:
    // backend call বসবে
    // GET /ratings/check?rideId=...&fromUserId=...&toUserId=...
    return false;
  }

  Future<void> submitRating(RideRatingSubmission submission) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // TODO:
    // POST /ratings/submit
    // body: submission.toMap()
  }

  Future<void> sendRatingRequestNotification({
    required String receiverUserId,
    required String rideId,
    required String otherPersonName,
    required String otherPersonRole,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // TODO:
    // POST /notifications/create
    // type: ride_rating_request
    // title: Rate your recent ride
    // body: Please rate $otherPersonName
  }

  Future<void> sendThankYouNotification({
    required String receiverUserId,
    required String rideId,
    required String senderName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // TODO:
    // POST /notifications/create
    // type: ride_rating_thanks
    // body: $senderName rated you. Thanks for sharing feedback.
  }
}

String getRatingLabel(int value) {
  switch (value) {
    case 1:
      return 'Very Poor';
    case 2:
      return 'Poor';
    case 3:
      return 'Neutral';
    case 4:
      return 'Satisfied';
    case 5:
      return 'Excellent';
    default:
      return '';
  }
}

IconData getRatingIcon(int value) {
  switch (value) {
    case 1:
      return Icons.sentiment_very_dissatisfied_rounded;
    case 2:
      return Icons.sentiment_dissatisfied_rounded;
    case 3:
      return Icons.sentiment_neutral_rounded;
    case 4:
      return Icons.sentiment_satisfied_rounded;
    case 5:
      return Icons.sentiment_very_satisfied_rounded;
    default:
      return Icons.star_rounded;
  }
}

Future<void> showRideRatingSheet(
    BuildContext context, {
      required RideRatingRequest request,
      VoidCallback? onSkipped,
      VoidCallback? onSubmitted,
    }) async {
  final alreadyRated = await RideRatingService.instance.hasUserRated(
    rideId: request.rideId,
    fromUserId: request.fromUserId,
    toUserId: request.toUserId,
  );

  if (alreadyRated || request.alreadyRated) return;

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (_) => RideRatingSheet(
      request: request,
      onSkipped: onSkipped,
      onSubmitted: onSubmitted,
    ),
  );
}

class RideRatingSheet extends StatefulWidget {
  final RideRatingRequest request;
  final VoidCallback? onSkipped;
  final VoidCallback? onSubmitted;

  const RideRatingSheet({
    super.key,
    required this.request,
    this.onSkipped,
    this.onSubmitted,
  });

  @override
  State<RideRatingSheet> createState() => _RideRatingSheetState();
}

class _RideRatingSheetState extends State<RideRatingSheet> {
  final TextEditingController _noteController = TextEditingController();

  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final submission = RideRatingSubmission(
      rideId: widget.request.rideId,
      fromUserId: widget.request.fromUserId,
      fromUserName: widget.request.fromUserName,
      toUserId: widget.request.toUserId,
      toUserName: widget.request.toUserName,
      rating: _selectedRating,
      ratingLabel: getRatingLabel(_selectedRating),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await RideRatingService.instance.submitRating(submission);

      await RideRatingService.instance.sendThankYouNotification(
        receiverUserId: widget.request.toUserId,
        rideId: widget.request.rideId,
        senderName: widget.request.fromUserName,
      );

      if (!mounted) return;
      Navigator.pop(context);

      widget.onSubmitted?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thanks! You rated ${widget.request.toUserName}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submit করা যায়নি। আবার চেষ্টা করো।'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _skip() {
    Navigator.pop(context);
    widget.onSkipped?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final selectedLabel = getRatingLabel(_selectedRating);

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rate Your Ride Experience',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _skip,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ride completed. এখন ${widget.request.toUserName}-কে একটি rating দাও।',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.softPrimary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(.12),
                          child: Text(
                            widget.request.toUserName.isNotEmpty
                                ? widget.request.toUserName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
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
                                widget.request.toUserName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.request.toRole == 'rider'
                                    ? 'Rider'
                                    : 'Passenger',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      final isSelected = _selectedRating == value;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == 4 ? 0 : 8,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              setState(() {
                                _selectedRating = value;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(.10)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    getRatingIcon(value),
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.mutedText,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$value',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _selectedRating == 0
                          ? 'Select a rating'
                          : selectedLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedRating == 0
                            ? AppColors.mutedText
                            : AppColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Optional note...',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _skip,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (_selectedRating == 0 || _isSubmitting)
                              ? null
                              : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            AppColors.primary.withOpacity(.45),
                            minimumSize: const Size.fromHeight(52),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                              : const Text(
                            'Submit Rating',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}