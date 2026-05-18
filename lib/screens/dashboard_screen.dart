import 'package:flutter/material.dart';
import '../core/helpers.dart';
import '../database/local_database.dart';
import '../widgets/stat_card.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/section_box.dart';
import '../widgets/action_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = LocalDatabase.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionBox(
            title: 'لوحة التحكم',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'مرحبًا بك في نسخة Android للدود ماركت',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ActionBar(children: [
                  FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.refresh), label: const Text('تحديث')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.print), label: const Text('طباعة')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download), label: const Text('Excel')),
                ]),
              ],
            ),
          ),
          ResponsiveGrid(
            children: [
              StatCard(title: 'عدد الأصناف', value: '${db.items.length}', icon: Icons.inventory),
              StatCard(title: 'العملاء', value: '${db.customers.length}', icon: Icons.people),
              StatCard(title: 'قيمة المخزون شراء', value: Formatters.money(db.inventoryPurchaseValue), icon: Icons.store),
              StatCard(title: 'ربح متوقع', value: Formatters.money(db.expectedStockProfit), icon: Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }
}
