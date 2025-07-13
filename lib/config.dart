import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String _baseUrl = "https://937279d75870.ngrok-free.app/admin";

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', url);
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? _baseUrl;
  }

  static Future<String> get supportUsersUrl async =>
      "${await getBaseUrl()}/support-users";

  static Future<String> supportMessagesUrl(String userId) async =>
      "${await getBaseUrl()}/support-messages?user_id=$userId";

  static Future<String> get adminReplyUrl async =>
      "${await getBaseUrl()}/admin-reply";
}
