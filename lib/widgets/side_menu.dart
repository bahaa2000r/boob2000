import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/app_user.dart';

class MenuItemData {
  final String id;
  final String title;
  final IconData icon;

  const MenuItemData(this.id, this.title, this.icon);
}

const appMenuItems = [
  MenuItemData('dashboard', 'الرئيسية', Icons.dashboard),
  MenuItemData('items', 'الأصناف / المخزون', Icons.inventory_2),
  MenuItemData('sales', 'فاتورة مبيعات', Icons.point_of_sale),
  MenuItemData('purchases', 'فاتورة مشتريات', Icons.shopping_cart),
  MenuItemData('customers', 'العملاء', Icons.people),
  MenuItemData('suppliers', 'الموردون', Icons.local_shipping),
  MenuItemData('capital', 'رأس المال', Icons.account_balance_wallet),
  MenuItemData('debts', 'الذمم / كشف الدين', Icons.receipt_long),
  MenuItemData('financial', 'مدفوعات وسحوبات', Icons.payments),
  MenuItemData('bank_audit', 'جرد الحسابات البنكية', Icons.account_balance),
  MenuItemData('notes', 'ملاحظات وتدوينات', Icons.note_alt),
  MenuItemData('sync_center', 'مركز المزامنة', Icons.sync),
  MenuItemData('telegram', 'إعدادات تلجرام', Icons.telegram),
];

class SideMenuPanel extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;
  final bool permanent;
  final AppUser user;

  const SideMenuPanel({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onLogout,
    required this.user,
    this.permanent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: permanent ? 300 : double.infinity,
      color: AppColors.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 1.5),
                color: Colors.black26,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/images/aldood_logo.png',
                      height: 140,
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'سوبر ماركت الدود',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text('${user.displayName} - ${user.role}', style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: appMenuItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = appMenuItems[index];
                    final isSelected = selected == item.id;
                    return InkWell(
                      onTap: () => onSelect(item.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        minHeight: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.bgCard : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.accent : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(item.icon, color: isSelected ? AppColors.accent : AppColors.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.title,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: isSelected ? AppColors.accentHover : AppColors.textDark,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: onLogout,
                  child: const Text('تسجيل خروج'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppEndDrawer extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;
  final AppUser user;

  const AppEndDrawer({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onLogout,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bgDeep,
      child: SideMenuPanel(
        selected: selected,
        onSelect: onSelect,
        onLogout: onLogout,
        user: user,
      ),
    );
  }
}
