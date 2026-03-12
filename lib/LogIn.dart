import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'LoginCheck.dart';
import 'GmailConfirm.dart';
import 'FindAccount.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UniRideLogin(),
  ));
}

class AppColors {
  static const Color primary = Color(0xFF14B8A6);     // Teal
  static const Color secondary = Color(0xFF0F766E);   // Dark Teal
  static const Color background = Color(0xFFF9FAFB);  // Background
  static const Color text = Color(0xFF1F2937);        // Main text
  static const Color inputFill = Color(0xFFF1F5F9);   // Input fill
  static const Color border = Color(0xFFD1D5DB);      // Border
  static const Color mutedText = Color(0xFF6B7280);   // Sub text
}

class UniRideLogin extends StatefulWidget {
  const UniRideLogin({super.key});

  @override
  State<UniRideLogin> createState() => _UniRideLoginState();
}

class _UniRideLoginState extends State<UniRideLogin> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isGoogleLoading = false;
  bool _isPasswordHidden = true;

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed in as ${account.email}'),
            backgroundColor: AppColors.secondary,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginCheck(),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in was cancelled.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              _logoWidget(),
              const SizedBox(height: 25),

              const Text(
                'Welcome to Intra University\nRide Sharing System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 30),

              _inputLabel('Email Address'),
              _textField(
                emailController,
                'Enter your email',
                Icons.email_outlined,
              ),

              const SizedBox(height: 20),

              _inputLabel('Password'),
              _textField(
                passwordController,
                'Enter your password',
                Icons.lock_outline,
                isPass: true,
              ),

              const SizedBox(height: 30),

              _actionButton('Log In', () {
                bool loginSuccess = true; // পরে API login check বসাতে পারবে

                if (loginSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginCheck(),
                    ),
                  );
                }
              }),

              const SizedBox(height: 20),

              _switchPageLink(
                "Don't have an account? ",
                "Sign up",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GmailconfirmPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),
              _orDivider(),
              const SizedBox(height: 25),

              if (!kIsWeb && Platform.isIOS) ...[
                _socialButton(
                  FontAwesomeIcons.apple,
                  'Continue with Apple',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
              ],

              _socialButton(
                FontAwesomeIcons.google,
                _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                isLoading: _isGoogleLoading,
              ),

              const SizedBox(height: 20),
              _findAccountButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoWidget() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: const Text(
      'UniRide',
      style: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _inputLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
  );

  Widget _textField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        bool isPass = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        obscureText: isPass ? _isPasswordHidden : false,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.mutedText),
          filled: true,
          fillColor: AppColors.inputFill,
          suffixIcon: isPass
              ? IconButton(
            onPressed: () {
              setState(() {
                _isPasswordHidden = !_isPasswordHidden;
              });
            },
            icon: Icon(
              _isPasswordHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.secondary,
            ),
          )
              : Icon(
            icon,
            color: AppColors.secondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String title, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    height: 58,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    ),
  );

  Widget _switchPageLink(
      String text,
      String linkText,
      VoidCallback onTap,
      ) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(color: AppColors.text),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              linkText,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );

  Widget _orDivider() => const Row(
    children: [
      Expanded(
        child: Divider(color: AppColors.border),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          'or',
          style: TextStyle(color: AppColors.mutedText),
        ),
      ),
      Expanded(
        child: Divider(color: AppColors.border),
      ),
    ],
  );

  Widget _socialButton(
      IconData icon,
      String text, {
        required VoidCallback? onTap,
        bool isLoading = false,
      }) =>
      SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                color: AppColors.text,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _findAccountButton() => TextButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FindAccount(),
        ),
      );
    },
    icon: const Icon(
      Icons.search,
      color: AppColors.secondary,
      size: 20,
    ),
    label: const Text(
      'Find my account',
      style: TextStyle(
        color: AppColors.secondary,
      ),
    ),
  );
}