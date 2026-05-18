import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../database/local_database.dart';
import '../models/item_model.dart';
import '../models/person_model.dart';
import '../services/telegram_service.dart';
import '../widgets/smart_item_search.dart';
import '../widgets/section_box.dart';
import '../widgets/action_bar.dart';

enum InvoiceType { sales, purchases }

class InvoiceScreen extends StatefulWidget {
  final InvoiceType type;
  const InvoiceScreen({super.key, required this.type});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  ItemModel? selectedItem;
  int? selectedPartyId;
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController(text: '0');
  final paidController = TextEditingController(text: '0');
  final notesController = TextEditingController();
  final List<Map<String, dynamic>> rows = [];

  bool get isSales => widget.type == InvoiceType.sales;
  List<PersonModel> get parties => isSales ? LocalDatabase.instance.customers : LocalDatabase.instance.suppliers;

  void addRow() {
    if (selectedItem == null) return;
    final qty = double.tryParse(qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    if (qty <= 0 || price < 0) return;
    setState(() {
      rows.add({'item': selectedItem!, 'qty': qty, 'price': price});
    });
  }

  Future<void> saveInvoice() async {
    try {
      final paid = double.tryParse(paidController.text) ?? 0;
      final id = await LocalDatabase.instance.createInvoice(
        isSales: isSales,
        rows: rows,
        partyId: selectedPartyId,
        paidAmount: paid,
        paymentMethod: 'كاش',
        notes: notesController.text.trim(),
      );
      await TelegramService.sendMessage(
        '🧾 ${isSales ? 'فاتورة مبيعات من الهاتف' : 'فاتورة مشتريات من الهاتف'}\n'
        'رقم داخلي: $id\n'
        'الإجمالي: $total\n'
        'المدفوع: $paid\n'
        'المتبقي: ${total - paid}',
      );
      if (!mounted) return;
      setState(() {
        rows.clear();
        paidController.text = '0';
        notesController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة محليًا وإضافتها للمزامنة')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  double get total => rows.fold(0, (s, r) => s + (r['qty'] as double) * (r['price'] as double));

  @override
  Widget build(BuildContext context) {
    final remaining = total - (double.tryParse(paidController.text) ?? 0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionBox(
            title: isSales ? 'إدخال فاتورة مبيعات' : 'إدخال فاتورة مشتريات',
            child: Column(
              children: [
                DropdownButtonFormField<int?>(
                  value: selectedPartyId,
                  decoration: InputDecoration(labelText: isSales ? 'العميل' : 'المورد'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('بدون تحديد')),
                    for (final p in parties) DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() => selectedPartyId = v),
                ),
                const SizedBox(height: 10),
                SmartItemSearch(
                  onSelected: (item) {
                    setState(() {
                      selectedItem = item;
                      priceController.text = isSales ? '${item.retailPrice}' : '${item.purchasePrice}';
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: qtyController, keyboardType: TextInputType.number, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الكمية'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: priceController, keyboardType: TextInputType.number, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'السعر'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: paidController, keyboardType: TextInputType.number, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'المدفوع'), onChanged: (_) => setState(() {}))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(readOnly: true, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'المتبقي', hintText: remaining.toStringAsFixed(2)))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: notesController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'ملاحظات')),
                const SizedBox(height: 12),
                ActionBar(children: [
                  FilledButton.icon(onPressed: addRow, icon: const Icon(Icons.add), label: const Text('إضافة السطر')),
                  OutlinedButton.icon(onPressed: saveInvoice, icon: const Icon(Icons.save), label: const Text('حفظ الفاتورة')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.print), label: const Text('طباعة')),
                ]),
              ],
            ),
          ),
          SectionBox(
            title: 'جدول الفاتورة',
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.bgCard),
                    columns: const [
                      DataColumn(label: Text('الصنف')),
                      DataColumn(label: Text('الكمية')),
                      DataColumn(label: Text('السعر')),
                      DataColumn(label: Text('الإجمالي')),
                    ],
                    rows: [
                      for (final r in rows)
                        DataRow(cells: [
                          DataCell(Text((r['item'] as ItemModel).name)),
                          DataCell(Text('${r['qty']}')),
                          DataCell(Text('${r['price']}')),
                          DataCell(Text('${(r['qty'] as double) * (r['price'] as double)}')),
                        ]),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.bgCard, border: Border.all(color: AppColors.accent)),
                  child: Text('الإجمالي: ${total.toStringAsFixed(2)} | المتبقي: ${remaining.toStringAsFixed(2)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
