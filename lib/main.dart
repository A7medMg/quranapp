import 'package:flutter/widgets.dart';
import 'package:quran_app/app/app.dart';
import 'package:quran_app/features/hadith/data/hadith_cache.dart';
import 'package:quran_app/features/quran/data/quran_cache.dart';
import 'package:quran_app/core/theme/app_theme_controller.dart';

export 'package:quran_app/app/app.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تسخين الكاش في الخلفية فور بدء التطبيق
  _warmUpCache();
  await AppThemeController.instance.load();

  runApp(const MyApp());
}

/// يبدأ تحميل البيانات في الخلفية بدون انتظار
void _warmUpCache() {
  final cache = QuranCache.instance;
  HadithCache.instance.getHadiths().ignore();
  cache.getSurah(0).ignore(); // الفاتحة
  cache.getSurah(1).ignore(); // البقرة
}
