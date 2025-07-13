import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _defaultBaseUrl = "https://937279d75870.ngrok-free.app";
  static const String _key = "baseUrl";

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? _defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }

  static Future<String> getSupportUsersUrl() async =>
      "${await getBaseUrl()}/support-users";

  static Future<String> getSupportMessagesUrl(String userId) async =>
      "${await getBaseUrl()}/support-messages?user_id=$userId";

  static Future<String> getAdminReplyUrl() async =>
      "${await getBaseUrl()}/admin-reply";
}