import 'package:flutter/material.dart';
import '../core/helpers.dart';
import '../database/local_database.dart';
import '../widgets/stat_card.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/section_box.dart';
import '../widgets/action_bar.dart';

class CapitalScreen extends StatelessWidget {
  const CapitalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = LocalDatabase.instance;
    const openingCapital = 0.0;
    const cashNet = 0.0;
    final realCapital = openingCapital + cashNet + db.inventoryPurchaseValue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionBox(
            title: 'الفلترة والتحكم برأس المال',
            child: ActionBar(children: [
              FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('إضافة تسوية')),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.flag), label: const Text('حفظ الافتتاحي')),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.today), label: const Text('اليوم')),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.date_range), label: const Text('هذا الشهر')),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download), label: const Text('Excel')),
            ]),
          ),
          ResponsiveGrid(
            children: [
              StatCard(title: 'رأس المال الافتتاحي', value: Formatters.money(openingCapital), icon: Icons.flag),
              StatCard(title: 'صافي الحركة النقدية', value: Formatters.money(cashNet), icon: Icons.payments),
              StatCard(title: 'قيمة المخزون شراء', value: Formatters.money(db.inventoryPurchaseValue), icon: Icons.inventory),
              StatCard(title: 'قيمة المخزون جملة', value: Formatters.money(db.inventoryWholesaleValue), icon: Icons.store),
              StatCard(title: 'ربح متوقع بالمخزون', value: Formatters.money(db.expectedStockProfit), icon: Icons.trending_up),
              StatCard(title: 'رأس المال الحقيقي', value: Formatters.money(realCapital), icon: Icons.account_balance_wallet),
            ],
          ),
        ],
      ),
    );
  }
}
