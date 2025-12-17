import 'package:flutter/material.dart';

class ItemHadithDetails extends StatelessWidget {
  String content;

  ItemHadithDetails({required this.content, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      //textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}
