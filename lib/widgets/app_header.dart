import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../models/app_user.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final String title;
  final bool showMenuButton;
  final AppUser user;

  const AppHeader({
    super.key,
    required this.onMenuPressed,
    required this.title,
    required this.user,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 650;

    return Container(
      height: compact ? 104 : 112,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.accent, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu, color: AppColors.accent, size: 30),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: compact ? 20 : 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'المستخدم: ${user.displayName} | الصلاحية: ${user.role}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('التاريخ والوقت', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(Formatters.now(), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
