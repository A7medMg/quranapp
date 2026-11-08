import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/features/hadith/data/hadith_cache.dart';

class HadithLibraryController extends ChangeNotifier {
  static const _favoritesKey = 'favorite_hadith_titles';

  Set<String> _favoriteIds = {};
  bool _loaded = false;
  bool _changedBeforeLoad = false;

  int get favoriteCount => _favoriteIds.length;
  bool get isLoaded => _loaded;

  bool isFavorite(HadithData hadith) =>
      _favoriteIds.contains(hadith.id) ||
      (hadith.legacyFavoriteKey != null &&
          _favoriteIds.contains(hadith.legacyFavoriteKey));

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedTitles = preferences.getStringList(_favoritesKey);
      if (!_changedBeforeLoad && savedTitles != null) {
        _favoriteIds = savedTitles.toSet();
      }
    } catch (_) {
      // Favorites remain usable in memory if local storage is unavailable.
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleFavorite(HadithData hadith) async {
    _changedBeforeLoad = true;
    final wasFavorite = _favoriteIds.remove(hadith.id);
    if (hadith.legacyFavoriteKey != null) {
      _favoriteIds.remove(hadith.legacyFavoriteKey);
    }
    if (wasFavorite) {
      _favoriteIds.remove(hadith.id);
    } else {
      _favoriteIds.add(hadith.id);
    }
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(
        _favoritesKey,
        _favoriteIds.toList()..sort(),
      );
    } catch (_) {
      // Preserve the in-memory change for this session.
    }
  }
}
