import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../database/local_database.dart';
import '../models/person_model.dart';
import '../widgets/action_bar.dart';
import '../widgets/section_box.dart';

enum PeopleKind { customers, suppliers }

class PeopleScreen extends StatefulWidget {
  final PeopleKind kind;
  const PeopleScreen({super.key, required this.kind});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();

  Future<void> _add() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    await LocalDatabase.instance.addPerson(
      widget.kind == PeopleKind.customers ? 'customers' : 'suppliers',
      name: name,
      phone: phoneController.text.trim(),
      notes: notesController.text.trim(),
    );
    nameController.clear();
    phoneController.clear();
    notesController.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<PersonModel> data = widget.kind == PeopleKind.customers
        ? LocalDatabase.instance.customers
        : LocalDatabase.instance.suppliers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionBox(
            title: widget.kind == PeopleKind.customers ? 'بيانات العميل' : 'بيانات المورد',
            child: Column(
              children: [
                TextField(controller: nameController, textAlign: TextAlign.right, decoration: InputDecoration(labelText: widget.kind == PeopleKind.customers ? 'اسم العميل' : 'اسم المورد')),
                const SizedBox(height: 10),
                TextField(controller: phoneController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الجوال')),
                const SizedBox(height: 10),
                TextField(controller: notesController, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'ملاحظات')),
                const SizedBox(height: 12),
                ActionBar(children: [
                  FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('إضافة وحفظ')),
                  OutlinedButton.icon(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh), label: const Text('تحديث')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.upload_file), label: const Text('استقبال Excel')),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download), label: const Text('تصدير Excel')),
                ]),
              ],
            ),
          ),
          SectionBox(
            title: widget.kind == PeopleKind.customers ? 'جدول العملاء' : 'جدول الموردين',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.bgCard),
                columns: const [
                  DataColumn(label: Text('الرقم')),
                  DataColumn(label: Text('الاسم')),
                  DataColumn(label: Text('الجوال')),
                  DataColumn(label: Text('ملاحظات')),
                ],
                rows: [
                  for (final p in data)
                    DataRow(cells: [
                      DataCell(Text('${p.id}')),
                      DataCell(Text(p.name)),
                      DataCell(Text(p.phone)),
                      DataCell(Text(p.notes)),
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
