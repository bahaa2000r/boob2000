import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../database/local_database.dart';
import '../models/item_model.dart';

class SmartItemSearch extends StatefulWidget {
  final ValueChanged<ItemModel> onSelected;
  const SmartItemSearch({super.key, required this.onSelected});

  @override
  State<SmartItemSearch> createState() => _SmartItemSearchState();
}

class _SmartItemSearchState extends State<SmartItemSearch> {
  final controller = TextEditingController();
  List<ItemModel> suggestions = [];

  void _search(String value) {
    final text = value.trim();
    setState(() {
      suggestions = text.isEmpty
          ? []
          : LocalDatabase.instance.items
              .where((i) => i.name.contains(text))
              .take(8)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            labelText: 'الصنف',
            hintText: 'اكتب جزء من اسم الصنف',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _search,
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.accent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return ListTile(
                  title: Text(item.name, textAlign: TextAlign.right),
                  subtitle: Text(
                    'الكمية: ${item.quantity} | مفرق: ${item.retailPrice} | جملة: ${item.wholesalePrice}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  onTap: () {
                    controller.text = item.name;
                    setState(() => suggestions = []);
                    widget.onSelected(item);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
