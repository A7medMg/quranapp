import 'package:flutter/material.dart';

class ItemHadithDetails extends StatelessWidget {
  final String content;

  const ItemHadithDetails({required this.content, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: SelectableText(
        content,
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          height: 1.9,
          fontSize: 22,
        ),
      ),
    );
  }
}
