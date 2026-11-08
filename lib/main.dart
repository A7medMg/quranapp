import 'package:flutter/material.dart';
import 'package:quran_app/hadith_details_screen.dart';
import 'package:quran_app/constans/theme.dart';
import 'package:quran_app/home_screen.dart';
import 'package:quran_app/services/quran_cache.dart';
import 'package:quran_app/services/app_theme_controller.dart';
import 'package:quran_app/surah_details_screen.dart';

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
  cache.getHadiths().ignore();
  cache.getSurah(0).ignore(); // الفاتحة
  cache.getSurah(1).ignore(); // البقرة
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = AppThemeController.instance;
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemeData.forVariant(themeController.selected),
        home: const HomeScreen(),
        routes: {
          SurahDetailsScreen.routeName: (context) => const SurahDetailsScreen(),
          HadithDetailsScreen.routeName: (context) =>
              const HadithDetailsScreen(),
        },
      ),
    );
  }
}
