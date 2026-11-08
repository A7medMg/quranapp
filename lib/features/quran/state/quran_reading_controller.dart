import 'package:flutter/foundation.dart';
import 'package:quran_app/features/quran/data/quran_preferences.dart';
import 'package:quran_app/features/quran/models/quran_reading_position.dart';

class QuranReadingController extends ChangeNotifier {
  QuranReadingPosition? _lastRead;
  bool _isLoaded = false;
  bool _hasLocalUpdate = false;

  QuranReadingPosition? get lastRead => _lastRead;
  bool get isLoaded => _isLoaded;

  Future<void> loadLastRead() async {
    try {
      final saved = await QuranPreferences.getLastReadPosition();
      if (!_hasLocalUpdate) _lastRead = saved;
    } catch (_) {
      _lastRead = null;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> savePagePosition({
    required int surahIndex,
    required String surahName,
    required int pageIndex,
  }) async {
    _hasLocalUpdate = true;
    final position = QuranReadingPosition(
      surahIndex: surahIndex,
      surahName: surahName,
      pageIndex: pageIndex,
    );

    if (_lastRead != position || !_isLoaded) {
      _lastRead = position;
      _isLoaded = true;
      notifyListeners();
    }

    try {
      await QuranPreferences.savePagePosition(
        surahIndex: surahIndex,
        surahName: surahName,
        pageIndex: pageIndex,
      );
    } catch (_) {
      // Keep the current session's reading position available in memory.
    }
  }
}
