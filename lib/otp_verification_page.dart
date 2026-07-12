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

class _OTPVerificationPageState extends State<OTPVerificationPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  // ── প্রতিটা box-এর জন্য আলাদা AnimationController ──
  late final List<AnimationController> _bounceControllers;
  late final List<Animation<double>> _bounceAnimations;

  // ── Shake (invalid OTP) ──
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // ── Success scale ──
  late final AnimationController _successController;
  late final Animation<double> _successScaleAnimation;
  late final Animation<double> _successFadeAnimation;

  bool _isButtonActive = false;
  bool _isLoading = false;
  bool _isOtpInvalid = false;
  bool _showSuccess = false;

  final AuthApiService _authApiService = AuthApiService();
  String _signupToken = '';

  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();

    // ── Bounce controllers (একটা করে প্রতিটা box-এর জন্য) ──
    _bounceControllers = List.generate(6, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
    });

    _bounceAnimations = _bounceControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(
            tween: Tween(begin: 1.0, end: 1.18)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 40),
        TweenSequenceItem(
            tween: Tween(begin: 1.18, end: 0.92)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 30),
        TweenSequenceItem(
            tween: Tween(begin: 0.92, end: 1.0)
                .chain(CurveTween(curve: Curves.elasticOut)),
            weight: 30),
      ]).animate(ctrl);
    }).toList();

    // ── Shake controller ──
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -4.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 10),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));

    // ── Success controller ──
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _successFadeAnimation = CurvedAnimation(
      parent: _successController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    for (var controller in _controllers) {
      controller.addListener(_checkOtpComplete);
    }
    _startResendTimer();
  }

  // ── একটা box-এ digit টাইপ হলে bounce play ──
  void _playBounce(int index) {
    _bounceControllers[index].forward(from: 0.0);
  }

  // ── OTP invalid হলে shake ──
  Future<void> _playShake() async {
    await _shakeController.forward(from: 0.0);
    _shakeController.reset();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _checkOtpComplete() {
    bool isComplete = _controllers.every((c) => c.text.isNotEmpty);
    if (_isButtonActive != isComplete) {
      setState(() => _isButtonActive = isComplete);
    }
    if (_isOtpInvalid) {
      setState(() => _isOtpInvalid = false);
    }
  }

  void _fillOtpFromPaste(String value) {
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
        _playBounce(i);
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

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    String enteredOtp = _controllers.map((c) => c.text).join();

    if (enteredOtp.length != 6) {
      _showSnackBar("Please enter the complete 6-digit code.");
      return;
    }

    setState(() => _isLoading = true);

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
        _showSuccess = true;
      });

      // ── Success animation play করো ──
      await _successController.forward();

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
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

      // ── Shake animation play করো ──
      await _playShake();

      // ── Shake শেষে fields clear ──
      _clearOtpFields();
      setState(() => _isOtpInvalid = false);

      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    for (var a in _bounceControllers) a.dispose();
    _shakeController.dispose();
    _successController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayName = widget.email.trim();
    if (displayName.contains('@')) displayName = displayName.split('@')[0];
    if (displayName.isNotEmpty) {
      displayName = displayName[0].toUpperCase() + displayName.substring(1);
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
                style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
              ),

              const SizedBox(height: 30),

              // ── OTP Row — shake wrapper এর ভেতরে ──
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => _otpBox(index)),
                ),
              ),

              const SizedBox(height: 15),

              // ── Success overlay OR error/tip text ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showSuccess
                    ? _buildSuccessBanner()
                    : Text(
                  key: const ValueKey('tip'),
                  _isOtpInvalid
                      ? 'The OTP you entered is incorrect. Please try again.'
                      : 'Tip: Be sure to check your inbox and spam folders',
                  style: TextStyle(
                    color: _isOtpInvalid ? Colors.red : Colors.grey,
                    fontSize: 13,
                    fontWeight: _isOtpInvalid
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              _actionButton(
                _resendSeconds > 0
                    ? 'Resend in ${_resendSeconds}s'
                    : 'Resend',
                onTap: _resendSeconds > 0 ? null : _resendCode,
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                    heroTag: 'back_otp',
                    onPressed:
                    _isLoading ? null : () => Navigator.pop(context),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    child: const Icon(Icons.arrow_back,
                        color: Color(0xFF1F2937)),
                  ),

                  GestureDetector(
                    onTap: (_isButtonActive && !_isLoading) ? _verifyOtp : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      decoration: BoxDecoration(
                        color: (_isButtonActive && !_isLoading)
                            ? const Color(0xFF14B8A6)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                              : Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                              (_isButtonActive && !_isLoading)
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 5),
                          if (!_isLoading)
                            Icon(
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

  // ── Success banner (OTP match হলে দেখাবে) ──
  Widget _buildSuccessBanner() {
    return ScaleTransition(
      key: const ValueKey('success'),
      scale: _successScaleAnimation,
      child: FadeTransition(
        opacity: _successFadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF14B8A6), width: 1.2),
          ),
          child: Row(
            children: const [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF0F766E), size: 20),
              SizedBox(width: 10),
              Text(
                'OTP verified successfully!',
                style: TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return AnimatedBuilder(
      animation: _bounceAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimations[index].value,
          child: child,
        );
      },
      child: SizedBox(
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isOtpInvalid
                    ? Colors.red
                    : const Color(0xFFE5E7EB),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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

            if (value.length == 1) {
              // ── Digit টাইপ হলে bounce ──
              _playBounce(index);

              if (index < 5) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else {
                FocusScope.of(context).unfocus();
              }
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
            }
          },
        ),
      ),
    );
  }

  Widget _actionButton(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            color: onTap == null ? Colors.grey : const Color(0xFF0F766E),
          ),
        ),
      ),
    );
  }
}