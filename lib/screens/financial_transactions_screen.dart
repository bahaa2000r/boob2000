import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../database/local_database.dart';
import '../widgets/action_bar.dart';
import '../widgets/section_box.dart';

class FinancialTransactionsScreen extends StatefulWidget {
  const FinancialTransactionsScreen({super.key});

  @override
  State<FinancialTransactionsScreen> createState() => _FinancialTransactionsScreenState();
}

class _FinancialTransactionsScreenState extends State<FinancialTransactionsScreen> {
  String type = 'مدفوعة مالية';
  final amountController = TextEditingController();
  final categoryController = TextEditingController(text: 'عام');
  final executorController = TextEditingController(text: 'mobile');
  final notesController = TextEditingController();

  Future<void> _save() async {
    try {
      final amount = double.tryParse(amountController.text) ?? 0;
      if (type == 'مدفوعة مالية') {
        await LocalDatabase.instance.addFinancialPayment(amount: amount, category: categoryController.text, executor: executorController.text, notes: notesController.text);
      } else {
        await LocalDatabase.instance.addFinancialWithdrawal(amount: amount, category: categoryController.text, executor: executorController.text, notes: notesController.text);
      }
      amountController.clear();
      notesController.clear();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ محليًا وسيتم تضمينه في المزامنة')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionBox(
            title: 'مدفوعات وسحوبات مالية',
            child: Column(children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'نوع العملية'),
                items: const [
                  DropdownMenuItem(value: 'مدفوعة مالية', child: Text('مدفوعة مالية / داخل')),
                  DropdownMenuItem(value: 'سحبة مالية', child: Text('سحبة مالية / خارج')),
                ],
                onChanged: (v) => setState(() => type = v ?? type),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: amountController, keyboardType: TextInputType.number, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'المبلغ'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: categoryController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'التصنيف'))),
              ]),
              const SizedBox(height: 10),
              TextField(controller: executorController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'المنفذ')),
              const SizedBox(height: 10),
              TextField(controller: notesController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'ملاحظات')),
              const SizedBox(height: 12),
              ActionBar(children: [FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('حفظ العملية'))]),
            ]),
          ),
          SectionBox(
            title: 'كشف الحركات المالية',
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: LocalDatabase.instance.financialRows(),
              builder: (context, snap) {
                final rows = snap.data ?? [];
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.bgCard),
                    columns: const [
                      DataColumn(label: Text('النوع')),
                      DataColumn(label: Text('المبلغ')),
                      DataColumn(label: Text('التصنيف')),
                      DataColumn(label: Text('المنفذ')),
                      DataColumn(label: Text('التاريخ')),
                      DataColumn(label: Text('ملاحظات')),
                    ],
                    rows: [
                      for (final r in rows)
                        DataRow(cells: [
                          DataCell(Text('${r['kind']}')),
                          DataCell(Text('${r['amount']}')),
                          DataCell(Text('${r['category']}')),
                          DataCell(Text('${r['executor']}')),
                          DataCell(Text('${r['tx_date']}')),
                          DataCell(Text('${r['notes']}')),
                        ]),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
