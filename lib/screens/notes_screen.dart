import 'package:flutter/material.dart';
import '../widgets/section_box.dart';
import '../widgets/action_bar.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: SectionBox(
        title: 'ملاحظات وتدوينات',
        child: Column(
          children: [
            const TextField(textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'عنوان الملاحظة')),
            const SizedBox(height: 10),
            const TextField(
              textAlign: TextAlign.right,
              minLines: 5,
              maxLines: 10,
              decoration: InputDecoration(labelText: 'اكتب الملاحظة هنا'),
            ),
            const SizedBox(height: 12),
            ActionBar(children: [
              FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.save), label: const Text('حفظ')),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.search), label: const Text('بحث')),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download), label: const Text('Excel')),
            ]),
          ],
        ),
      ),
    );
  }
}
