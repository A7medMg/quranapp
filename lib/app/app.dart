import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/core/theme/app_theme.dart';
import 'package:quran_app/core/theme/app_theme_controller.dart';
import 'package:quran_app/features/hadith/presentation/hadith_details_screen.dart';
import 'package:quran_app/features/home/presentation/home_screen.dart';
import 'package:quran_app/features/prayer/data/prayer_schedule_service.dart';
import 'package:quran_app/features/hadith/state/hadith_library_controller.dart';
import 'package:quran_app/features/quran/presentation/surah_details_screen.dart';
import 'package:quran_app/features/quran/state/quran_reading_controller.dart';
import 'package:quran_app/features/sebha/state/sebha_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeController>.value(
          value: AppThemeController.instance,
        ),
        ChangeNotifierProvider<PrayerScheduleService>.value(
          value: PrayerScheduleService.instance,
        ),
        ChangeNotifierProvider(
          create: (_) {
            final controller = QuranReadingController();
            unawaited(controller.loadLastRead());
            return controller;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final controller = HadithLibraryController();
            unawaited(controller.load());
            return controller;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final controller = SebhaController();
            unawaited(controller.load());
            return controller;
          },
        ),
      ],
      child: Consumer<AppThemeController>(
        builder: (context, themeController, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemeData.forVariant(themeController.selected),
          home: const HomeScreen(),
          routes: {
            SurahDetailsScreen.routeName: (context) =>
                const SurahDetailsScreen(),
            HadithDetailsScreen.routeName: (context) =>
                const HadithDetailsScreen(),
          },
        ),
      ),
    );
  }
}
