import 'package:flutter/material.dart';

import 'screens/item_hadith_details.dart';
import 'services/quran_cache.dart';

class HadithDetailsScreen extends StatelessWidget {
  const HadithDetailsScreen({super.key});

  static const String routeName = 'HadithDetailsScreen';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as HadithData;

    return Stack(
      children: [
        Image.asset(
          'assets/images/mainbacklight.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.fill,
        ),
        Scaffold(
          appBar: AppBar(
            title: Text(
              args.title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ItemHadithDetails(content: args.content),
          ),
        ),
      ],
    );
  }
}
