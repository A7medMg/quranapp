import 'package:flutter/material.dart';

class Itemsurahdetails extends StatelessWidget {
  final String content;
  final int index;

  const Itemsurahdetails({
    required this.content,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        "$content (${index + 1})",
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
