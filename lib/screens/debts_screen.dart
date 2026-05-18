import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../database/local_database.dart';
import '../models/person_model.dart';
import '../widgets/action_bar.dart';
import '../widgets/section_box.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  int? selectedCustomerId;
  final amountController = TextEditingController();
  final methodController = TextEditingController(text: 'نقدي');
  final notesController = TextEditingController();
  bool loading = false;

  List<PersonModel> get customers => LocalDatabase.instance.customers;

  Future<void> _addDebt() async => _run(() => LocalDatabase.instance.addCustomerDebt(
        customerId: selectedCustomerId!,
        amount: double.tryParse(amountController.text) ?? 0,
        notes: notesController.text.trim(),
      ), 'تم إضافة الدين');

  Future<void> _payDebt() async => _run(() => LocalDatabase.instance.payCustomerDebt(
        customerId: selectedCustomerId!,
        amount: double.tryParse(amountController.text) ?? 0,
        paymentMethod: methodController.text.trim(),
        notes: notesController.text.trim(),
      ), 'تم تسجيل التسديد');

  Future<void> _run(Future<void> Function() action, String msg) async {
    if (selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر العميل أولًا')));
      return;
    }
    setState(() => loading = true);
    try {
      await action();
      amountController.clear();
      notesController.clear();
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$msg وستظهر في المزامنة')));
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _payInvoice(Map<String, dynamic> row) async {
    final controller = TextEditingController(text: '${row['remaining'] ?? 0}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسديد دين فاتورة'),
          content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ التسديد')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تسديد')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await LocalDatabase.instance.payInvoiceDebt(
        isSales: '${row['kind']}'.contains('عميل'),
        invoiceId: (row['ref_id'] as num).toInt(),
        amount: double.tryParse(controller.text) ?? 0,
        notes: 'تسديد من شاشة الذمم في الهاتف',
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التسديد وسيظهر في المزامنة')));
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
            title: 'إضافة دين / تسديد دين عميل',
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: selectedCustomerId,
                  decoration: const InputDecoration(labelText: 'العميل'),
                  items: [for (final c in customers) DropdownMenuItem(value: c.id, child: Text(c.name))],
                  onChanged: (v) => setState(() => selectedCustomerId = v),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: amountController, keyboardType: TextInputType.number, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'المبلغ'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: methodController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'طريقة الدفع'))),
                ]),
                const SizedBox(height: 10),
                TextField(controller: notesController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'ملاحظات')),
                const SizedBox(height: 12),
                ActionBar(children: [
                  FilledButton.icon(onPressed: loading ? null : _addDebt, icon: const Icon(Icons.add), label: const Text('إضافة دين')),
                  OutlinedButton.icon(onPressed: loading ? null : _payDebt, icon: const Icon(Icons.payments), label: const Text('تسديد دين')),
                ]),
              ],
            ),
          ),
          SectionBox(
            title: 'كشف الدين',
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: LocalDatabase.instance.debtRows(),
              builder: (context, snap) {
                final rows = snap.data ?? [];
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.bgCard),
                    columns: const [
                      DataColumn(label: Text('النوع')),
                      DataColumn(label: Text('الجهة')),
                      DataColumn(label: Text('المرجع')),
                      DataColumn(label: Text('التاريخ')),
                      DataColumn(label: Text('الأصل')),
                      DataColumn(label: Text('المدفوع')),
                      DataColumn(label: Text('المتبقي')),
                      DataColumn(label: Text('تسديد')),
                    ],
                    rows: [
                      for (final r in rows)
                        DataRow(cells: [
                          DataCell(Text('${r['kind']}')),
                          DataCell(Text('${r['party']}')),
                          DataCell(Text('${r['ref_no']}')),
                          DataCell(Text('${r['tx_date']}')),
                          DataCell(Text('${(r['total'] as num?)?.toDouble().toStringAsFixed(2) ?? '0'}')),
                          DataCell(Text('${(r['paid'] as num?)?.toDouble().toStringAsFixed(2) ?? '0'}')),
                          DataCell(Text('${(r['remaining'] as num?)?.toDouble().toStringAsFixed(2) ?? '0'}')),
                          DataCell('${r['kind']}'.contains('فاتورة') ? TextButton(onPressed: () => _payInvoice(r), child: const Text('تسديد')) : const Text('-')),
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
