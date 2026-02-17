import 'package:flutter/material.dart';
import 'ConfirmationPage.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PersonalInfoForm(),
  ));
}

class PersonalInfoForm extends StatefulWidget {
  @override
  _PersonalInfoFormState createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  // ১. ভেরিয়েবল এবং কন্ট্রোলার ডিক্লেয়ারেশন
  bool _isObscure = true;
  bool _isObscureConfirm = true;
  String? selectedBloodGroup;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // ২. মেমোরি লিক রোধ করতে ডিসপোজ মেথড
  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: _formKey, // ফর্ম ভ্যালিডেশনের জন্য দরকার
          child: Column(
            children: [
              // ফার্স্ট নেম
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelText: "First Name",
                  hintText: "Enter Your First Name",
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'First Name is required' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelText: "Last Name",
                  hintText: "Enter Your Last Name",
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),

              // ফোন নাম্বার
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelText: "Phone Number",
                  hintText: "Enter Your Phone Number",
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 15),

              // ব্লাড গ্রুপ ড্রপডাউন
              DropdownButtonFormField<String>(
                value: selectedBloodGroup,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelText: "Occupation",
                  hintText: "Enter Your University Role",
                  prefixIcon: const Icon(Icons.work, color: Colors.black),
                ),
                items: ['Student','Faculty', 'Staff']
                    .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBloodGroup = value;
                  });
                },
                validator: (value) => value == null ? 'Please select your occupation' : null,
              ),
              const SizedBox(height: 15),

              // প্রেজেন্ট এরিয়া
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelText: "Present Area",
                  hintText: "e.g: Narayanganj",
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Address is required' : null,
              ),
              const SizedBox(height: 15),

              // পাসওয়ার্ড ফিল্ড
              TextFormField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelText: "Password",
                  hintText: "Current Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
                validator: (value) => (value != null && value.length < 6) ? 'At least 6 characters' : null,
              ),
              const SizedBox(height: 15),

              // কনফার্ম পাসওয়ার্ড ফিল্ড
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _isObscureConfirm,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelText: "Confirm Password",
                  hintText: "Confirm Password",
                  prefixIcon: const Icon(Icons.lock_clock),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // সাবমিট বাটন
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConfirmationPage(),
                        ),
                      );

                    }
                  },
                  child: const Text('Submit Information', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}