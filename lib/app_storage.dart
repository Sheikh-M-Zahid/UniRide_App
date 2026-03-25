import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userPhotoPathKey = 'user_photo_path';
  static const String userRatingKey = 'user_rating';

  static const String homeKey = 'saved_home';
  static const String campusKey = 'saved_campus';
  static const String hallKey = 'saved_hall';

  static const String isLoggedInKey = 'is_logged_in';
  static const String selectedThemeKey = 'selected_theme';

  static const String rideHistoryKey = 'ride_history';
  static const String reserveHistoryKey = 'reserve_history';

  static const String helpMessageKey = 'help_message';
  static const String reportMessageKey = 'report_message';

  static Future<void> saveLoginSession({
    required String name,
    required String email,
    String? photoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isLoggedInKey, true);
    await prefs.setString(userNameKey, name);
    await prefs.setString(userEmailKey, email);
    await prefs.setDouble(userRatingKey, 5.0);

    if (photoPath != null && photoPath.isNotEmpty) {
      await prefs.setString(userPhotoPathKey, photoPath);
    }
  }

  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userNameKey, name);
    await prefs.setString(userEmailKey, email);
  }

  static Future<void> saveProfilePhoto(String photoPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userPhotoPathKey, photoPath);
  }

  static Future<void> saveSavedPlaces({
    required String home,
    required String campus,
    required String hall,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(homeKey, home);
    await prefs.setString(campusKey, campus);
    await prefs.setString(hallKey, hall);
  }

  static Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedThemeKey, themeName);
  }

  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(selectedThemeKey) ?? 'teal';
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(userNameKey) ?? 'User Name',
      'email': prefs.getString(userEmailKey) ?? 'user@email.com',
      'photoPath': prefs.getString(userPhotoPathKey),
      'rating': prefs.getDouble(userRatingKey) ?? 5.0,
      'home': prefs.getString(homeKey) ?? '',
      'campus': prefs.getString(campusKey) ?? '',
      'hall': prefs.getString(hallKey) ?? '',
      'isLoggedIn': prefs.getBool(isLoggedInKey) ?? false,
    };
  }

  static Future<void> saveRideHistory(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(rideHistoryKey, items);
  }

  static Future<List<String>> getRideHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(rideHistoryKey) ?? [];
  }

  static Future<void> saveReserveHistory(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(reserveHistoryKey, items);
  }

  static Future<List<String>> getReserveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(reserveHistoryKey) ?? [];
  }

  static Future<void> saveHelpMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(helpMessageKey, message);
  }

  static Future<void> saveReportMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(reportMessageKey, message);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(isLoggedInKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(userPhotoPathKey);
    await prefs.remove(userRatingKey);
  }
}