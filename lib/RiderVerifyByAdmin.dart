import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'services/auth_api_service.dart';

class RiderVerifyByAdmin extends StatefulWidget {
  const RiderVerifyByAdmin({super.key});

  @override
  State<RiderVerifyByAdmin> createState() => _RiderVerifyByAdminState();
}

class _RiderVerifyByAdminState extends State<RiderVerifyByAdmin> {
  final AuthApiService _authApiService = AuthApiService();

  List<RiderVerificationRequest> _requests = [];
  String _searchText = '';
  bool _isLoading = true;
  bool _isActionLoading = false;
  Timer? _pollingTimer;
  Timer? _searchDebounce;
  IO.Socket? _socket;

  List<RiderVerificationRequest> get _pendingRequests {
    return _requests;
  }

  List<RiderVerificationRequest> get _filteredRequests => _pendingRequests;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _startPolling();
    _setupSocket();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchDebounce?.cancel();
    _socket?.emit('admin:vehicle-verifications:leave');
    _socket?.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadRequests(isSilent: true);
    });
  }

  void _setupSocket() {
    _socket = IO.io(
      AuthApiService.baseUrl.replaceAll('/api', ''),
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      },
    );

    _socket!.onConnect((_) {
      _socket!.emit('admin:vehicle-verifications:join');
    });

    _socket!.on('admin:vehicle-verification-updated', (_) {
      _loadRequests(isSilent: true);
    });
  }

  Future<void> _loadRequests({
    bool isSilent = false,
    String? search,
  }) async {
    try {
      if (!isSilent) {
        setState(() {
          _isLoading = true;
        });
      }

      final response = await _authApiService.getPendingRiderVerificationRequests(
        search: search ?? _searchText,
      );

      final List<dynamic> rows = response['data'] ?? [];

      final mapped = rows
          .map((item) => RiderVerificationRequest.fromJson(
        Map<String, dynamic>.from(item),
      ))
          .toList();

      if (!mounted) return;

      setState(() {
        _requests = mapped;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load rider verification requests: $e'),
        ),
      );
    }
  }

  String _formatDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not available';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.day}/${local.month}/${local.year}, $hour:$minute $amPm';
  }

  Future<void> _confirmRequest(RiderVerificationRequest request) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _buildActionDialog(
        title: 'Confirm Rider Request',
        message: 'Are you sure you want to approve ${request.name} as a rider?',
        confirmText: 'Confirm',
        confirmColor: const Color(0xFF14B8A6),
      ),
    );

    if (ok != true) return;

    try {
      setState(() {
        _isActionLoading = true;
      });

      await _authApiService.approveRiderVerificationRequest(
        vehicleId: request.id,
      );

      if (!mounted) return;

      await _loadRequests(isSilent: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${request.name} has been approved successfully.'),
          backgroundColor: const Color(0xFF0F766E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve request: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Future<void> _rejectRequest(RiderVerificationRequest request) async {
    final reason = await _showRejectReasonDialog(request.name);

    if (reason == null || reason.trim().isEmpty) return;

    try {
      setState(() {
        _isActionLoading = true;
      });

      await _authApiService.rejectRiderVerificationRequest(
        vehicleId: request.id,
        reason: reason.trim(),
      );

      if (!mounted) return;

      await _loadRequests(isSilent: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${request.name} has been rejected.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject request: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Widget _buildActionDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16242C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  Future<String?> _showRejectReasonDialog(String name) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16242C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reject Rider Request',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter rejection reason for $name',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter rejection reason',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _openImagePreview(String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F2027),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 250,
                      color: Colors.white10,
                      alignment: Alignment.center,
                      child: const Text(
                        'Image not available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRequestDetails(String vehicleId) async {
    try {
      final response = await _authApiService.getRiderVerificationRequestDetails(
        vehicleId: vehicleId,
      );

      final data = RiderVerificationRequest.fromJson(
        Map<String, dynamic>.from(response['data'] ?? {}),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF16242C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            data.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Email', data.email),
                _detailRow('Phone', data.phone ?? 'Not available'),
                _detailRow('Gender', data.gender ?? 'Not available'),
                _detailRow('Vehicle Type', data.vehicleType ?? 'Not available'),
                _detailRow('Company', data.vehicleCompany),
                _detailRow('Model', data.vehicleModel),
                _detailRow('Year', data.vehicleYear),
                _detailRow('Number Plate', data.numberPlate),
                _detailRow('Seats', '${data.totalSeats ?? 0}'),
                _detailRow('Submitted', _formatDateTime(data.submittedAt)),
                _detailRow('Status', data.status),
                if ((data.reviewedAt ?? '').isNotEmpty)
                  _detailRow('Reviewed At', _formatDateTime(data.reviewedAt)),
                if ((data.rejectionReason ?? '').isNotEmpty)
                  _detailRow('Rejection Reason', data.rejectionReason!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load request details: $e')),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingRequests.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Verify by Admin'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff0f2027),
              Color(0xff203a43),
              Color(0xff2c5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 54,
                            width: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF14B8A6),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pending Rider Verification',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$pendingCount request waiting for admin review',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              pendingCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });

                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(
                            const Duration(milliseconds: 500),
                                () {
                              _loadRequests(isSilent: true, search: value);
                            },
                          );
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search by name, email, company or plate',
                          hintStyle: TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF14B8A6),
                  ),
                )
                    : _filteredRequests.isEmpty
                    ? const Center(
                  child: Text(
                    'No pending rider verification request found.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                )
                    : Stack(
                  children: [
                    RefreshIndicator(
                      color: const Color(0xFF14B8A6),
                      onRefresh: () => _loadRequests(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredRequests[index];
                          return _buildRequestCard(request);
                        },
                      ),
                    ),
                    if (_isActionLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(RiderVerificationRequest request) {
    return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openRequestDetails(request.id),
          child: Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white12,
                  backgroundImage: request.profilePhoto.trim().isNotEmpty
                      ? NetworkImage(request.profilePhoto)
                      : null,
                  child: request.profilePhoto.trim().isEmpty
                      ? const Icon(
                    Icons.person,
                    color: Colors.white70,
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${_formatDateTime(request.submittedAt)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orangeAccent),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoBox(request),
            const SizedBox(height: 16),
            _buildImageSection(request),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmRequest(request),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _buildInfoBox(RiderVerificationRequest request) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoItem('Company', request.vehicleCompany),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoItem('Model', request.vehicleModel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoItem('Year', request.vehicleYear),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoItem('Number Plate', request.numberPlate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(RiderVerificationRequest request) {
    final docs = [
      RiderDocument(
        title: 'University ID Card',
        imageUrl: request.universityIdImage,
        icon: Icons.badge_outlined,
      ),
      RiderDocument(
        title: 'Profile Photo',
        imageUrl: request.profilePhoto,
        icon: Icons.account_circle_outlined,
      ),
      RiderDocument(
        title: 'Driving License',
        imageUrl: request.drivingLicenseImage,
        icon: Icons.credit_card_outlined,
      ),
      RiderDocument(
        title: 'Registration Paper',
        imageUrl: request.registrationPaperImage,
        icon: Icons.description_outlined,
      ),
      RiderDocument(
        title: 'Tax Token',
        imageUrl: request.taxTokenImage,
        icon: Icons.receipt_long_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Submitted Documents',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .95,
          ),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openImagePreview(doc.title, doc.imageUrl),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Image.network(
                          doc.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white10,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white54,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Icon(doc.icon, color: const Color(0xFF14B8A6), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              doc.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class RiderVerificationRequest {
  final String id;
  final String name;
  final String email;
  final String vehicleCompany;
  final String vehicleModel;
  final String vehicleYear;
  final String numberPlate;
  final String universityIdImage;
  final String profilePhoto;
  final String drivingLicenseImage;
  final String registrationPaperImage;
  final String taxTokenImage;
  final String submittedAt;
  final String status;
  final String? phone;
  final String? gender;
  final String? vehicleType;
  final int? totalSeats;
  final String? reviewedAt;
  final String? rejectionReason;

  RiderVerificationRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.vehicleCompany,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.numberPlate,
    required this.universityIdImage,
    required this.profilePhoto,
    required this.drivingLicenseImage,
    required this.registrationPaperImage,
    required this.taxTokenImage,
    required this.submittedAt,
    required this.status,
    this.phone,
    this.gender,
    this.vehicleType,
    this.totalSeats,
    this.reviewedAt,
    this.rejectionReason,
  });

  factory RiderVerificationRequest.fromJson(Map<String, dynamic> json) {
    return RiderVerificationRequest(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      vehicleCompany: json['vehicleCompany']?.toString() ?? '',
      vehicleModel: json['vehicleModel']?.toString() ?? '',
      vehicleYear: json['vehicleYear']?.toString() ?? '',
      numberPlate: json['numberPlate']?.toString() ?? '',
      universityIdImage: json['universityIdImage']?.toString() ?? '',
      profilePhoto: json['profilePhoto']?.toString() ?? '',
      drivingLicenseImage: json['drivingLicenseImage']?.toString() ?? '',
      registrationPaperImage:
      json['registrationPaperImage']?.toString() ?? '',
      taxTokenImage: json['taxTokenImage']?.toString() ?? '',
      submittedAt: json['submittedAt']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      vehicleType: json['vehicleType']?.toString(),
      totalSeats: int.tryParse(json['totalSeats']?.toString() ?? ''),
      reviewedAt: json['reviewedAt']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

class RiderDocument {
  final String title;
  final String imageUrl;
  final IconData icon;

  RiderDocument({
    required this.title,
    required this.imageUrl,
    required this.icon,
  });
}