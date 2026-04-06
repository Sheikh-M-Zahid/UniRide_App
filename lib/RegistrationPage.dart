import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ConfirmationPage.dart';
import 'services/auth_api_service.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PersonalInfoForm(
        signupToken: '',
        email: '',
      ),
    ),
  );
}

class PersonalInfoForm extends StatefulWidget {
  final String signupToken;
  final String email;

  const PersonalInfoForm({
    super.key,
    required this.signupToken,
    required this.email,
  });

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  final AuthApiService _authApiService = AuthApiService();

  bool _isSubmitting = false;
  String? signupToken;
  String? userEmail;

  bool _isObscure = true;
  bool _isObscureConfirm = true;

  String? selectedBloodGroup;
  String? selectedOccupation;
  String? selectedGender;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _recoveryPhoneController =
  TextEditingController();
  final TextEditingController _emergencyPhoneController =
  TextEditingController();
  final TextEditingController _dateOfBirthController =
  TextEditingController();
  final TextEditingController _homeAddressController =
  TextEditingController();
  final TextEditingController _hostelAddressController =
  TextEditingController();
  final TextEditingController _campusAddressController =
  TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  final List<Map<String, String>> _countryList = [
    {'name': 'Bangladesh', 'code': '+880'},
    {'name': 'India', 'code': '+91'},
    {'name': 'Pakistan', 'code': '+92'},
    {'name': 'USA', 'code': '+1'},
    {'name': 'AUS', 'code': '+61'},
  ];

  final List<String> _bloodGroups = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  String selectedCountry = 'Bangladesh';

  String get selectedCountryCode {
    return _countryList.firstWhere(
          (country) => country['name'] == selectedCountry,
    )['code']!;
  }

  @override
  void initState() {
    super.initState();
    signupToken = widget.signupToken;
    userEmail = widget.email;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _recoveryPhoneController.dispose();
    _emergencyPhoneController.dispose();
    _dateOfBirthController.dispose();
    _homeAddressController.dispose();
    _hostelAddressController.dispose();
    _campusAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: Color(0xFF1F2937)),
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF0F766E),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if ((signupToken ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid signup session. Please verify OTP again.',
          ),
        ),
      );
      return;
    }

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authApiService.registerUser(
        signupToken: signupToken!.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        recoveryPhone: _recoveryPhoneController.text.trim().isEmpty
            ? null
            : _recoveryPhoneController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        gender: (selectedGender ?? '').trim(),
        bloodGroup: selectedBloodGroup,
        dateOfBirth: _dateOfBirthController.text.trim(),
        homeAddress: _homeAddressController.text.trim(),
        hostelAddress: _hostelAddressController.text.trim(),
        campusAddress: _campusAddressController.text.trim().isEmpty
            ? null
            : _campusAddressController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ConfirmationPage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
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
              if ((userEmail ?? '').trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF0F766E),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userEmail!,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],

              TextFormField(
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "First Name",
                  hintText: "Enter Your First Name",
                  prefixIcon: Icons.person,
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'First Name is required'
                    : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "Last Name",
                  hintText: "Enter Your Last Name",
                  prefixIcon: Icons.person,
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'Last Name is required'
                    : null,
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
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
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
                  labelText: "Occupation",
                  hintText: "Enter Your University Role",
                  labelStyle:
                  const TextStyle(color: Color(0xFF1F2937)),
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
                  labelText: "Gender",
                  hintText: "Select Your Gender",
                  labelStyle:
                  const TextStyle(color: Color(0xFF1F2937)),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF0F766E),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['male', 'female']
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

              DropdownButtonFormField<String>(
                value: selectedBloodGroup,
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
                  labelText: "Blood Group (Optional)",
                  hintText: "Select Blood Group",
                  labelStyle:
                  const TextStyle(color: Color(0xFF1F2937)),
                  prefixIcon: const Icon(
                    Icons.bloodtype,
                    color: Color(0xFF0F766E),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _bloodGroups
                    .map(
                      (group) => DropdownMenuItem<String>(
                    value: group,
                    child: Text(group),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBloodGroup = value;
                  });
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _hostelAddressController,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "Hostel Address",
                  hintText: "Enter Your Hostel Address",
                  prefixIcon: Icons.location_on,
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'Hostel address is required'
                    : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _homeAddressController,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "Home Address",
                  hintText: "Enter Your Home Address",
                  prefixIcon: Icons.home,
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'Home address is required'
                    : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _campusAddressController,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "Campus Address (Optional)",
                  hintText: "Enter Campus Address",
                  prefixIcon: Icons.location_city,
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _recoveryPhoneController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9+]'),
                  ),
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: _buildInputDecoration(
                  labelText: "Recovery Phone (Optional)",
                  hintText: "Enter Recovery Phone",
                  prefixIcon: Icons.phone_in_talk,
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _emergencyPhoneController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9+]'),
                  ),
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: _buildInputDecoration(
                  labelText: "Emergency Phone (Optional)",
                  hintText: "Enter Emergency Phone",
                  prefixIcon: Icons.emergency,
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _dateOfBirthController,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "Date of Birth",
                  hintText: "YYYY-MM-DD",
                  prefixIcon: Icons.calendar_today,
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'Date of birth is required'
                    : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: _isObscure,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  labelText: "Password",
                  hintText: "Enter Password",
                  prefixIcon: Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF0F766E),
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Password is required';
                  }
                  if (value.trim().length < 6) {
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
                decoration: _buildInputDecoration(
                  labelText: "Confirm Password",
                  hintText: "Confirm Password",
                  prefixIcon: Icons.lock_clock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF0F766E),
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureConfirm = !_isObscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Confirm Password is required';
                  }
                  if (value.trim() != _passwordController.text.trim()) {
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
                  onPressed: _isSubmitting ? null : _registerUser,
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
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