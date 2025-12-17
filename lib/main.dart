import 'package:flutter/material.dart';
import 'package:quran_app/HadithdetailsScreen.dart';
import 'package:quran_app/constans/theme.dart';
import 'package:quran_app/homeScreen.dart';
import 'package:quran_app/surahdetailsScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Homescreen.routeName,
      routes:  {
        Homescreen.routeName: (context) => const Homescreen(),
        SurahDetailsScreen.routeName: (context) => SurahDetailsScreen(),
        HadithDetailsScreen.routeName: (context) => HadithDetailsScreen(),
      },
      theme: AppThemeData.lightTheme,
    );
  }
}

