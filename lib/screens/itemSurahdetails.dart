import 'package:flutter/material.dart';

class Itemsurahdetails extends StatelessWidget {
  String content;

  int index;

  Itemsurahdetails({required this.content, required this.index, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      child: Text(
        "${content}${index > 0 ? "(${index})" : ''}",
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
