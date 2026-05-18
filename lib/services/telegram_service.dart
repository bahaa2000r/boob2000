import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TelegramBotConfig {
  final String botToken;
  final String chatId;
  final bool enabled;

  const TelegramBotConfig({
    required this.botToken,
    required this.chatId,
    required this.enabled,
  });

  bool get isConfigured => botToken.trim().isNotEmpty && chatId.trim().isNotEmpty;
}

class TelegramSettings {
  final TelegramBotConfig notificationBot;
  final TelegramBotConfig commandBot;

  const TelegramSettings({
    required this.notificationBot,
    required this.commandBot,
  });
}

class TelegramService {
  // Bot 1: إشعارات فقط
  static const _notifyTokenKey = 'telegram_notify_bot_token';
  static const _notifyChatIdKey = 'telegram_notify_chat_id';
  static const _notifyEnabledKey = 'telegram_notify_enabled';

  // Bot 2: أوامر وتقارير
  static const _commandTokenKey = 'telegram_command_bot_token';
  static const _commandChatIdKey = 'telegram_command_chat_id';
  static const _commandEnabledKey = 'telegram_command_enabled';

  // مفاتيح قديمة من النسخة السابقة لدعم الترقية بدون ضياع الإعدادات.
  static const _oldTokenKey = 'telegram_bot_token';
  static const _oldChatIdKey = 'telegram_chat_id';
  static const _oldEnabledKey = 'telegram_enabled';

  static Future<TelegramSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final oldToken = prefs.getString(_oldTokenKey) ?? '';
    final oldChat = prefs.getString(_oldChatIdKey) ?? '';
    final oldEnabled = prefs.getBool(_oldEnabledKey) ?? false;

    return TelegramSettings(
      notificationBot: TelegramBotConfig(
        botToken: prefs.getString(_notifyTokenKey) ?? oldToken,
        chatId: prefs.getString(_notifyChatIdKey) ?? oldChat,
        enabled: prefs.getBool(_notifyEnabledKey) ?? oldEnabled,
      ),
      commandBot: TelegramBotConfig(
        botToken: prefs.getString(_commandTokenKey) ?? '',
        chatId: prefs.getString(_commandChatIdKey) ?? '',
        enabled: prefs.getBool(_commandEnabledKey) ?? false,
      ),
    );
  }

  static Future<void> saveSettings({
    required String notificationBotToken,
    required String notificationChatId,
    required bool notificationEnabled,
    required String commandBotToken,
    required String commandChatId,
    required bool commandEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notifyTokenKey, notificationBotToken.trim());
    await prefs.setString(_notifyChatIdKey, notificationChatId.trim());
    await prefs.setBool(_notifyEnabledKey, notificationEnabled);
    await prefs.setString(_commandTokenKey, commandBotToken.trim());
    await prefs.setString(_commandChatIdKey, commandChatId.trim());
    await prefs.setBool(_commandEnabledKey, commandEnabled);
  }

  static Future<String> sendNotification(String message) async {
    final settings = await loadSettings();
    return _sendWithConfig(settings.notificationBot, message, 'بوت الإشعارات');
  }

  static Future<String> sendCommandBotMessage(String message) async {
    final settings = await loadSettings();
    return _sendWithConfig(settings.commandBot, message, 'بوت الأوامر');
  }

  // توافق مع كود النسخة السابقة: أي sendMessage يرسل عبر بوت الإشعارات.
  static Future<String> sendMessage(String message) => sendNotification(message);

  static Future<String> _sendWithConfig(TelegramBotConfig config, String message, String label) async {
    if (!config.enabled) {
      return '$label غير مفعل.';
    }

    if (!config.isConfigured) {
      return 'أدخل Bot Token و Chat ID لـ $label أولًا.';
    }

    final uri = Uri.parse('https://api.telegram.org/bot${config.botToken}/sendMessage');

    try {
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': config.chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return 'تم الإرسال عبر $label بنجاح.';
      }

      return 'فشل الإرسال عبر $label: ${response.statusCode} - ${response.body}';
    } catch (e) {
      return 'تعذر الاتصال بـ $label: $e';
    }
  }
}
