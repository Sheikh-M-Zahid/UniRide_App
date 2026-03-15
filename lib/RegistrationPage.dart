import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ConfirmationPage.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PersonalInfoForm(),
    ),
  );
}

class PersonalInfoForm extends StatefulWidget {
  const PersonalInfoForm({super.key});

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  bool _isObscure = true;
  bool _isObscureConfirm = true;
  String? selectedBloodGroup;
  String? selectedOccupation;
  String? selectedGender;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final List<Map<String, String>> _countryList = [
    {'name': 'Bangladesh', 'code': '+880'},
    {'name': 'India', 'code': '+91'},
    {'name': 'Pakistan', 'code': '+92'},
    {'name': 'USA', 'code': '+1'},
    {'name': 'AUS', 'code': '+61'},
  ];

  String selectedCountry = 'Bangladesh';

  String get selectedCountryCode {
    return _countryList.firstWhere(
          (country) => country['name'] == selectedCountry,
    )['code']!;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF0F766E),
          width: 1.8,
        ),
      ),
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: Color(0xFF1F2937)),
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF0F766E),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Personal Information',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF14B8A6),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "First Name",
                  hintText: "Enter Your First Name",
                  prefixIcon: Icons.person,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'First Name is required'
                    : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "Last Name",
                  hintText: "Enter Your Last Name",
                  prefixIcon: Icons.person,
                ),
              ),
              const SizedBox(height: 15),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      value: selectedCountry,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 1.8,
                          ),
                        ),
                        labelText: "Country",
                        labelStyle:
                        const TextStyle(color: Color(0xFF1F2937)),
                        prefixIcon: const Icon(
                          Icons.flag,
                          color: Color(0xFF0F766E),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 16,
                        ),
                      ),
                      items: _countryList
                          .map(
                            (country) => DropdownMenuItem<String>(
                          value: country['name'],
                          child: Text(
                            country['name']!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCountry = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _phoneController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F766E),
                            width: 1.8,
                          ),
                        ),
                        labelText: "Phone Number",
                        hintText: "Enter Your Phone Number",
                        labelStyle:
                        const TextStyle(color: Color(0xFF1F2937)),
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: 42,
                            child: Center(
                              child: Text(
                                selectedCountryCode,
                                style: const TextStyle(
                                  color: Color(0xFF0F766E),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Only digits are allowed';
                        }
                        if (value.length < 7) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedOccupation,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F766E),
                      width: 1.8,
                    ),
                  ),
                  labelText: "Occupation",
                  hintText: "Enter Your University Role",
                  labelStyle: const TextStyle(color: Color(0xFF1F2937)),
                  prefixIcon: const Icon(
                    Icons.work,
                    color: Color(0xFF0F766E),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['Student', 'Faculty', 'Staff']
                    .map(
                      (group) => DropdownMenuItem<String>(
                    value: group,
                    child: Text(group),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedOccupation = value;
                  });
                },
                validator: (value) =>
                value == null ? 'Please select your occupation' : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F766E),
                      width: 1.8,
                    ),
                  ),
                  labelText: "Gender",
                  hintText: "Select Your Gender",
                  labelStyle: const TextStyle(color: Color(0xFF1F2937)),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF0F766E),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['Male', 'Female', 'Other']
                    .map(
                      (gender) => DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
                validator: (value) =>
                value == null ? 'Please select your gender' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "Present Area",
                  hintText: "e.g: Narayanganj",
                  prefixIcon: Icons.location_on,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Address is required'
                    : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: _isObscure,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F766E),
                      width: 1.8,
                    ),
                  ),
                  labelText: "Password",
                  hintText: "Current Password",
                  labelStyle: const TextStyle(color: Color(0xFF1F2937)),
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: Color(0xFF0F766E),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF0F766E),
                    ),
                    onPressed: () =>
                        setState(() => _isObscure = !_isObscure),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'At least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _isObscureConfirm,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F766E),
                      width: 1.8,
                    ),
                  ),
                  labelText: "Confirm Password",
                  hintText: "Confirm Password",
                  labelStyle: const TextStyle(color: Color(0xFF1F2937)),
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.lock_clock,
                    color: Color(0xFF0F766E),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF0F766E),
                    ),
                    onPressed: () => setState(
                          () => _isObscureConfirm = !_isObscureConfirm,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm Password is required';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                  child: const Text(
                    'Submit Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}