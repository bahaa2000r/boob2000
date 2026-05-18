import '../models/app_user.dart';

class AuthService {
  static const Map<String, Map<String, String>> _users = {
    'abd': {'password': '123', 'displayName': 'عبد الله', 'role': 'مدير النظام'},
    'm': {'password': '123', 'displayName': 'محاسب', 'role': 'محاسب'},
    'd': {'password': '123', 'displayName': 'مدخل بيانات', 'role': 'موظف إدخال'},
    's': {'password': '123', 'displayName': 'كاشير', 'role': 'كاشير'},
  };

  static AppUser? login(String username, String password) {
    final cleanUsername = username.trim();
    final user = _users[cleanUsername];
    if (user == null) return null;
    if (user['password'] != password) return null;

    return AppUser(
      username: cleanUsername,
      displayName: user['displayName']!,
      role: user['role']!,
    );
  }
}
