import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _lastLoginKey = 'last_login_time';
  static const String _lastOpenKey = 'last_open_time';

  static const int _autoLogoutDays = 30;

  /// Login success হলে token save করবে
  static Future<void> saveLoginSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_lastLoginKey, now);
    await prefs.setInt(_lastOpenKey, now);
  }

  /// App open হলেই এটা call করবে
  /// এতে last open time update হবে
  static Future<void> updateLastOpenTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastOpenKey, now);
  }

  /// User login আছে কিনা check করবে
  /// 30 দিনের বেশি app-এ না ঢুকলে auto logout
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);
    final lastOpenTime = prefs.getInt(_lastOpenKey);

    if (token == null || token.isEmpty) {
      return false;
    }

    if (lastOpenTime == null) {
      await clearSession();
      return false;
    }

    final lastOpenDate = DateTime.fromMillisecondsSinceEpoch(lastOpenTime);
    final now = DateTime.now();
    final difference = now.difference(lastOpenDate).inDays;

    if (difference >= _autoLogoutDays) {
      await clearSession();
      return false;
    }

    await updateLastOpenTime();
    return true;
  }

  /// saved token লাগলে এটা use করতে পারো
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Manual logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_lastLoginKey);
    await prefs.remove(_lastOpenKey);
  }
}