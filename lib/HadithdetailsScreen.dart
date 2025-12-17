import 'package:flutter/material.dart';
import 'package:quran_app/hadithtab.dart';

import 'screens/itemHatithdetails.dart';

class HadithDetailsScreen extends StatefulWidget {
  HadithDetailsScreen({super.key});

  static const String routeName = 'HadithDetailsScreen';

  @override
  State<HadithDetailsScreen> createState() => _HadithDetailsScreenState();
}

class _HadithDetailsScreenState extends State<HadithDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments as HadithData;

    return Stack(
      children: [
        Image.asset(
          "assets/images/mainbacklight.png",
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
          body: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: 1,
            itemBuilder: (context, index) {
              return ItemHadithDetails(content: args.content);
            },
          ),
        ),
      ],
    );
  }

  List<String> cleanLines(List<String> lines) {
    return lines.map((line) {
      return line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    }).toList();
  }
}
