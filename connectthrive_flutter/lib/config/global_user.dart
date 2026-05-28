import 'package:shared_preferences/shared_preferences.dart';

class GlobalUser {
  static String username = '';
  static String mobileNumber = '';
  static int userId = 0;
  static int batchId = 2;

  static void setGlobalUser({
    required String username,
    required String mobileNumber,
    int userId = 0,
    int batchId = 2,
  }) {
    GlobalUser.username = username;
    GlobalUser.mobileNumber = mobileNumber;
    GlobalUser.userId = userId;
    GlobalUser.batchId = batchId;
  }

  static Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('mobileNumber', mobileNumber);
    await prefs.setInt('userId', userId);
    await prefs.setInt('batchId', batchId);
  }

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    mobileNumber = prefs.getString('mobileNumber') ?? '';
    userId = prefs.getInt('userId') ?? 0;
    batchId = prefs.getInt('batchId') ?? 2;
  }

  static bool get isLoggedIn => mobileNumber.isNotEmpty;

  static Future<void> clear() async {
    username = '';
    mobileNumber = '';
    userId = 0;
    batchId = 2;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
