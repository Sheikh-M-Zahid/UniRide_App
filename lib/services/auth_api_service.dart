import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiService {
  static String get baseUrl {
    return 'https://uniride-app-rm20.onrender.com/api';
  }

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
        final firstName = data['data']['user']['first_name'] ?? '';
        final lastName = data['data']['user']['last_name'] ?? '';
        final fullName = ('$firstName $lastName').trim();

        if (fullName.isNotEmpty) {
          await prefs.setString('user_name', fullName);
        }
      }

      if (data['data'] != null && data['data']['user'] != null) {
        final rawUserId =
            data['data']['user']['user_id'] ??
                data['data']['user']['id'] ??
                '';

        if (rawUserId.toString().trim().isNotEmpty) {
          await prefs.setString('user_id', rawUserId.toString());
        }
      }

      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_admin', data['data']?['isAdmin'] == true);

// ✅ ADD THESE
      await prefs.setInt(
        'last_login_at',
        DateTime.now().millisecondsSinceEpoch,
      );

      if (data['data']?['isAdmin'] == true) {
        await prefs.setString('last_role', 'admin');
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
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception(
        'Server is waking up, please try again in a moment.',
      ),
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

    final url = Uri.parse('$baseUrl/users/check-role?role=$role');

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

      if (data['data'] != null && data['data']['user'] != null) {
        final rawUserId =
            data['data']['user']['user_id'] ??
                data['data']['user']['id'] ??
                '';

        if (rawUserId.toString().trim().isNotEmpty) {
          await prefs.setString('user_id', rawUserId.toString());
        }
      }

      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_admin', data['data']?['isAdmin'] == true);

// ✅ ADD
      await prefs.setInt(
        'last_login_at',
        DateTime.now().millisecondsSinceEpoch,
      );

      if (data['data']?['isAdmin'] == true) {
        await prefs.setString('last_role', 'admin');
      }

      return data;
    } else {
      throw Exception(data['message'] ?? 'Google login failed');
    }
  }

  Future<Map<String, dynamic>> getRoleOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/users/me/role-options');

    print("ROLE OPTIONS URL => $url");
    print("TOKEN SENT => $token");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("STATUS CODE => ${response.statusCode}");
    print("RAW RESPONSE => ${response.body}");

    final contentType = response.headers['content-type'] ?? '';

    if (!contentType.contains('application/json')) {
      throw Exception("Server returned non-JSON response");
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch role options');
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

    final url = Uri.parse('$baseUrl/users/profile');

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

    final url = Uri.parse('$baseUrl/users/profile');

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

    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'png' : 'jpeg';

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/profile/image'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
        contentType: MediaType('image', mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.body.isEmpty) {
      throw Exception('Empty response from server');
    }

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

    final url = Uri.parse('$baseUrl/help/submit');

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


  Future<Map<String, dynamic>> createReserve({
    required String pickupLocation,
    required String destinationLocation,
    required String travelDate,
    required String travelTime,
    required int selectedSeats,
    required String genderPreference,
    required String vehicleType,
    required double totalDistanceKm,
    required int estimatedTravelMinutes,
    required double estimatedCost,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String mappedVehicleType = vehicleType.trim().toLowerCase();
    if (mappedVehicleType == 'car') mappedVehicleType = 'car';
    if (mappedVehicleType == 'bike') mappedVehicleType = 'bike';

    String mappedGenderPreference = genderPreference.trim().toLowerCase();
    if (mappedGenderPreference == 'no preference') {
      mappedGenderPreference = 'any';
    }

    final url = Uri.parse('$baseUrl/reserve/create');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'pickup_location': pickupLocation,
        'destination_location': destinationLocation,
        'travel_date': travelDate,
        'travel_time': travelTime,
        'selected_seats': selectedSeats,
        'gender_preference': mappedGenderPreference,
        'vehicle_type': mappedVehicleType,
        'total_distance_km': totalDistanceKm,
        'estimated_travel_minutes': estimatedTravelMinutes,
        'estimated_cost': estimatedCost,
        'note': (note ?? '').trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Reserve request failed');
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

  //RiderDashboard
  Future<Map<String, dynamic>> getRiderDashboardSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/rider/dashboard');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final contentType = response.headers['content-type'] ?? '';

    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server returned non-JSON response. Check rider dashboard API.',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load dashboard');
    }
  }

  Future<Map<String, dynamic>> updateRiderStatus({
    required bool isOnline,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/rider/dashboard/status');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'is_online': isOnline,
      }),
    );

    final contentType = response.headers['content-type'] ?? '';

    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server returned non-JSON response. Check rider status API.',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update status');
    }
  }

  //ActiveRiderPage.dart
  Future<Map<String, dynamic>> getActiveRiders({
    String search = '',
    String filter = 'all_active',
    String location = '',
    int page = 1,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/rider/active-riders').replace(
      queryParameters: {
        'search': search,
        'filter': filter,
        'location': location,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final contentType = response.headers['content-type'] ?? '';

    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server returned non-JSON response. Check rider dashboard API.',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load dashboard');
    }
  }

  //EarningPage.dart
  Future<Map<String, dynamic>> getEarningsDashboard({
    String range = 'today',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/rider/earnings').replace(
      queryParameters: {
        'range': range,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load earnings dashboard');
    }
  }

  //AdminHome.dart
  Future<Map<String, dynamic>> getAdminDashboardSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/dashboard');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load admin dashboard');
    }
  }

  //RiderVerifyByAdmin.dart

  Future<Map<String, dynamic>> getPendingRiderVerificationRequests({
    String search = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse(
      '$baseUrl/admin/vehicles/rider-verifications',
    ).replace(
      queryParameters: {
        'search': search,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to load rider verification requests',
      );
    }
  }

  Future<Map<String, dynamic>> getRiderVerificationRequestDetails({
    required String vehicleId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse(
      '$baseUrl/admin/vehicles/rider-verifications/$vehicleId',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to load rider verification details',
      );
    }
  }

  Future<Map<String, dynamic>> approveRiderVerificationRequest({
    required String vehicleId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse(
      '$baseUrl/admin/vehicles/rider-verifications/$vehicleId/approve',
    );

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to approve rider verification request',
      );
    }
  }

  Future<Map<String, dynamic>> rejectRiderVerificationRequest({
    required String vehicleId,
    required String reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse(
      '$baseUrl/admin/vehicles/rider-verifications/$vehicleId/reject',
    );

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'reason': reason,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to reject rider verification request',
      );
    }
  }

  //GmailConfirm.dart
  Future<Map<String, dynamic>> sendSignupOtp({
    required String email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/send-signup-otp');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      )
          .timeout(const Duration(seconds: 50));

      final contentType = response.headers['content-type'] ?? '';

      if (!contentType.contains('application/json')) {
        throw Exception(
          'Server returned non-JSON response. Check auth route and backend deployment.',
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to send signup OTP');
      }
    } on SocketException {
      throw Exception(
        'Cannot connect to backend server. Check backend server and internet connection.',
      );
    } on http.ClientException {
      throw Exception(
        'Request failed. Check backend URL and deployment.',
      );
    }
  }

  Future<Map<String, dynamic>> googleSignupCheck({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/google-signup-check');

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
      throw Exception(data['message'] ?? 'Google signup check failed');
    }
  }

  //OTPVerificationPage.dart
  Future<Map<String, dynamic>> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/auth/verify-signup-otp');

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

  Future<Map<String, dynamic>> resendSignupOtp({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/resend-signup-otp');

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

  //UserSetting.dart
  Future<Map<String, dynamic>> getSettingsSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/settings/summary');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load settings summary');
    }
  }

  //WalletPage.dart
  Future<Map<String, dynamic>> getWalletSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/wallet/summary');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load wallet summary');
    }
  }
  Future<Map<String, dynamic>> payDue({
    required String method,
    required String referenceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/wallet/pay-due');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'method': method,
        'reference_id': referenceId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Due payment failed');
    }
  }

  //RegistrationPage.dart
  Future<Map<String, dynamic>> registerUser({
    required String signupToken,
    required String firstName,
    required String lastName,
    required String phone,
    String? recoveryPhone,
    String? emergencyPhone,
    required String gender,
    String? bloodGroup,
    required String dateOfBirth,
    required String homeAddress,
    String? hostelAddress,
    String? campusAddress,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'signupToken': signupToken,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'recovery_phone': recoveryPhone,
        'emergency_phone': emergencyPhone,
        'gender': gender,
        'blood_group': bloodGroup,
        'date_of_birth': dateOfBirth,
        'home_address': homeAddress,
        if (hostelAddress != null && hostelAddress.isNotEmpty)
          'hostel_address': hostelAddress,
        'campus_address': campusAddress,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  //UserServices.dart
  Future<Map<String, dynamic>> getServicesSummary() async {
    final url = Uri.parse('$baseUrl/services/summary');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load services summary');
    }
  }

  //SendItem.dart
  Future<Map<String, dynamic>> validateSendItemReceiver({
    required String receiverEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/send-items/validate-receiver');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'receiver_email': receiverEmail,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Receiver validation failed');
    }
  }

  Future<Map<String, dynamic>> createSendItemRequest({
    required String receiverEmail,
    required String itemType,
    required String itemWeight,
    required String senderName,
    required String senderPhone,
    String? pickupLocation,
    required String dropLocation,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
    String? riderId,
    String? riderPhone,
    double? deliveryFee,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/send-items');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'receiver_email': receiverEmail,
        'item_type': itemType,
        'item_weight': itemWeight,
        'sender_name': senderName,
        'sender_phone': senderPhone,
        'pickup_location': pickupLocation,
        'destination_location': dropLocation,
        'drop_location': dropLocation,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
        'rider_id': riderId,
        'rider_phone': riderPhone,
        'delivery_fee': deliveryFee,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create send item request');
    }
  }

  Future<Map<String, dynamic>> getMySendItemRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/send-items/my-sent');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load send item requests');
    }
  }

  // SendItemTracking.dart
  Future<Map<String, dynamic>> getSendItemDetails({
    required String sId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/send-items/$sId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load item details');
    }
  }

  Future<Map<String, dynamic>> cancelSendItem({
    required String sId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/send-items/$sId/cancel');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to cancel delivery');
    }
  }

  //RideSelection.dart
  Future<Map<String, dynamic>> getVehicleSelectionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/vehicle-selection/status');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to load vehicle selection status',
      );
    }
  }

  Future<Map<String, dynamic>> selectVehicleType({
    required String selectedVehicleType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/vehicle-selection/select');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'selectedVehicleType': selectedVehicleType,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to process vehicle selection',
      );
    }
  }

  //BikeRegistration.dart
  Future<Map<String, dynamic>> registerBike({
    required String company,
    required String model,
    required String year,
    required String numberPlate,
    required File varsityIdPhoto,
    required File driverProfilePhoto,
    required File drivingLicensePhoto,
    required File vehicleRegistrationPhoto,
    required File taxTokenPhoto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please try again.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/rider/bike/register'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['company'] = company;
    request.fields['model'] = model;
    request.fields['year'] = year;
    request.fields['number_plate'] = numberPlate;

    request.files.add(
      await http.MultipartFile.fromPath(
        'varsity_id_photo',
        varsityIdPhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'driver_profile_photo',
        driverProfilePhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'driving_license_photo',
        drivingLicensePhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'vehicle_registration_photo',
        vehicleRegistrationPhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'tax_token_photo',
        taxTokenPhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Upload timed out. Please check your internet connection.'),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Bike registration failed');
    }
  }

  //PrivateCarRegistration.dart
  Future<Map<String, dynamic>> registerCar({
    required String company,
    required String model,
    required String year,
    required String numberPlate,
    required File varsityIdPhoto,
    required File driverProfilePhoto,
    required File drivingLicensePhoto,
    required File vehicleRegistrationPhoto,
    required File taxTokenPhoto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please try again.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/rider/car/register'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['company'] = company;
    request.fields['model'] = model;
    request.fields['year'] = year;
    request.fields['number_plate'] = numberPlate;

    request.files.add(
      await http.MultipartFile.fromPath(
        'varsity_id_photo',
        varsityIdPhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'driver_profile_photo',
        driverProfilePhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'driving_license_photo',
        drivingLicensePhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'vehicle_registration_photo',
        vehicleRegistrationPhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'tax_token_photo',
        taxTokenPhoto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Upload timed out. Please check your internet connection.'),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Car registration failed');
    }
  }

  //RegisteredVehicles.dart
  Future<Map<String, dynamic>> getMyVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/vehicles');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load vehicles');
    }
  }

  Future<Map<String, dynamic>> getVehicleDocuments({
    required String vehicleId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/vehicles/$vehicleId/documents');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load vehicle documents');
    }
  }

  //RiderDelivery.dart
  Future<Map<String, dynamic>> getRiderDeliveryDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/delivery/dashboard');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load delivery dashboard');
    }
  }

  Future<Map<String, dynamic>> acceptDeliveryRequest({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/delivery/requests/$requestId/accept');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to accept delivery request');
    }
  }

  Future<Map<String, dynamic>> rejectDeliveryRequest({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/delivery/requests/$requestId/reject');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to reject delivery request');
    }
  }

  Future<Map<String, dynamic>> sendDeliveryOtp({
    required String deliveryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/delivery/$deliveryId/send-delivery-otp');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> markDeliveryAsDelivered({
    required String deliveryId,
    required String otp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/delivery/$deliveryId/mark-delivered');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'otp': otp}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to mark delivery as delivered');
    }
  }

  Future<Map<String, dynamic>> markDeliveryAsPickedUp({
    required String deliveryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/delivery/$deliveryId/mark-picked-up');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to mark as picked up');
    }
  }

  //RiderSetting.dart
  Future<Map<String, dynamic>> getRiderSettingsSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/settings');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load rider settings summary');
    }
  }

  //RiderProfile.dart
  Future<Map<String, dynamic>> getRiderProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/profile');

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
      throw Exception(data['message'] ?? 'Failed to load rider profile');
    }
  }

  Future<Map<String, dynamic>> uploadRiderProfileImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/rider/profile/image'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'profilePicture',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to upload rider profile image');
    }
  }

  //RiderMap.dart
  Future<Map<String, dynamic>> getRiderMapDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/map/dashboard');

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
      throw Exception(data['message'] ?? 'Failed to load rider map dashboard');
    }
  }

  Future<Map<String, dynamic>> updateRiderLocation({
    required double lat,
    required double lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/map/location');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'lat': lat,
        'lng': lng,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update rider location');
    }
  }

  Future<Map<String, dynamic>> acceptRideRequestFromMap({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/map/ride-requests/$requestId/accept');

    final response = await http.post(
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
      throw Exception(data['message'] ?? 'Failed to accept ride request');
    }
  }

  Future<Map<String, dynamic>> startRideNavigation({
    required String rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/map/ride/$rideId/start-navigation');

    final response = await http.post(
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
      throw Exception(data['message'] ?? 'Failed to start navigation');
    }
  }

  Future<Map<String, dynamic>> completeRideFromMap({
    required String rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/map/ride/$rideId/complete');

    final response = await http.post(
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
      throw Exception(data['message'] ?? 'Failed to complete ride');
    }
  }

  // ReportProblemPage.dart
  Future<Map<String, dynamic>> submitReport({
    required String comment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/reports');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'comment': comment,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to submit report');
    }
  }

  Future<Map<String, dynamic>> getMyReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/reports/my');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load reports');
    }
  }

  //UserActivity.dart
  Future<Map<String, dynamic>> getActivityDashboard({
    String type = 'all',
    String time = 'today',
    int page = 1,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final mappedTime = time == 'this_week'
        ? 'week'
        : time == 'this_month'
        ? 'month'
        : time;

    final uri = Uri.parse('$baseUrl/rider/activity/dashboard').replace(
      queryParameters: {
        'type': type,
        'time': mappedTime,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final contentType = response.headers['content-type'] ?? '';

    if (!contentType.contains('application/json')) {
      throw Exception('Server returned non-JSON response');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load activity dashboard');
    }
  }

  // UpcomingReservePage.dart
  Future<Map<String, dynamic>> getUpcomingReserve() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/reserve/upcoming');

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
      throw Exception(data['message'] ?? 'Failed to load upcoming reserve');
    }
  }

  Future<Map<String, dynamic>> acceptReserveRequest({
    required String reserveId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/reserve/$reserveId/accept');

    final response = await http.patch(
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
      throw Exception(data['message'] ?? 'Failed to accept reserve request');
    }
  }

  // UserHome.dart
  Future<Map<String, dynamic>> getServicesSummaryPublic() async {
    final url = Uri.parse('$baseUrl/services/summary');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load services summary');
    }
  }

  //help_support_page.dart
  Future<Map<String, dynamic>> submitHelpRequestpage({
    required String message,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/help/submit');

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

  //RiderRequestModel.dart
  Future<Map<String, dynamic>> createRideRequest({
    required String riderId,
    required String pickupLocation,
    required String destination,
    required double pickupLatitude,
    required double pickupLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/passenger/ride-request/create');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'riderId': riderId,
        'pickupLocation': pickupLocation,
        'destination': destination,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create ride request');
    }
  }

  Future<Map<String, dynamic>> getPendingRideRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/ride-requests/pending');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load pending ride requests');
    }
  }

  Future<Map<String, dynamic>> acceptRideRequest({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/$requestId/accept');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Server error (${response.statusCode}). Route not found.');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to accept ride request');
    }
  }

  Future<Map<String, dynamic>> rejectRideRequest({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/$requestId/reject');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Server error (${response.statusCode}). Route not found.');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to reject ride request');
    }
  }

  Future<Map<String, dynamic>> cancelConfirmedRide({
    required String requestId,
    String cancelReason = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // ✅ URL ঠিক করা হয়েছে — server.js এ mount prefix অনুযায়ী
    final url = Uri.parse('$baseUrl/rider/active-ride/confirmed-ride/$requestId/cancel');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'cancelReason': cancelReason,
      }),
    );

    // ✅ Content-type check যোগ করা হয়েছে
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server error (${response.statusCode}). Cancel ride route not found. Check backend.',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to cancel confirmed ride');
    }
  }

  Future<Map<String, dynamic>> startRide({
    required String rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/rides/$rideId/start');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to start ride');
    }
  }

  Future<Map<String, dynamic>> completeRide({
    required String rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rider/rides/$rideId/complete');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to complete ride');
    }
  }

  //LogIn.dart
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final lastLoginMillis = prefs.getInt('last_login_at');

    if (lastLoginMillis != null) {
      final lastLoginTime = DateTime.fromMillisecondsSinceEpoch(lastLoginMillis);
      final now = DateTime.now();

      if (now.difference(lastLoginTime).inDays >= 30) {
        await logout();
        return false;
      }
    }

    return isLoggedIn && token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint("Logout prefs clear error: $e");
    }
  }

  //ConfirmationPage.dart
  Future<Map<String, dynamic>> getConfirmationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/confirmation/status');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load confirmation status');
    }
  }

  Future<Map<String, dynamic>> selectConfirmationMode({
    required String selectedMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/confirmation/select-mode');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'selectedMode': selectedMode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to process selected mode');
    }
  }

  //Saved_Place_page.dart
  Future<Map<String, dynamic>> getSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/me/saved-places');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load saved places');
    }
  }

  Future<Map<String, dynamic>> updateSavedPlaces({
    required String homeAddress,
    required String campusAddress,
    required String hostelAddress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/me/saved-places');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'homeAddress': homeAddress,
        'campusAddress': campusAddress,
        'hostelAddress': hostelAddress,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update saved places');
    }
  }

  //ride_history_page.dart
  Future<Map<String, dynamic>> getRideHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/history');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load ride history');
    }
  }

  //RiderRideHistory.dart
  Future<Map<String, dynamic>> getRiderRideHistory({
    String search = '',
    String range = '',
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final queryParams = {
      'search': search,
      'range': range,
      if (month != null) 'month': month.toString(),
      if (year != null) 'year': year.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/rider/ride-history')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load ride history');
    }
  }

  //AllPassengerPage.dart
  Future<Map<String, dynamic>> getAllRiders({
    String search = '',
    String filter = 'all',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/admin/riders').replace(
      queryParameters: {
        'search': search,
        'filter': filter,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load riders');
    }
  }

  Future<Map<String, dynamic>> updateAdminRiderStatus({
    required String riderId,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/riders/$riderId/status');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update rider status');
    }
  }

  //AddOfferPage.dart
  Future<Map<String, dynamic>> createOffer({
    required String offerName,
    required String offerType,
    required String offerCategory,
    required String rewardPercentage,
    required String eligibleUser,
    required String startDate,
    required String endDate,
    required String promoCode,
    required String conditions,
    required String usageLimitType,
    required String conditionType,
    int? conditionValue,
    required String eligibleRideType,
    int? maxTotalUses,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/offers');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'offer_name': offerName,
        'offer_type': offerType,
        'offer_category': offerCategory,
        'reward_percentage': int.tryParse(rewardPercentage) ?? 0,
        'eligible_user': eligibleUser.toLowerCase(),
        'start_date': startDate,
        'end_date': endDate,
        'promo_code': promoCode,
        'conditions': conditions,
        'usage_limit_type': usageLimitType,
        'condition_type': conditionType,
        'eligible_ride_type': eligibleRideType,
        if (conditionValue != null) 'condition_value': conditionValue,
        if (maxTotalUses != null) 'max_total_uses': maxTotalUses,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create offer');
    }
  }

  //RideSearch.dart
  Future<Map<String, dynamic>> searchRides({
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/rides/search');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
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
      throw Exception(data['message'] ?? 'Ride search failed');
    }
  }

  // AdminPaymentApproval.dart
  Future<Map<String, dynamic>> getPaymentRequests({
    String search = '',
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/admin/payment-approvals').replace(
      queryParameters: {
        'search': search,
        'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load payment requests');
    }
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String paymentDbId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/payment-approvals/$paymentDbId/confirm');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to confirm payment');
    }
  }

  Future<Map<String, dynamic>> declinePayment({
    required String paymentDbId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/payment-approvals/$paymentDbId/decline');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to decline payment');
    }
  }

  //AdminProfile.dart
  Future<Map<String, dynamic>> getAdminProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/profile');

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
      throw Exception(data['message'] ?? 'Failed to load admin profile');
    }
  }

  Future<Map<String, dynamic>> updateAdminProfile({
    required String fullName,
    required String phone,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/profile/edit');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName,
        'phone': phone,
        'gender': gender,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update admin profile');
    }
  }

  Future<Map<String, dynamic>> updateAdminProfileImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/admin/profile/image'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = (ext == 'png') ? 'png' : (ext == 'webp') ? 'webp' : 'jpeg';
    request.files.add(
      await http.MultipartFile.fromPath(
        'profilePicture',
        imageFile.path,
        contentType: MediaType('image', mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to upload admin profile image');
    }
  }

  //AdminReportsPage.dart
  Future<Map<String, dynamic>> getAdminReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/reports');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load admin reports');
    }
  }

  Future<Map<String, dynamic>> markAdminReportAsSolved({
    required String reportId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/reports/$reportId/solve');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to mark report as solved');
    }
  }

  //AllPassenger.dart (Admin Dashboard)
  Future<Map<String, dynamic>> getAllPassengers({
    String search = '',
    String filter = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/admin/passengers').replace(
      queryParameters: {
        'search': search,
        'filter': filter,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load passengers');
    }
  }

  //RideSharingHistory.dart (Admin)
  Future<Map<String, dynamic>> getAdminRiderSharingHistory({
    String search = '',
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/admin/rider-sharing-history').replace(
      queryParameters: {
        'search': search,
        'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to load rider sharing history',
      );
    }
  }

  //SharingCaringHistory.dart (Admin)
  Future<Map<String, dynamic>> getAdminSharingCaringHistory({
    String search = '',
    String status = 'all',
    String safety = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/admin/sharing-caring-history').replace(
      queryParameters: {
        'search': search,
        'status': status,
        'safety': safety,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to load sharing & caring history',
      );
    }
  }

  //TopLocationPage.dart (Admin)
  Future<Map<String, dynamic>> getAdminTopLocationStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/top-locations');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load top location stats');
    }
  }

  //AppStats.dart (Admin)
  Future<Map<String, dynamic>> getAdminAppStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/admin/app-stats');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load app statistics');
    }
  }

  //RideOptions.dart
  Future<Map<String, dynamic>> getRideOptions({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    String genderPreference = 'Any',
    String vehicleType = 'All',
    String userType = 'All',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rides/options');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'genderPreference': genderPreference,
        'vehicleType': vehicleType,
        'userType': userType,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load ride options');
    }
  }

  Future<Map<String, dynamic>> createRideAvailabilityAlert({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    String genderPreference = 'Any',
    String vehicleType = 'All',
    String userType = 'All',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rides/notify-availability');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'genderPreference': genderPreference,
        'vehicleType': vehicleType,
        'userType': userType,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create ride alert');
    }
  }

  //RideDetailsPage.dart
  Future<Map<String, dynamic>> getRideDetails({
    required String rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rides/$rideId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load ride details');
    }
  }

  Future<Map<String, dynamic>> joinRide({
    required String rideId,
    required double fare,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rides/$rideId/join');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fare': fare,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to join ride');
    }
  }

  Future<Map<String, dynamic>> confirmRideParticipant({
    required String rideId,
    required String participantId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse(
      '$baseUrl/rides/$rideId/participants/$participantId/confirm',
    );

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to confirm participant');
    }
  }

  //SharingCaringPage.dart
  Future<Map<String, dynamic>> createCompanySharingSession({
    required String startLocation,
    required String destination,
    required String status,
    String? tripDate,
    String? tripTime,
    String? vehicleType,
    String? vehicleNumber,
    int? totalSeats,
    String? preferredGender,
    double? farePerPerson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/company-sharing');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'start_location': startLocation,
        'destination': destination,
        'status': status,
        'trip_date': tripDate,
        'trip_time': tripTime,
        'vehicle_type': vehicleType,
        'vehicle_number': vehicleNumber,
        'total_seats': totalSeats,
        'preferred_gender': preferredGender,
        'fare_per_person': farePerPerson,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create co ride session');
    }
  }

  //ReserveDateSelection.dart
  Future<Map<String, dynamic>> validateReserveSchedule({
    required String pickupLocation,
    required String destinationLocation,
    required double totalDistanceKm,
    required int estimatedTravelMinutes,
    required double estimatedCost,
    required String travelDate,
    required String travelTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/reserve/validate-schedule');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'pickup_location': pickupLocation,
        'destination_location': destinationLocation,
        'total_distance_km': totalDistanceKm,
        'estimated_travel_minutes': estimatedTravelMinutes,
        'estimated_cost': estimatedCost,
        'travel_date': travelDate,
        'travel_time': travelTime,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Reserve schedule validation failed');
    }
  }

  //ReserveRidePreference.dart
  Future<Map<String, dynamic>> validateReservePreferences({
    required String pickupLocation,
    required String destinationLocation,
    required double totalDistanceKm,
    required int estimatedTravelMinutes,
    required double estimatedCost,
    required String travelDate,
    required String travelTime,
    required int selectedSeats,
    String? genderPreference,
    required String vehicleType,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/reserve/validate-preferences');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'pickup_location': pickupLocation,
        'destination_location': destinationLocation,
        'travel_date': travelDate,
        'travel_time': travelTime,
        'total_distance_km': totalDistanceKm,
        'estimated_travel_minutes': estimatedTravelMinutes,
        'estimated_cost': estimatedCost,
        'selected_seats': selectedSeats,
        'gender_preference': genderPreference,
        'vehicle_type': vehicleType,
        'note': note,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Reserve preferences validation failed');
    }
  }


  // CoRideChatListPage.dart
  Future<Map<String, dynamic>> getCoRideChatList() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/company-sharing');

    final response = await http
        .get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load Co Ride chats');
    }
  }

  Future<Map<String, dynamic>> markCoRideChatAsRead({
    required String sessionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/chat/read');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to mark chat as read');
    }
  }

  //CoRideChatRoomPage.dart
  Future<Map<String, dynamic>> getCoRideChatMessages({
    required String sessionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/chat');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load Co Ride chat messages');
    }
  }

  Future<Map<String, dynamic>> sendCoRideChatMessage({
    required String sessionId,
    required String messageText,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/chat');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message_text': messageText,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to send Co Ride message');
    }
  }


  // RideRequestService.dart / Rider Active Ride flow
  Future<Map<String, dynamic>> getRiderActiveRideDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/dashboard');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load active ride dashboard');
    }
  }

  Future<Map<String, dynamic>> acceptPendingRideRequest({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/$requestId/accept');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to accept ride request');
    }
  }

  Future<Map<String, dynamic>> rejectPendingRideRequest({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/$requestId/reject');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to reject ride request');
    }
  }


  Future<Map<String, dynamic>> updateRideAvailability({
    required bool isActive,
    double? latitude,
    double? longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/availability');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'isActive': isActive,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update ride availability');
    }
  }

  Future<Map<String, dynamic>> startAssignedRide({
    required String rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rides/$rideId/start');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to start ride');
    }
  }

  Future<Map<String, dynamic>> completeOngoingRide({
    required String rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/rides/$rideId/complete');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to complete ride');
    }
  }

  // ActiveRidesPage.dart
  Future<Map<String, dynamic>> getCurrentActiveRide() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/active-ride/current');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load current active ride');
    }
  }

  Future<Map<String, dynamic>> cancelCurrentActiveRide() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/active-ride/cancel');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to cancel active ride');
    }
  }

  Future<Map<String, dynamic>> getActiveRideSetupData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/active-ride/setup');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Failed to load active ride setup data',
      );
    }
  }

  Future<Map<String, dynamic>> activateActiveRide({
    required String vehicleId,
    required String destination,
    required double destinationLat,
    required double destinationLng,
    required double currentLat,
    required double currentLng,
    String? currentLocationText,
    String genderPreference = 'any',
    String? note,
    String? travelDate,
    String? travelTime,
    int availableSeats = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/active-ride/activate');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'vehicleId': vehicleId,
        'destination': destination,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'currentLat': currentLat,
        'currentLng': currentLng,
        'currentLocationText': currentLocationText,
        'genderPreference': genderPreference,
        'note': note,
        'travelDate': travelDate,
        'travelTime': travelTime,
        'availableSeats': availableSeats,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to activate ride');
    }
  }

  Future<Map<String, dynamic>> updateActiveRideLocation({
    required double latitude,
    required double longitude,
    String? rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/active-ride/location');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'rideId': rideId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update current location');
    }
  }

  // RideRating.dart
  Future<Map<String, dynamic>> checkRatingStatus({
    required String rideId,
    required String toUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/ratings/check').replace(
      queryParameters: {
        'rideId': rideId,
        'toUserId': toUserId,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to check rating status');
    }
  }

  Future<Map<String, dynamic>> passengerRatesRider({
    required String rideId,
    required int rating,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ratings/passenger-rate-rider');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ride_id': rideId,
        'rating': rating,
        'note': note,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to rate rider');
    }
  }

  Future<Map<String, dynamic>> riderRatesParticipant({
    required String rideId,
    required String participantId,
    required int rating,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ratings/rider-rate-participant');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ride_id': rideId,
        'participant_id': participantId,
        'rating': rating,
        'note': note,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to rate passenger');
    }
  }

  Future<Map<String, dynamic>> fetchRatingSummary({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ratings/summary/$userId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load rating summary');
    }
  }

  // SecurityPage.dart
  Future<Map<String, dynamic>> getSecuritySummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/security');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load security summary');
    }
  }

  Future<Map<String, dynamic>> updateEmergencyContact({
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/security/emergency-contact');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'phone': phone,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update emergency contact');
    }
  }

  Future<Map<String, dynamic>> changeSecurityPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/security/change-password');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to change password');
    }
  }

  // PrivacyDataPage.dart
  Future<Map<String, dynamic>> getPrivacyData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/privacy-data');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load privacy data');
    }
  }

  Future<Map<String, dynamic>> updatePrivacyLocationAccess({
    required String locationAccess,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/privacy-data/location-access');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'locationAccess': locationAccess,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update location access');
    }
  }

  Future<Map<String, dynamic>> updatePrivacyProfileVisibility({
    required String profileVisibility,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/privacy-data/profile-visibility');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'profileVisibility': profileVisibility,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update profile visibility');
    }
  }

  Future<Map<String, dynamic>> updatePrivacyPhonePrivacy({
    required String phonePrivacy,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/privacy-data/phone-privacy');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'phonePrivacy': phonePrivacy,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update phone privacy');
    }
  }

  Future<Map<String, dynamic>> requestPrivacyDataDownload() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/privacy-data/download');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to request data download');
    }
  }

  // NotificationPage.dart
  Future<Map<String, dynamic>> getNotifications({String? role}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/notifications').replace(
      queryParameters: role != null ? {'role': role} : null,
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load notifications');
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead({
    required String notificationId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/notifications/$notificationId/read');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to mark notification as read');
    }
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/notifications/read-all');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Server error: ${response.statusCode}. Check backend deployment.');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to mark all as read');
    }
  }

  Future<Map<String, dynamic>> deleteNotification({
    required String notificationId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/notifications/$notificationId');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to delete notification');
    }
  }

  // MapPickerScreen.dart
  Future<Map<String, dynamic>> mapsAutocomplete({
    required String input,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/maps/autocomplete').replace(
      queryParameters: {
        'input': input,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15)); // টাইমআউট যোগ করা হয়েছে

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        // সার্ভার থেকে আসা এরর মেসেজ পাঠানো
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch results', 'data': []};
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  Future<Map<String, dynamic>> mapsPlaceDetails({
    required String placeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/maps/place-details').replace(
      queryParameters: {
        'placeId': placeId,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch place details');
    }
  }

  Future<Map<String, dynamic>> mapsReverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/maps/reverse-geocode').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to reverse geocode');
    }
  }

  //ReguestingRide.dart
  Future<Map<String, dynamic>> createRideRequestV2({
    required String rideId,
    required String pickupAddress,
    required String destinationAddress,
    required double fare,
    required double distanceKm,
    required int estimatedMinutes,
    String? appliedPromoCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rideId': rideId,
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'fare': fare,
        'distanceKm': distanceKm,
        'estimatedMinutes': estimatedMinutes,
        if (appliedPromoCode != null) 'applied_promo_code': appliedPromoCode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create ride request');
    }
  }

  Future<Map<String, dynamic>> getRideRequestStatus({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/$requestId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load ride request status');
    }
  }

  Future<Map<String, dynamic>> cancelRideRequest({
    required String requestId,
    String? cancelReason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/$requestId/cancel');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'cancelReason': cancelReason,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to cancel ride request');
    }
  }


  Future<Map<String, dynamic>> createRideRequestRealtime({
    required String rideId,
    required String pickupAddress,
    required String destinationAddress,
    required double fare,
    required double distanceKm,
    required int estimatedMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rideId': rideId,
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'fare': fare,
        'distanceKm': distanceKm,
        'estimatedMinutes': estimatedMinutes,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create ride request');
    }
  }

  Future<Map<String, dynamic>> getRideRequestStatusRealtime({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/$requestId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load ride request status');
    }
  }

  Future<Map<String, dynamic>> cancelRideRequestRealtime({
    required String requestId,
    String? cancelReason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/$requestId/cancel');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'cancelReason': cancelReason,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to cancel ride request');
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/profile/image');

    final request = http.MultipartRequest('PATCH', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to upload profile image.');
    }
  }

  //ReserveRideCancel
  Future<Map<String, dynamic>> cancelReserve({
    required String reserveId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/reserve/$reserveId/cancel');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to cancel reserve request');
    }
  }

  Future<Map<String, dynamic>> acceptReserveAsRider({
    required String reserveId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/reserve/$reserveId/accept');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to accept reserve request');
    }
  }
  // CoRide - My Active Session
  Future<Map<String, dynamic>> getMyActiveCoRideSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/company-sharing/my-active');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Failed');
  }

  // CoRide - Get Session Details (for popup)
  Future<Map<String, dynamic>> getCoRideSessionDetails(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/company-sharing/$sessionId');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Failed');
  }

  // CoRide - Book (Join)
  Future<Map<String, dynamic>> bookCoRideSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/join');
    final response = await http.post(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Booking failed');
  }

  // CoRide - Cancel My Session
  Future<Map<String, dynamic>> cancelCoRideSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/cancel');
    final response = await http.patch(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Cancel failed');
  }

  // CoRide - Start Journey
  Future<Map<String, dynamic>> startCoRideJourney(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/start');
    final response = await http.patch(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Start failed');
  }

  // CoRide - Update Live Location
  Future<Map<String, dynamic>> updateCoRideLiveLocation({
    required String sessionId,
    required double lat,
    required double lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/location');
    final response = await http.post(url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'lat': lat, 'lng': lng}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Location update failed');
  }

  // CoRide - Get Live Location
  Future<Map<String, dynamic>> getCoRideLiveLocation(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/location');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Failed');
  }

  // CoRide - Get Session With Participants
  Future<Map<String, dynamic>> getCoRideSessionWithParticipants(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/with-participants');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Failed to load session details');
  }

// CoRide - Remove Participant
  Future<Map<String, dynamic>> removeCoRideParticipant({
    required String sessionId,
    required String participantUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/company-sharing/$sessionId/participants/$participantUserId');
    final response = await http.delete(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Failed to remove participant');
  }

  // ─── SOS APIs ───
  Future<Map<String, dynamic>> triggerCoRideSosHost({
    required String sessionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/sos/coride/host');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'sessionId': sessionId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'SOS failed');
  }

  Future<Map<String, dynamic>> triggerCoRideSosParticipant({
    required String sessionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/sos/coride/participant');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'sessionId': sessionId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'SOS failed');
  }

  Future<Map<String, dynamic>> triggerRiderSos({
    required String rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/sos/rider');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rideId': rideId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'SOS failed');
  }

  Future<Map<String, dynamic>> triggerPassengerSos({
    required String rideId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/sos/passenger');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rideId': rideId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'SOS failed');
  }


  //Alumniiii

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> _get(
      String endpoint, {
        Map<String, String>? queryParams,
      }) async {
    final token = await _getToken();
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data['message'] ?? 'Request failed.');
  }

  Future<Map<String, dynamic>> _post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data['message'] ?? 'Request failed.');
  }

  Future<Map<String, dynamic>> _patch(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    final token = await _getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data['message'] ?? 'Request failed.');
  }

  Future<Map<String, dynamic>> registerAlumni({
    // Degree type
    required String degreeType, // graduation | masters | both
    // Graduation
    String? graduationUniversity,
    String? graduationDepartment,
    String? graduationMajor,
    int? graduationYear,
    // Masters
    String? mastersStatus, // ongoing | completed | not_started
    String? mastersUniversity,
    String? mastersSubject,
    int? mastersCompletionYear,
    // Professional
    required String currentWorkplace,
    required String currentPosition,
    required bool livesAbroad,
    required String country,
    required File alumniCardPhoto,
    required File transcriptPhoto,
    required List<Map<String, dynamic>> works,
    // Legacy fields (backward compat)
    required String department,
    required String majorSubject,
    required int legacyGraduationYear,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/alumni/register');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['degree_type'] = degreeType
      ..fields['department'] = department
      ..fields['major_subject'] = majorSubject
      ..fields['graduation_year'] = graduationYear.toString()
      ..fields['current_workplace'] = currentWorkplace
      ..fields['current_position'] = currentPosition
      ..fields['lives_abroad'] = livesAbroad.toString()
      ..fields['country'] = country
      ..fields['works'] = jsonEncode(works);

    // Optional fields
    if (graduationUniversity != null)
      request.fields['graduation_university'] = graduationUniversity;
    if (graduationDepartment != null)
      request.fields['graduation_department'] = graduationDepartment;
    if (graduationMajor != null)
      request.fields['graduation_major'] = graduationMajor;
    if (graduationYear != null)
      request.fields['graduation_year_actual'] = graduationYear.toString();
    if (mastersStatus != null)
      request.fields['masters_status'] = mastersStatus;
    if (mastersUniversity != null)
      request.fields['masters_university'] = mastersUniversity;
    if (mastersSubject != null)
      request.fields['masters_subject'] = mastersSubject;
    if (mastersCompletionYear != null)
      request.fields['masters_completion_year'] = mastersCompletionYear.toString();

    request.files.add(await http.MultipartFile.fromPath(
      'alumni_card_photo', alumniCardPhoto.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    request.files.add(await http.MultipartFile.fromPath(
      'transcript_photo', transcriptPhoto.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body);

    if (res.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Failed to submit alumni application.');
  }

  Future<Map<String, dynamic>> getAlumniMyStatus() async {
    return await _get('/alumni/my-status');
  }

  Future<Map<String, dynamic>> getAlumniList({
    String? department,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (department != null) 'department': department,
      if (search != null) 'search': search,
    };
    return await _get('/alumni/list', queryParams: params);
  }

  Future<Map<String, dynamic>> getAlumniDepartments() async {
    return await _get('/alumni/departments');
  }

  Future<Map<String, dynamic>> sendAlumniContactRequest({
    required String alumniId,
    String? message,
  }) async {
    return await _post('/alumni/contact-request', {
      'alumni_id': alumniId,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<Map<String, dynamic>> getAlumniRequests() async {
    return await _get('/alumni/requests');
  }

  Future<Map<String, dynamic>> respondAlumniRequest({
    required String requestId,
    required String action, // 'accepted' | 'rejected'
    bool phoneShared = false,
    DateTime? scheduledTime,
  }) async {
    return await _patch('/alumni/requests/$requestId/respond', {
      'action': action,
      'phone_shared': phoneShared,
      if (scheduledTime != null)
        'scheduled_time': scheduledTime.toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getAlumniChatMessages(String sessionId) async {
    return await _get('/alumni/chat/$sessionId/messages');
  }

  Future<Map<String, dynamic>> getMyAlumniChats() async {
    return await _get('/alumni/my-chats');
  }

  Future<Map<String, dynamic>> adminGetPendingAlumni() async {
    return await _get('/alumni/admin/pending');
  }

  Future<Map<String, dynamic>> updateAlumniProfile({
    required String alumniId,
    required String currentWorkplace,
    required String currentPosition,
    required bool livesAbroad,
    required String country,
    required List<Map<String, dynamic>> works,
  }) async {
    return await _patch('/alumni/profile/update', {
      'current_workplace': currentWorkplace,
      'current_position': currentPosition,
      'lives_abroad': livesAbroad,
      'country': country,
      'works': works,
    });
  }

  Future<Map<String, dynamic>> adminReviewAlumni({
    required String alumniId,
    required String action, // 'approved' | 'rejected'
    String? rejectionReason,
  }) async {
    return await _patch('/alumni/admin/$alumniId/review', {
      'action': action,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    });
  }


// ─────────────────────────────────────────────────
// auth_api_service.dart এ এই দুটো method যোগ করো
// ─────────────────────────────────────────────────

  // ── Fare সেটিংস লোড করা ──
  Future<Map<String, dynamic>> getFareSettings() async {
    final token = await _getToken(); // তোমার existing token method
    final response = await http.get(
      Uri.parse('$baseUrl/fare/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to load fare settings.');
  }

  // ── Fare সেটিংস আপডেট করা ──
  Future<Map<String, dynamic>> updateFareSettings(
      Map<String, dynamic> body) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/fare/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to update fare settings.');
  }

  // RiderOffersPage.dart
  Future<Map<String, dynamic>> getRiderOffers() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/rider/offers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load offers');
    }
  }

  // Passenger Offers — UserOffer.dart
  Future<Map<String, dynamic>> getPassengerOffers() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/offers/recent'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load offers');
    }
  }

  //Fare Calculation
  Future<Map<String, dynamic>> getVehicleRates() async {
    final url = Uri.parse('$baseUrl/reserve/vehicle-rates');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load vehicle rates');
    }
  }

  // ActiveRideTrackingPage.dart
  Future<Map<String, dynamic>> getPassengerActiveRideRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/passenger/active');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load active ride request');
    }
  }

  Future<Map<String, dynamic>> getRiderLiveLocationForPassenger({
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/ride-requests/$requestId/rider-location');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load rider location');
    }
  }

  Future<Map<String, dynamic>> getRoutePolyline({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/rider/map/route-polyline').replace(
      queryParameters: {
        'originLat': originLat.toString(),
        'originLng': originLng.toString(),
        'destinationLat': destinationLat.toString(),
        'destinationLng': destinationLng.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to get route');
    }
  }

  Future<Map<String, dynamic>> applyPromoCode({
    required String promoCode,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/offers/apply'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'promo_code': promoCode}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to apply promo code');
    }
  }

  Future<Map<String, dynamic>> saveFcmToken({required String fcmToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/notifications/fcm-token');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to save FCM token');
    }
  }
}