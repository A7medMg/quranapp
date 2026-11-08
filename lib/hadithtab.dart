import 'package:flutter/material.dart';

import 'screens/item_hadith_name.dart';
import 'services/quran_cache.dart';

class HadithTab extends StatefulWidget {
  const HadithTab({super.key});

  @override
  State<HadithTab> createState() => _HadithTabState();
}

class _HadithTabState extends State<HadithTab> {
  List<HadithData> _hadiths = [];
  bool _loaded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    try {
      // القراءة والتحليل في background isolate — مع كاش للاستدعاءات التالية
      final hadiths = await QuranCache.instance.getHadiths();
      if (mounted) {
        setState(() {
          _hadiths = hadiths;
          _loaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget listBody;

    if (_error != null) {
      listBody = Center(
        child: Text(
          'حدث خطأ أثناء تحميل الأحاديث',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    } else if (!_loaded) {
      listBody = Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      listBody = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _hadiths.length,
        itemBuilder: (context, index) {
          return Itemhadithname(hadithData: _hadiths[index]);
        },
        separatorBuilder: (context, index) {
          return const SizedBox(height: 8);
        },
      );
    }

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الأحاديث',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Expanded(child: listBody),
        ],
      ),
    );
  }
}
