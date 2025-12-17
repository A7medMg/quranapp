import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constans/appcolor.dart';
import 'screens/itemSurahdetails.dart';

class SurahDetailsScreen extends StatefulWidget {
  SurahDetailsScreen({super.key});

  static const String routeName = 'surahDetailsScreen';

  @override
  State<SurahDetailsScreen> createState() => _SurahDetailsScreenState();
}

class _SurahDetailsScreenState extends State<SurahDetailsScreen> {
  List verses = [];

  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments as SurahdetailsArgs;
    if (verses.isEmpty) {
      loadFile(args.index);
    }

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
              args.surahName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          body: verses.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: Appcolor.brimarycolor,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  itemCount: verses.length,
                  itemBuilder: (context, index) {
                    return Itemsurahdetails(
                      content: verses[index],
                      index: index,
                    );
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

  void loadFile(int index) async {
    String fileContent = await rootBundle.loadString(
      'assets/files/${index + 1}.txt',
    );
    fileContent.split('\n');
    List<String> lines = fileContent.split('\n');

    lines = cleanLines(lines);
    verses = lines;
    setState(() {});
  }
}

class SurahdetailsArgs {
  String surahName;
  int index;

  SurahdetailsArgs({required this.surahName, required this.index});
}
