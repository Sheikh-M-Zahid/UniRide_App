import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'RegistrationPage.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String generatedOtp;

  const OTPVerificationPage({
    super.key,
    required this.email,
    required this.generatedOtp,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {

  // ৪টি ঘরের জন্য ৪টি কন্ট্রোলার
  final List<TextEditingController> _controllers =
  List.generate(4, (_) => TextEditingController());

  bool _isButtonActive = false;

  @override
  void initState() {
    super.initState();

    // প্রত্যেকটি কন্ট্রোলারের ইনপুট চেক করার জন্য লিসেনার অ্যাড
    for (var controller in _controllers) {
      controller.addListener(_checkOtpComplete);
    }
  }

  // ৪টি ঘর পূরণ হয়েছে কিনা চেক
  void _checkOtpComplete() {
    bool isComplete = _controllers.every((c) => c.text.isNotEmpty);

    setState(() {
      _isButtonActive = isComplete;
    });
  }

  // 🔥 OTP Verify Function
  void _verifyOtp() {
    String enteredOtp = _controllers.map((c) => c.text).join();

    if (enteredOtp == widget.generatedOtp) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalInfoForm(),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid OTP"),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    String displayName = widget.email.split('@')[0];

    if (displayName.isNotEmpty) {
      displayName =
          displayName[0].toUpperCase() + displayName.substring(1);
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Text(
                'Enter the 4-digit code sent to you at:\n${widget.email}',
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87),
              ),

              const SizedBox(height: 30),

              // OTP Input Row
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: List.generate(
                    4,
                        (index) => _otpBox(index)),
              ),

              const SizedBox(height: 15),

              const Text(
                'Tip: Be sure to check your inbox and spam folders',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13),
              ),

              const SizedBox(height: 30),

              _actionButton('Resend'),

              const SizedBox(height: 12),

              _actionButton('Send code by SMS'),

              const Spacer(),

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [

                  FloatingActionButton(
                    heroTag: 'back_otp',
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Colors.grey[200],
                    elevation: 0,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                    ),
                  ),

                  // Next Button
                  GestureDetector(
                    onTap:
                    _isButtonActive ? _verifyOtp : null,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15),
                      decoration: BoxDecoration(
                        color: _isButtonActive
                            ? Colors.black
                            : Colors.grey[300],
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              color: _isButtonActive
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward,
                            color: _isButtonActive
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
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly
        ],
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Colors.black,
                width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1 &&
              index < 3) {
            FocusScope.of(context)
                .nextFocus();
          } else if (value.isEmpty &&
              index > 0) {
            FocusScope.of(context)
                .previousFocus();
          }
        },
      ),
    );
  }

  Widget _actionButton(String title) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding:
        const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}