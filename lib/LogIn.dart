import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'RegistrationPage.dart';// রেজিস্ট্রেশন ফাইল ইমপোর্ট নিশ্চিত করুন
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb; // ওয়েব সাপোর্ট চেকের জন্য
import 'LoginCheck.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UniRideLogin(),
  ));
}

class UniRideLogin extends StatefulWidget {
  const UniRideLogin({super.key});

  @override
  State<UniRideLogin> createState() => _UniRideLoginState();
}

class _UniRideLoginState extends State<UniRideLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              const Text('Log In', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              _inputLabel('Email Address'),
              _textField(emailController, 'Enter your email', Icons.email_outlined),
              const SizedBox(height: 20),
              _inputLabel('Password'),
              _textField(passwordController, 'Enter your password', Icons.lock_outline, isPass: true),

              const SizedBox(height: 30),
              _actionButton('Log In', () {

                // এখানে পরে তুমি API login check বসাতে পারবে

                bool loginSuccess = true; // আপাতত ধরে নিচ্ছি login সফল

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
              _switchPageLink("Don't have an account? ", "Sign up", () {
                // এখান থেকে 'const' সরানো হয়েছে এরর দূর করতে
                Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalInfoForm()));
              }),

              const SizedBox(height: 25),
              _orDivider(),
              const SizedBox(height: 25),

              // ওয়েব ব্রাউজারে অ্যাপল বাটন এরর এড়াতে kIsWeb চেক করা হয়েছে
              if (!kIsWeb && Platform.isIOS) ...[
                _socialButton(FontAwesomeIcons.apple, 'Continue with Apple', onTap: () {}),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 20),
              _findAccountButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // হেল্পার উইজেটস (আপনার দেওয়া স্ট্রাকচার ঠিক রাখা হয়েছে)
  Widget _logoWidget() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
    child: const Text('UniRide', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
  );

  Widget _inputLabel(String label) => Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)));

  Widget _textField(TextEditingController controller, String hint, IconData icon, {bool isPass = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF3F3F3),
          suffixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _actionButton(String title, VoidCallback onPressed) => SizedBox(
    width: double.infinity, height: 58,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
    ),
  );

  Widget _switchPageLink(String text, String linkText, VoidCallback onTap) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(text),
      GestureDetector(onTap: onTap, child: Text(linkText, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))),
    ],
  );

  Widget _orDivider() => const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or')), Expanded(child: Divider())]);

  Widget _socialButton(IconData icon, String text, {required VoidCallback onTap}) => SizedBox(
    width: double.infinity, height: 56,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFEEEEEE), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [FaIcon(icon, color: Colors.black, size: 22), const SizedBox(width: 10), Text(text, style: const TextStyle(color: Colors.black, fontSize: 16))]),
    ),
  );

  Widget _findAccountButton() => TextButton.icon(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.grey, size: 20), label: const Text('Find my account', style: TextStyle(color: Colors.grey)));
}