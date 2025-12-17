import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constans/appcolor.dart';
import 'screens/itemhadithName.dart';

class HadithTab extends StatefulWidget {
  HadithTab({super.key});

  @override
  State<HadithTab> createState() => _HadithTabState();
}

class _HadithTabState extends State<HadithTab> {
  List hadiths = [];

  @override
  Widget build(BuildContext context) {
    loadHadithFile();
    return Column(
      children: [
        Expanded(child: Image.asset("assets/images/logo.png")),
        Divider(color: Appcolor.brimarycolor, thickness: 3),

        Text("hadith name", style: Theme.of(context).textTheme.bodyMedium),
        Divider(color: Appcolor.brimarycolor, thickness: 3),
        Expanded(
          flex: 2,
          child: hadiths.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: Appcolor.brimarycolor,
                  ),
                )
              : ListView.separated(
                  itemCount: hadiths.length,
                  itemBuilder: (context, index) {
                    return Itemhadithname(hadithData: hadiths[index]);
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Divider(color: Appcolor.brimarycolor, thickness: 3);
                  },
                ),
        ),
      ],
    );
  }

  Future<void> loadHadithFile() async {
    // قراءة الملف
    String data = await rootBundle.loadString('assets/files/h.txt');

    // تقسيم الأحاديث
    List<String> blocks = data.split(RegExp(r'\n\s*#\s*\n'));

    hadiths.clear();

    for (String block in blocks) {
      block = block.trim();
      if (block.isEmpty) continue;

      // تقسيم السطور
      List<String> lines = block.split('\n');

      if (lines.isEmpty) continue;

      String title = lines.first.trim();

      // باقي النص محتوى الحديث
      String content = lines.skip(1).join('\n').trim();

      hadiths.add(HadithData(title: title, content: content));
    }

    setState(() {});
  }
}

class HadithData {
  final String title;
  final String content;

  HadithData({required this.title, required this.content});
}
