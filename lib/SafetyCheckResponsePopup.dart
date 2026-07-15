import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';

class SafetyCheckResponsePopup extends StatefulWidget {
  final String checkId;
  const SafetyCheckResponsePopup({super.key, required this.checkId});

  @override
  State<SafetyCheckResponsePopup> createState() => _SafetyCheckResponsePopupState();
}

class _SafetyCheckResponsePopupState extends State<SafetyCheckResponsePopup> {
  final AuthApiService _api = AuthApiService();
  bool _isSubmitting = false;
  bool _showMessageBox = false;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _respond(String status) async {
    if (_isSubmitting) return;
    if (status == 'not_okay' && !_showMessageBox) {
      setState(() => _showMessageBox = true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _api.respondSafetyCheck(
        checkId: widget.checkId,
        status: status,
        message: status == 'not_okay' ? _messageController.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'okay'
              ? 'Thank you! Your response has been saved.'
              : 'Your message has been sent to the admin.'),
          backgroundColor: status == 'okay' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.health_and_safety_outlined, color: Color(0xFFDC2626), size: 32),
              const SizedBox(height: 12),
              const Text('Is everything okay?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Your trip appears to have ended before reaching its intended destination.',
                style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 20),
              if (_showMessageBox) ...[
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Briefly describe what happened...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _respond('not_okay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send Message', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _respond('okay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('I am okay, nothing happened', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => _respond('not_okay'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('I am not okay', style: TextStyle(color: Color(0xFFDC2626))),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}