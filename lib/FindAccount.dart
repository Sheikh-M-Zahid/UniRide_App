import 'package:flutter/material.dart';

class FindAccount extends StatefulWidget {
  const FindAccount({super.key});

  @override
  State<FindAccount> createState() => _FindAccountState();
}

class _FindAccountState extends State<FindAccount> {

  final TextEditingController _emailController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 40),

              const Text("Find Your Account",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              const Text("Enter your university email",
                style: TextStyle(
                    fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Enter your university email",
                  filled: true,
                  fillColor:
                  const Color(0xFFF3F3F3),
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text("Please check your mail box."),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Search",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16),
                  ),
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: () =>
                    Navigator.pop(context),
                child: const Text("Back to Login",
                  style:
                  TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}