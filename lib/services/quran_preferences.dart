import 'package:shared_preferences/shared_preferences.dart';

/// خدمة حفظ واسترجاع موضع القراءة الأخير ورقم الصفحة لكل سورة
class QuranPreferences {
  static const String _keyPrefixPage = 'surah_page_index_';
  static const String _keyPrefixScroll = 'surah_scroll_offset_';
  static const String _keyLastSurahIndex = 'last_read_surah_index';
  static const String _keyLastSurahName = 'last_read_surah_name';
  static const String _keyLastSurahPage = 'last_read_surah_page';

  /// حفظ رقم الصفحة الحالية لسورة معينة
  static Future<void> savePagePosition({
    required int surahIndex,
    required String surahName,
    required int pageIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefixPage$surahIndex', pageIndex);
    await prefs.setInt(_keyLastSurahIndex, surahIndex);
    await prefs.setString(_keyLastSurahName, surahName);
    await prefs.setInt(_keyLastSurahPage, pageIndex);
  }

  /// جلب رقم الصفحة المحفوظ لسورة معينة (افتراضياً 0 - أول صفحة)
  static Future<int> getPagePosition(int surahIndex) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefixPage$surahIndex') ?? 0;
  }

  /// جلب بيانات آخر سورة تمت قراءتها مع اسمها ورقمها ورقم الصفحة
  static Future<Map<String, dynamic>?> getLastReadSurah() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyLastSurahIndex);
    final name = prefs.getString(_keyLastSurahName);
    final page = prefs.getInt(_keyLastSurahPage) ?? 0;
    if (index != null && name != null) {
      return {'index': index, 'name': name, 'page': page};
    }
    return null;
  }

  /// حفظ موضع الاسكرول (للتوافق القديم)
  static Future<void> saveScrollPosition({
    required int surahIndex,
    required String surahName,
    required double scrollOffset,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_keyPrefixScroll$surahIndex', scrollOffset);
    await prefs.setInt(_keyLastSurahIndex, surahIndex);
    await prefs.setString(_keyLastSurahName, surahName);
  }

  /// جلب موضع الاسكرول (للتوافق القديم)
  static Future<double> getScrollPosition(int surahIndex) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_keyPrefixScroll$surahIndex') ?? 0.0;
  }

  /// مسح موضع سورة معينة
  static Future<void> resetSurahPosition(int surahIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefixPage$surahIndex');
    await prefs.remove('$_keyPrefixScroll$surahIndex');
  }
}
