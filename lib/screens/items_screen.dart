import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../database/local_database.dart';
import '../widgets/action_bar.dart';
import '../widgets/section_box.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '0');
  final purchaseController = TextEditingController(text: '0');
  final wholesaleController = TextEditingController(text: '0');
  final retailController = TextEditingController(text: '0');
  final locationController = TextEditingController();
  final searchController = TextEditingController();

  Future<void> _add() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    await LocalDatabase.instance.addItem(
      name: name,
      quantity: double.tryParse(qtyController.text) ?? 0,
      purchasePrice: double.tryParse(purchaseController.text) ?? 0,
      wholesalePrice: double.tryParse(wholesaleController.text) ?? 0,
      retailPrice: double.tryParse(retailController.text) ?? 0,
      location: locationController.text.trim(),
    );
    nameController.clear();
    qtyController.text = '0';
    purchaseController.text = '0';
    wholesaleController.text = '0';
    retailController.text = '0';
    locationController.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filter = searchController.text.trim();
    final items = LocalDatabase.instance.items.where((i) => filter.isEmpty || i.name.contains(filter)).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionBox(
            title: 'بيانات الصنف',
            child: Column(
              children: [
                TextField(controller: nameController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'اسم الصنف')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: qtyController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الكمية'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: purchaseController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'سعر الشراء'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: wholesaleController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'سعر البيع جملة'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: retailController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'سعر البيع مفرق'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: locationController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'مكان المخزون')),
                const SizedBox(height: 12),
                ActionBar(
                  children: [
                    FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('إضافة وحفظ')),
                    OutlinedButton.icon(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh), label: const Text('تحديث')),
                  ],
                ),
              ],
            ),
          ),
          SectionBox(
            title: 'جدول الأصناف',
            child: Column(
              children: [
                ActionBar(children: [
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.upload_file), label: const Text('استقبال Excel')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download), label: const Text('تصدير Excel')),
                ]),
                const SizedBox(height: 10),
                TextField(controller: searchController, onChanged: (_) => setState(() {}), textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'بحث')),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.bgCard),
                    columns: const [
                      DataColumn(label: Text('الرقم')),
                      DataColumn(label: Text('الصنف')),
                      DataColumn(label: Text('الكمية')),
                      DataColumn(label: Text('شراء')),
                      DataColumn(label: Text('جملة')),
                      DataColumn(label: Text('مفرق')),
                      DataColumn(label: Text('المخزن')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(cells: [
                          DataCell(Text('${item.id}')),
                          DataCell(Text(item.name)),
                          DataCell(Text('${item.quantity}')),
                          DataCell(Text('${item.purchasePrice}')),
                          DataCell(Text('${item.wholesalePrice}')),
                          DataCell(Text('${item.retailPrice}')),
                          DataCell(Text(item.storagePlace)),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
