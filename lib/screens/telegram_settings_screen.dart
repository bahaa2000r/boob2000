import 'package:flutter/material.dart';
import '../services/telegram_service.dart';
import '../widgets/section_box.dart';
import '../widgets/action_bar.dart';

class TelegramSettingsScreen extends StatefulWidget {
  const TelegramSettingsScreen({super.key});

  @override
  State<TelegramSettingsScreen> createState() => _TelegramSettingsScreenState();
}

class _TelegramSettingsScreenState extends State<TelegramSettingsScreen> {
  final notifyTokenController = TextEditingController();
  final notifyChatIdController = TextEditingController();
  final commandTokenController = TextEditingController();
  final commandChatIdController = TextEditingController();

  bool notifyEnabled = false;
  bool commandEnabled = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await TelegramService.loadSettings();
    notifyTokenController.text = settings.notificationBot.botToken;
    notifyChatIdController.text = settings.notificationBot.chatId;
    notifyEnabled = settings.notificationBot.enabled;
    commandTokenController.text = settings.commandBot.botToken;
    commandChatIdController.text = settings.commandBot.chatId;
    commandEnabled = settings.commandBot.enabled;
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    await TelegramService.saveSettings(
      notificationBotToken: notifyTokenController.text,
      notificationChatId: notifyChatIdController.text,
      notificationEnabled: notifyEnabled,
      commandBotToken: commandTokenController.text,
      commandChatId: commandChatIdController.text,
      commandEnabled: commandEnabled,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ إعدادات بوتات تلجرام')),
    );
  }

  Future<void> _testNotificationBot() async {
    await _save();
    final result = await TelegramService.sendNotification(
      '✅ اختبار بوت الإشعارات\nالدود ماركت متصل بنجاح.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  Future<void> _testCommandBot() async {
    await _save();
    final result = await TelegramService.sendCommandBotMessage(
      '✅ اختبار بوت الأوامر\nجاهز للأوامر والتقارير في المرحلة القادمة.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  Widget _botBox({
    required String title,
    required String description,
    required TextEditingController tokenController,
    required TextEditingController chatController,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required VoidCallback onTest,
  }) {
    return SectionBox(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(description, textAlign: TextAlign.right),
          const SizedBox(height: 12),
          TextField(
            controller: tokenController,
            obscureText: true,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(labelText: 'Bot Token'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: chatController,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(labelText: 'Chat ID'),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: enabled,
            onChanged: onEnabledChanged,
            title: const Text('تفعيل هذا البوت', textAlign: TextAlign.right),
          ),
          const SizedBox(height: 12),
          ActionBar(children: [
            FilledButton.icon(onPressed: onTest, icon: const Icon(Icons.send), label: const Text('تجربة الإرسال')),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _botBox(
            title: 'Bot 1 - بوت الإشعارات',
            description: 'يستخدم لإشعارات تسجيل الدخول، الفواتير، تسديد الديون، المزامنة، ورأس المال.',
            tokenController: notifyTokenController,
            chatController: notifyChatIdController,
            enabled: notifyEnabled,
            onEnabledChanged: (v) => setState(() => notifyEnabled = v),
            onTest: _testNotificationBot,
          ),
          _botBox(
            title: 'Bot 2 - بوت الأوامر والتقارير',
            description: 'مخصص للأوامر والتقارير مثل /capital و /stock و /debts و /sync_status في المرحلة القادمة.',
            tokenController: commandTokenController,
            chatController: commandChatIdController,
            enabled: commandEnabled,
            onEnabledChanged: (v) => setState(() => commandEnabled = v),
            onTest: _testCommandBot,
          ),
          ActionBar(children: [
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('حفظ إعدادات البوتين')),
            OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تحديث')),
          ]),
          const SizedBox(height: 12),
          const Text(
            'لا يتم وضع التوكن داخل الكود. يتم حفظ الإعدادات داخل التطبيق. أي إرسال تلقائي حاليًا يستخدم بوت الإشعارات، أما بوت الأوامر فهو جاهز للإعداد والتجربة وسيتم ربط استقبال الأوامر لاحقًا.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
