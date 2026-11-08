import 'package:flutter/material.dart';
import 'package:quran_app/constans/appcolor.dart';

enum AppThemeVariant { emerald, ocean, violet, amber }

class AppThemePalette extends ThemeExtension<AppThemePalette> {
  const AppThemePalette({
    required this.primary,
    required this.soft,
    required this.gradientStart,
    required this.gradientEnd,
    required this.background,
    required this.surface,
  });

  final Color primary;
  final Color soft;
  final Color gradientStart;
  final Color gradientEnd;
  final Color background;
  final Color surface;

  @override
  AppThemePalette copyWith({
    Color? primary,
    Color? soft,
    Color? gradientStart,
    Color? gradientEnd,
    Color? background,
    Color? surface,
  }) {
    return AppThemePalette(
      primary: primary ?? this.primary,
      soft: soft ?? this.soft,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      background: background ?? this.background,
      surface: surface ?? this.surface,
    );
  }

  @override
  AppThemePalette lerp(covariant AppThemePalette? other, double t) {
    if (other == null) return this;
    return AppThemePalette(
      primary: Color.lerp(primary, other.primary, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemePalette get appPalette =>
      Theme.of(this).extension<AppThemePalette>() ?? AppThemeData.emeraldPalette;
}

class AppThemeData {
  static const emeraldPalette = AppThemePalette(
    primary: Color(0xFF168064),
    soft: Color(0xFFE7F3EF),
    gradientStart: Color(0xFF0D7259),
    gradientEnd: Color(0xFF4CB68C),
    background: Color(0xFFF5F7F6),
    surface: Colors.white,
  );

  static const oceanPalette = AppThemePalette(
    primary: Color(0xFF2864B0),
    soft: Color(0xFFE8F0FA),
    gradientStart: Color(0xFF1A4F98),
    gradientEnd: Color(0xFF65A2E8),
    background: Color(0xFFF4F7FC),
    surface: Colors.white,
  );

  static const violetPalette = AppThemePalette(
    primary: Color(0xFF7755B2),
    soft: Color(0xFFF0EAF8),
    gradientStart: Color(0xFF5D3D96),
    gradientEnd: Color(0xFFA27BD2),
    background: Color(0xFFF8F6FB),
    surface: Colors.white,
  );

  static const amberPalette = AppThemePalette(
    primary: Color(0xFFA66A24),
    soft: Color(0xFFFBF0DE),
    gradientStart: Color(0xFF8E5317),
    gradientEnd: Color(0xFFD79E4D),
    background: Color(0xFFFAF7F1),
    surface: Colors.white,
  );

  static AppThemePalette paletteFor(AppThemeVariant variant) => switch (variant) {
    AppThemeVariant.emerald => emeraldPalette,
    AppThemeVariant.ocean => oceanPalette,
    AppThemeVariant.violet => violetPalette,
    AppThemeVariant.amber => amberPalette,
  };

  static ThemeData get lightTheme => forVariant(AppThemeVariant.emerald);

  static ThemeData forVariant(AppThemeVariant variant) {
    final palette = paletteFor(variant);
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: palette.primary,
      onPrimary: Colors.white,
      primaryContainer: palette.soft,
      onPrimaryContainer: palette.primary,
      secondary: palette.primary,
      surface: palette.surface,
    );

    return ThemeData(
      colorScheme: scheme,
      primaryColor: palette.primary,
      canvasColor: palette.surface,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: Appcolor.blackColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          color: Appcolor.blackColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodySmall: TextStyle(
          color: Appcolor.blackColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: Appcolor.blackColor,
          fontSize: 21,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: const Color(0xFF8A9692),
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: palette.primary,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: Color(0xFF8A9692),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
