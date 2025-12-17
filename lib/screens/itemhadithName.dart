import 'package:flutter/material.dart';
import 'package:quran_app/HadithdetailsScreen.dart';
import 'package:quran_app/hadithtab.dart';

class Itemhadithname extends StatelessWidget {
  HadithData hadithData;

  Itemhadithname({required this.hadithData, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).pushNamed(HadithDetailsScreen.routeName, arguments: hadithData);
      },
      child: Text(
        hadithData.title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
