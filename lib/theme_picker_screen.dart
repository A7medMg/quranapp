import 'package:flutter/material.dart';

import 'constans/theme.dart';
import 'services/app_theme_controller.dart';

class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key});

  static const _ink = Color(0xFF26343B);
  static const _muted = Color(0xFF73817E);

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.instance;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.appPalette.background,
        appBar: AppBar(
          title: const Text('مظهر التطبيق'),
          centerTitle: true,
          backgroundColor: context.appPalette.surface,
          foregroundColor: _ink,
          elevation: 0,
        ),
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            children: [
              const Text(
                'اختار اللون اللي يريحك',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'هيتطبق على التطبيق كله ويتحفظ اختيارك تلقائيًا.',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              for (final variant in AppThemeVariant.values) ...[
                _ThemeChoiceCard(
                  variant: variant,
                  selected: controller.selected == variant,
                  onTap: () => controller.select(variant),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  const _ThemeChoiceCard({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final AppThemeVariant variant;
  final bool selected;
  final VoidCallback onTap;

  String get _name => switch (variant) {
    AppThemeVariant.emerald => 'أخضر هادئ',
    AppThemeVariant.ocean => 'أزرق المحيط',
    AppThemeVariant.violet => 'بنفسجي أنيق',
    AppThemeVariant.amber => 'رملي دافئ',
  };

  String get _description => switch (variant) {
    AppThemeVariant.emerald => 'المظهر الأصلي للتطبيق',
    AppThemeVariant.ocean => 'درجات زرقاء هادئة',
    AppThemeVariant.violet => 'درجات بنفسجية ناعمة',
    AppThemeVariant.amber => 'درجات رملية دافئة',
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeData.paletteFor(variant);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? palette.primary : const Color(0xFFE5ECE9),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.gradientStart, palette.gradientEnd],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.palette_rounded, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        color: Color(0xFF26343B),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _description,
                      style: const TextStyle(
                        color: Color(0xFF73817E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? palette.primary : const Color(0xFFB7C1BE),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
