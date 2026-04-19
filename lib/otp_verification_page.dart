import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'RegistrationPage.dart';
import 'services/auth_api_service.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;

  const OTPVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  // 6টি ঘরের জন্য ৪টি কন্ট্রোলার
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  bool _isButtonActive = false;
  bool _isLoading = false;
  bool _isOtpInvalid = false;
  final AuthApiService _authApiService = AuthApiService();
  String _signupToken = '';

  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();

    // প্রত্যেকটি কন্ট্রোলারের ইনপুট চেক করার জন্য লিসেনার অ্যাড
    for (var controller in _controllers) {
      controller.addListener(_checkOtpComplete);
    }

    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();

    setState(() {
      _resendSeconds = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  // 6টি ঘর পূরণ হয়েছে কিনা চেক
  void _checkOtpComplete() {
    bool isComplete = _controllers.every((c) => c.text.isNotEmpty);

    if (_isButtonActive != isComplete) {
      setState(() {
        _isButtonActive = isComplete;
      });
    }

    if (_isOtpInvalid) {
      setState(() {
        _isOtpInvalid = false;
      });
    }
  }

  void _fillOtpFromPaste(String value) {
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
      }
      FocusScope.of(context).unfocus();
      _checkOtpComplete();
    }
  }

  void _clearOtpFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0) return;

    try {
      await _authApiService.resendSignupOtp(email: widget.email);

      _clearOtpFields();
      _startResendTimer();

      _showSnackBar("A new code has been sent to your email.");
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  // 🔥 OTP Verify Function
  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    String enteredOtp = _controllers.map((c) => c.text).join();

    if (enteredOtp.length != 6) {
      _showSnackBar("Please enter the complete 6-digit code.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authApiService.verifySignupOtp(
        email: widget.email,
        otp: enteredOtp,
      );

      _signupToken = response['data']?['signupToken'] ?? '';

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isOtpInvalid = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalInfoForm(
            signupToken: _signupToken,
            email: widget.email,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isOtpInvalid = true;
      });

      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }

    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayName = widget.email.trim();

    if (displayName.contains('@')) {
      displayName = displayName.split('@')[0];
    }

    if (displayName.isNotEmpty) {
      displayName =
          displayName[0].toUpperCase() + displayName.substring(1);
    } else {
      displayName = "User";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Text(
                'Welcome, $displayName.',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                'Enter the 6-digit code sent to you at:\n${widget.email}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 30),

              // OTP Input Row
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                      (index) => _otpBox(index),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                _isOtpInvalid
                    ? 'The OTP you entered is incorrect. Please try again.'
                    : 'Tip: Be sure to check your inbox and spam folders',
                style: TextStyle(
                  color: _isOtpInvalid ? Colors.red : Colors.grey,
                  fontSize: 13,
                  fontWeight:
                  _isOtpInvalid ? FontWeight.w500 : FontWeight.normal,
                ),
              ),

              const SizedBox(height: 30),

              _actionButton(
                _resendSeconds > 0
                    ? 'Resend in ${_resendSeconds}s'
                    : 'Resend',
                onTap: _resendSeconds > 0 ? null : _resendCode,
              ),

              const SizedBox(height: 12),

              const Spacer(),

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                    heroTag: 'back_otp',
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pop(context),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1F2937),
                    ),
                  ),

                  // Next Button
                  GestureDetector(
                    onTap: (_isButtonActive && !_isLoading)
                        ? _verifyOtp
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: (_isButtonActive && !_isLoading)
                            ? const Color(0xFF14B8A6)
                            : Colors.grey[300],
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                              : Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              color: (_isButtonActive && !_isLoading)
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 5),
                          _isLoading
                              ? const SizedBox.shrink()
                              : Icon(
                            Icons.arrow_forward,
                            color: (_isButtonActive && !_isLoading)
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      height: 60,
      width: 65,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction:
        index == 5 ? TextInputAction.done : TextInputAction.next,
        maxLength: 1,
        autofillHints: const [AutofillHints.oneTimeCode],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isOtpInvalid
                  ? Colors.red
                  : const Color(0xFFE5E7EB),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isOtpInvalid
                  ? Colors.red
                  : const Color(0xFF0F766E),
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.length > 1) {
            _fillOtpFromPaste(value);
            return;
          }

          if (value.length == 1 && index < 5) {
            FocusScope.of(context)
                .requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context)
                .requestFocus(_focusNodes[index - 1]);
          } else if (value.length == 1 && index == 5) {
            FocusScope.of(context).unfocus();
          }
        },
      ),
    );
  }

  Widget _actionButton(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius:
          BorderRadius.circular(20),
          border: Border.all(
            color: onTap == null
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF14B8A6),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: onTap == null
                ? Colors.grey
                : const Color(0xFF0F766E),
          ),
        ),
      ),
    );
  }
}