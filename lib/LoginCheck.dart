import 'package:flutter/material.dart';
import 'RiderDashboard.dart';
import 'UserHome.dart';
import 'LogIn.dart';

class LoginCheck extends StatefulWidget {
  final String email;

  const LoginCheck({
    super.key,
    required this.email,
  });

  @override
  State<LoginCheck> createState() => _LoginCheckState();
}

class _LoginCheckState extends State<LoginCheck> {
  String? selectedRole; // Passenger / Rider
  bool isChecking = false;

  bool _hasValidUniversityDomain(String email) {
    final normalizedEmail = email.trim().toLowerCase();

    if (!normalizedEmail.contains('@')) return false;

    final emailParts = normalizedEmail.split('@');
    if (emailParts.length != 2) return false;

    final domainPart = emailParts[1];

    return domainPart == 'std.ewubd.edu' || domainPart == 'ewubd.edu';
  }

  Future<bool> checkRoleInDatabase(String email, String role) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();

    // Apatoto sudhu university domain thaklei allow
    if (!_hasValidUniversityDomain(normalizedEmail)) {
      return false;
    }

    // ================= BACKEND READY =================
    // Pore ekhane backend/database theke FULL email + role check hobe.
    // Example:
    //
    // final response = await yourApiService.getUserByEmail(normalizedEmail);
    // final List<String> rolesFromDatabase =
    //     (response['roles'] as List<dynamic>? ?? [])
    //         .map((e) => e.toString().toLowerCase().trim())
    //         .toList();
    //
    // return rolesFromDatabase.contains(role.trim().toLowerCase());

    // Apatoto valid university email hole Passenger/Rider jekono role e jete parbe
    return true;
  }

  Future<void> goNext() async {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a role first."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isChecking = true;
    });

    try {
      final String email = widget.email.trim().toLowerCase();

      final bool isValid = await checkRoleInDatabase(email, selectedRole!);

      if (!mounted) return;

      if (!_hasValidUniversityDomain(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please use your official university email address.",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "This email is not registered as ${selectedRole!}. Please select the correct role.",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (selectedRole == "Passenger") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UniRideHomePage(),
          ),
        );
      } else if (selectedRole == "Rider") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RiderDashboard(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Please try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isChecking = false;
        });
      }
    }
  }

  Widget _buildRoleTile(String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedRole == role
              ? const Color(0xFF14B8A6)
              : const Color(0xFFE5E7EB),
          width: selectedRole == role ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: RadioListTile<String>(
        value: role,
        groupValue: selectedRole,
        activeColor: const Color(0xFF14B8A6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          role,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          role == "Passenger"
              ? "Continue as passenger"
              : "Continue as rider",
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
          ),
        ),
        onChanged: isChecking
            ? null
            : (value) {
          setState(() {
            selectedRole = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: isChecking
              ? null
              : () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const UniRideLogin(),
              ),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: (selectedRole != null && !isChecking) ? goNext : null,
              child: isChecking
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Color(0xFF14B8A6),
                ),
              )
                  : Text(
                "Next",
                style: TextStyle(
                  fontSize: 16,
                  color: selectedRole != null
                      ? const Color(0xFF14B8A6)
                      : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                "Select Your Role",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose how you want to continue.",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              _buildRoleTile("Passenger"),
              _buildRoleTile("Rider"),
            ],
          ),
        ),
      ),
    );
  }
}