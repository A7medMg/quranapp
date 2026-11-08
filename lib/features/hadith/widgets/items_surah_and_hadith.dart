import 'package:flutter/material.dart';
import 'package:quran_app/features/quran/presentation/surah_details_screen.dart';
import 'package:quran_app/features/quran/models/surah_details_args.dart';

class Itemssurahandhadith extends StatelessWidget {
  final String surahName;
  final int index;

  const Itemssurahandhadith({
    required this.surahName,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          SurahDetailsScreen.routeName,
          arguments: SurahDetailsArgs(
            surahName: surahName,
            index: index,
            startAtBeginning: true,
          ),
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
