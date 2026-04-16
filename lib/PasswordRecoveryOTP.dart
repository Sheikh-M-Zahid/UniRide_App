import 'dart:async';
import 'package:flutter/material.dart';
import 'services/auth_api_service.dart';
import 'ResetPassword.dart';

class passwordrecoveryotp extends StatefulWidget {
  final String email;

  const passwordrecoveryotp({
    super.key,
    required this.email,
  });

  @override
  State<passwordrecoveryotp> createState() => _passwordrecoveryotpState();
}

class _passwordrecoveryotpState extends State<passwordrecoveryotp> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _isVerifying = false;
  bool _isResending = false;
  final AuthApiService _authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String get _otpCode {
    return _otpControllers.map((e) => e.text).join();
  }

  bool get _isOtpComplete {
    return _otpControllers.every((controller) => controller.text.trim().isNotEmpty);
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    setState(() {});
  }

  void _onBackspace(int index) {
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await _authApiService.verifyRecoveryOtp(
        email: widget.email,
        otp: _otpCode,
      );

      final String resetToken = response['data']?['resetToken'] ?? '';

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified successfully'),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(
            resetToken: resetToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      await _authApiService.resendRecoveryOtp(email: widget.email);

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      _clearOtpFields();
      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new OTP has been sent'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))
        ),
      );
    }
  }

  void _clearOtpFields() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 3) {
      return '${name[0]}**@$domain';
    }

    final visible = name.substring(0, 3);
    return '$visible${'*' * (name.length - 3)}@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF5BB8AE);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter the 6-digit code sent to ${_maskEmail(widget.email)}',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 46,
                        height: 58,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            if (event.logicalKey.keyLabel == 'Backspace') {
                              _onBackspace(index);
                            }
                          },
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: themeColor,
                                  width: 1.8,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.length > 1) {
                                _otpControllers[index].text = value[value.length - 1];
                                _otpControllers[index].selection =
                                    TextSelection.fromPosition(
                                      const TextPosition(offset: 1),
                                    );
                              }
                              _onOtpChanged(_otpControllers[index].text, index);
                            },
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isOtpComplete && !_isVerifying)
                          ? _verifyOtp
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        disabledBackgroundColor: themeColor.withOpacity(0.45),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Center(
                    child: _secondsRemaining > 0
                        ? Text(
                      'Resend code in ${_secondsRemaining}s',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                      ),
                    )
                        : TextButton(
                      onPressed: _isResending ? null : _resendOtp,
                      child: _isResending
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                    ),
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