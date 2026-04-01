import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiService {
  // Android emulator হলে 10.0.2.2 ব্যবহার করবা
  // Real phone হলে তোমার PC এর local IP দিতে হবে
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();

      if (data['data'] != null && data['data']['token'] != null) {
        await prefs.setString('token', data['data']['token']);
      }

      if (data['data'] != null && data['data']['user'] != null) {
        await prefs.setString(
          'user_email',
          data['data']['user']['university_email'] ?? email,
        );
      }

      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  Future<bool> checkIfAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      return false;
    }

    final url = Uri.parse('$baseUrl/auth/me');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final user = data['data']['user'];
      final isAdmin = user['isAdmin'] == true;

      return isAdmin;
    } else {
      return false;
    }
  }

  Future<bool> checkUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/user/check-role?role=$role');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    return data['hasRole'] == true;
  }

  Future<Map<String, dynamic>> googleLogin({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/google-login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();

      if (data['data'] != null && data['data']['token'] != null) {
        await prefs.setString('token', data['data']['token']);
      }

      if (data['data'] != null && data['data']['user'] != null) {
        await prefs.setString(
          'user_email',
          data['data']['user']['university_email'] ?? email,
        );
      }

      return data;
    } else {
      throw Exception(data['message'] ?? 'Google login failed');
    }
  }

  Future<Map<String, dynamic>> getRoleOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/user/me/role-options');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception('Failed to fetch role options');
    }
  }

  Future<Map<String, dynamic>> findAccount({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/find-account');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Account not found');
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/user/me/profile');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load profile');
    }
  }

  Future<Map<String, dynamic>> updateMyProfile({
    required String phone,
    required String recoveryPhone,
    required String emergencyPhone,
    required String gender,
    required String dateOfBirth,
    required String homeAddress,
    required String hostelAddress,
    required String campusAddress,
    String? bloodGroup,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/user/me/profile');

    final body = {
      'phone': phone,
      'recovery_phone': recoveryPhone,
      'emergency_phone': emergencyPhone,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'home_address': homeAddress,
      'hostel_address': hostelAddress,
      'campus_address': campusAddress,
    };

    if (bloodGroup != null && bloodGroup.trim().isNotEmpty) {
      body['blood_group'] = bloodGroup;
    }

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }
  }

  Future<Map<String, dynamic>> updateProfilePicture(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/user/me/profile-picture'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('profile_picture', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to upload profile picture');
    }
  }

  String getFullImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final base = baseUrl.replaceAll('/api', '');
    return '$base$path';
  }

  Future<Map<String, dynamic>> submitHelpRequest({
    required String message,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/support/help');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Help request failed');
    }
  }

  Future<Map<String, dynamic>> calculateReserveRide({
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final url = Uri.parse('$baseUrl/reserve/calculate');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Reserve calculation failed');
    }
  }

  //ResetPassword
  Future<Map<String, dynamic>> resetPasswordWithToken({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/reset-password-with-token');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Password reset failed');
    }
  }

  Future<Map<String, dynamic>> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/auth/verify-recovery-otp');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'OTP verification failed');
    }
  }

  //PasswordRecoveryOTP
  Future<Map<String, dynamic>> resendRecoveryOtp({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/resend-recovery-otp');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to resend OTP');
    }
  }
}