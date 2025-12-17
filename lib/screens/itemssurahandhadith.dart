import 'package:flutter/material.dart';
import 'package:quran_app/surahdetailsScreen.dart';

class Itemssurahandhadith extends StatelessWidget {
  String surahName;
  int index;

  Itemssurahandhadith({required this.surahName, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          SurahDetailsScreen.routeName,
          arguments: SurahdetailsArgs(surahName: surahName, index: index),
        );
      },
      child: Text(
        surahName,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
