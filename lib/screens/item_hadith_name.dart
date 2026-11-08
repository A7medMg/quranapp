import 'package:flutter/material.dart';
import 'package:quran_app/hadith_details_screen.dart';
import 'package:quran_app/services/quran_cache.dart';

class Itemhadithname extends StatelessWidget {
  final HadithData hadithData;

  const Itemhadithname({required this.hadithData, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(HadithDetailsScreen.routeName, arguments: hadithData);
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 3,
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.menu_book_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            hadithData.title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          trailing: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF789089),
          ),
        ),
      ),
    );
  }
}
