import 'package:flutter/foundation.dart';

import '../constans/surah_info.dart';

/// Builds on-demand audio URLs for the full Minshawi murattal recitation.
/// The Quran Cloud audio CDN uses the global (1-based) ayah number.
class QuranAudioService {
  QuranAudioService._();

  static const String reciterName = 'محمد صديق المنشاوي';
  static const String recitationStyle = 'مرتّل';
  static const String _baseUrl =
      'https://cdn.islamic.network/quran/audio/128/ar.minshawi';

  static Uri ayahUri({required int surahNumber, required int ayahNumber}) {
    if (surahNumber < 1 || surahNumber > QuranMetadata.surahs.length) {
      throw RangeError.range(surahNumber, 1, QuranMetadata.surahs.length);
    }

    final surah = QuranMetadata.getByZeroIndex(surahNumber - 1);
    if (ayahNumber < 1 || ayahNumber > surah.totalVerses) {
      throw RangeError.range(ayahNumber, 1, surah.totalVerses);
    }

    final precedingAyahs = QuranMetadata.surahs
        .take(surahNumber - 1)
        .fold<int>(0, (total, item) => total + item.totalVerses);
    final globalAyahNumber = precedingAyahs + ayahNumber;
    return Uri.parse('$_baseUrl/$globalAyahNumber.mp3');
  }

  static List<Uri> ayahUris({
    required int surahNumber,
    required Iterable<int> ayahNumbers,
  }) => List<Uri>.unmodifiable(
    ayahNumbers.map(
      (ayahNumber) => ayahUri(surahNumber: surahNumber, ayahNumber: ayahNumber),
    ),
  );

  @visibleForTesting
  static int globalAyahNumber({
    required int surahNumber,
    required int ayahNumber,
  }) => int.parse(
    ayahUri(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    ).pathSegments.last.replaceFirst('.mp3', ''),
  );
}
