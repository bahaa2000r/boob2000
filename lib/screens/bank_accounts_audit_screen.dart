import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../database/local_database.dart';
import '../widgets/section_box.dart';
import '../widgets/action_bar.dart';

class BankAccountsAuditScreen extends StatefulWidget {
  const BankAccountsAuditScreen({super.key});

  @override
  State<BankAccountsAuditScreen> createState() => _BankAccountsAuditScreenState();
}

class _BankAccountsAuditScreenState extends State<BankAccountsAuditScreen> {
  final nameController = TextEditingController();
  final accountController = TextEditingController(text: 'بنك فلسطين');
  final typeController = TextEditingController(text: 'بيع يومي');
  final originalController = TextEditingController(text: '0');
  final transferredController = TextEditingController(text: '0');
  final notesController = TextEditingController();

  Future<void> _add() async {
    if (nameController.text.trim().isEmpty) return;
    await LocalDatabase.instance.addBankOperation(
      name: nameController.text.trim(),
      account: accountController.text.trim(),
      type: typeController.text.trim(),
      original: double.tryParse(originalController.text) ?? 0,
      transferred: double.tryParse(transferredController.text) ?? 0,
      notes: notesController.text.trim(),
    );
    nameController.clear();
    originalController.text = '0';
    transferredController.text = '0';
    notesController.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ops = LocalDatabase.instance.bankOperations;
    final totalOriginal = ops.fold<double>(0, (s, o) => s + o.originalAmount);
    final totalTransferred = ops.fold<double>(0, (s, o) => s + o.transferredAmount);
    final totalRemaining = ops.fold<double>(0, (s, o) => s + o.remaining);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionBox(
            title: 'إضافة عملية جرد بنكي',
            child: Column(
              children: [
                TextField(controller: nameController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الاسم')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: accountController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الحساب / البنك'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: typeController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'نوع العملية'))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: originalController, keyboardType: TextInputType.number, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الأصل'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: transferredController, keyboardType: TextInputType.number, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'المحول'))),
                ]),
                const SizedBox(height: 10),
                TextField(controller: notesController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'ملاحظات')),
                const SizedBox(height: 12),
                ActionBar(children: [
                  FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('إضافة وحفظ')),
                  OutlinedButton.icon(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh), label: const Text('تحديث')),
                ]),
              ],
            ),
          ),
          SectionBox(
            title: 'التحكم بجرد الحسابات البنكية',
            child: Column(
              children: [
                ActionBar(children: [
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.table_view), label: const Text('فتح جدول جميع العمليات')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.today), label: const Text('اليوم')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.view_week), label: const Text('الأسبوع')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_month), label: const Text('الشهر')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download), label: const Text('تصدير Excel')),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.bgCard, border: Border.all(color: AppColors.accent)),
                  child: Text(
                    'الأصل: $totalOriginal | المحول: $totalTransferred | المتبقي: $totalRemaining',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SectionBox(
            title: 'جدول العمليات',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.bgCard),
                columns: const [
                  DataColumn(label: Text('الاسم')),
                  DataColumn(label: Text('الحساب')),
                  DataColumn(label: Text('النوع')),
                  DataColumn(label: Text('الأصل')),
                  DataColumn(label: Text('المحول')),
                  DataColumn(label: Text('المتبقي')),
                  DataColumn(label: Text('الحالة')),
                  DataColumn(label: Text('ملاحظات')),
                ],
                rows: [
                  for (final o in ops)
                    DataRow(cells: [
                      DataCell(Text(o.name)),
                      DataCell(Text(o.account)),
                      DataCell(Text(o.type)),
                      DataCell(Text('${o.originalAmount}')),
                      DataCell(Text('${o.transferredAmount}')),
                      DataCell(Text('${o.remaining}')),
                      DataCell(Text(o.status)),
                      DataCell(Text(o.notes)),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
