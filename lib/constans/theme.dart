import 'package:flutter/material.dart';
import 'package:quran_app/constans/appcolor.dart';

class AppThemeData {
  static final lightTheme = ThemeData(
    primaryColor: Appcolor.brimarycolor,
    canvasColor: Appcolor.brimarycolor,

    scaffoldBackgroundColor: Colors.transparent,
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: Appcolor.blackColor,
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: Appcolor.blackColor,
        fontSize: 25,
        fontWeight: FontWeight.w700,
      ),
      bodySmall: TextStyle(
        color: Appcolor.blackColor,
        fontSize: 25,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: Appcolor.blackColor,
        fontSize: 25,
        fontWeight: FontWeight.w400,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Appcolor.brimarycolor,
      selectedItemColor: Appcolor.blackColor,
      unselectedItemColor: Colors.white,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Appcolor.blackColor,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
