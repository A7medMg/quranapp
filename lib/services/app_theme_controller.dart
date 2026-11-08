import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constans/theme.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();
  static const _preferenceKey = 'selected_app_theme';

  AppThemeVariant _selected = AppThemeVariant.emerald;
  AppThemeVariant get selected => _selected;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString(_preferenceKey);
      for (final variant in AppThemeVariant.values) {
        if (variant.name == value) {
          _selected = variant;
          break;
        }
      }
    } catch (_) {
      // The default theme remains available if preferences cannot be read.
    }
    notifyListeners();
  }

  Future<void> select(AppThemeVariant variant) async {
    if (_selected == variant) return;
    _selected = variant;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_preferenceKey, variant.name);
    } catch (_) {
      // Keep this session's selection even if saving preferences fails.
    }
  }
}
