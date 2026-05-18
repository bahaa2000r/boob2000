import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  final List<Widget> children;

  const ActionBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,
      children: children,
    );
  }
}
