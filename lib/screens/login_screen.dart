import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/telegram_service.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<AppUser> onLoggedIn;

  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool loading = false;

  Future<void> _login() async {
    final user = AuthService.login(usernameController.text, passwordController.text);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم المستخدم أو كلمة السر غير صحيحة')),
      );
      return;
    }

    setState(() => loading = true);

    await TelegramService.sendMessage(
      '✅ تسجيل دخول جديد\n'
      'المستخدم: ${user.displayName}\n'
      'الصلاحية: ${user.role}\n'
      'الحساب: ${user.username}',
    );

    if (!mounted) return;
    setState(() => loading = false);
    widget.onLoggedIn(user);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Row(
                  children: [
                    if (wide)
                      Expanded(
                        child: Container(
                          height: 520,
                          decoration: BoxDecoration(
                            color: AppColors.bgDeep,
                            border: Border.all(color: AppColors.accent, width: 1.5),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/aldood_logo.png',
                              width: 420,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    if (wide) const SizedBox(width: 18),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          border: Border.all(color: AppColors.accent, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!wide)
                              Image.asset(
                                'assets/images/aldood_logo.png',
                                height: 170,
                                fit: BoxFit.contain,
                              ),
                            const SizedBox(height: 16),
                            const Text(
                              'تسجيل الدخول',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'الدود ماركت',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: usernameController,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                labelText: 'اسم المستخدم',
                                prefixIcon: Icon(Icons.person),
                              ),
                              onSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: obscure,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'كلمة السر',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => obscure = !obscure),
                                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                                ),
                              ),
                              onSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: loading ? null : _login,
                              icon: loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.login),
                              label: const Text('دخول'),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                border: Border.all(color: AppColors.gold),
                              ),
                              child: const Text(
                                'الحسابات:\nabd / 123\nm / 123\nd / 123\ns / 123',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
