import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HadithData {
  const HadithData({
    required this.id,
    required this.title,
    required this.content,
    required this.collection,
    required this.searchText,
    this.legacyFavoriteKey,
    this.bookTitle,
    this.bookNumber,
    this.hadithNumber,
    this.sourceNumber,
  });

  final String id;
  final String title;
  final String content;
  final String collection;
  final String searchText;
  final String? legacyFavoriteKey;
  final String? bookTitle;
  final int? bookNumber;
  final int? hadithNumber;
  final String? sourceNumber;

  bool get isSahihMuslim => collection == 'صحيح مسلم';

  bool get isSahihBukhari => collection == 'صحيح البخاري';

  String get referenceLabel {
    if (isSahihMuslim) {
      final sourceRef = sourceNumber?.isNotEmpty == true
          ? ' • ترقيم $sourceNumber'
          : '';
      return '${bookTitle ?? 'صحيح مسلم'} • رقم $hadithNumber$sourceRef';
    }
    if (isSahihBukhari) {
      final title = bookTitle ?? 'كتاب ${bookNumber ?? 0}';
      final sourceRef = sourceNumber?.isNotEmpty == true
          ? ' • الترقيم $sourceNumber'
          : '';
      return 'صحيح البخاري • $title • رقم $hadithNumber$sourceRef';
    }
    return collection;
  }
}

class HadithNavigationArgs {
  const HadithNavigationArgs({
    required this.hadiths,
    required this.initialIndex,
  });

  final List<HadithData> hadiths;
  final int initialIndex;
}

class _ParseHadithParams {
  const _ParseHadithParams({
    required this.editionJson,
    required this.collection,
    required this.curatedText,
  });

  final String editionJson;
  final String collection;
  final String curatedText;
}
const _sahihMuslimBooks = <int, String>{
  0: 'المقدمة',
  1: 'كتاب الإيمان',
  2: 'كتاب الطهارة',
  3: 'كتاب الحيض',
  4: 'كتاب الصلاة',
  5: 'كتاب المساجد ومواضع الصلاة',
  6: 'كتاب صلاة المسافرين وقصرها',
  7: 'كتاب الجمعة',
  8: 'كتاب العيدين',
  9: 'كتاب الاستسقاء',
  10: 'كتاب الكسوف',
  11: 'كتاب الجنائز',
  12: 'كتاب الزكاة',
  13: 'كتاب الصيام',
  14: 'كتاب الاعتكاف',
  15: 'كتاب الحج',
  16: 'كتاب النكاح',
  17: 'كتاب الرضاع',
  18: 'كتاب الطلاق',
  19: 'كتاب اللعان',
  20: 'كتاب العتق',
  21: 'كتاب البيوع',
  22: 'كتاب المساقاة',
  23: 'كتاب الفرائض',
  24: 'كتاب الهبات',
  25: 'كتاب الوصية',
  26: 'كتاب النذر',
  27: 'كتاب الأيمان',
  28: 'كتاب القسامة والمحاربين والقصاص والديات',
  29: 'كتاب الحدود',
  30: 'كتاب الأقضية',
  31: 'كتاب اللقطة',
  32: 'كتاب الجهاد والسير',
  33: 'كتاب الإمارة',
  34: 'كتاب الصيد والذبائح',
  35: 'كتاب الأضاحي',
  36: 'كتاب الأشربة',
  37: 'كتاب اللباس والزينة',
  38: 'كتاب الآداب',
  39: 'كتاب السلام',
  40: 'كتاب الألفاظ من الأدب وغيرها',
  41: 'كتاب الشعر',
  42: 'كتاب الرؤيا',
  43: 'كتاب الفضائل',
  44: 'كتاب فضائل الصحابة',
  45: 'كتاب البر والصلة والآداب',
  46: 'كتاب القدر',
  47: 'كتاب العلم',
  48: 'كتاب الذكر والدعاء والتوبة والاستغفار',
  49: 'كتاب الرقاق',
  50: 'كتاب التوبة',
  51: 'كتاب صفات المنافقين وأحكامهم',
  52: 'كتاب صفة القيامة والجنة والنار',
  53: 'كتاب الجنة وصفة نعيمها وأهلها',
  54: 'كتاب الفتن وأشراط الساعة',
  55: 'كتاب الزهد والرقائق',
  56: 'كتاب التفسير',
};

String _normalizeArabic(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
    .replaceAll('\u0640', '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .trim();

String _shortHadithTitle(String content, String fallback) {
  final quotedText = RegExp(r'["«“]([\s\S]{8,100}?)[»”"]')
      .firstMatch(content)
      ?.group(1);
  if (quotedText == null) return fallback;

  final title = quotedText
      .replaceAll(RegExp(r'[\u200E\u200F]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (title.isEmpty) return fallback;
  if (title.length <= 64) return title;
  final wordEnd = title.lastIndexOf(' ', 64);
  final end = wordEnd >= 32 ? wordEnd : 64;
  return '${title.substring(0, end)}…';
}

List<HadithData> _parseHadithsInIsolate(_ParseHadithParams params) {
  final isMuslim = params.collection == 'صحيح مسلم';
  final decoded = jsonDecode(params.editionJson) as Map<String, dynamic>;
  final entries = decoded['entries'] as List<dynamic>;
  final result = <HadithData>[];
  final collectionPrefix = isMuslim ? 'sahih-muslim' : 'sahih-bukhari';

  for (final value in entries) {
    final entry = value as Map<String, dynamic>;
    final id = entry['id'] as int;
    final book = entry['book'] as int? ?? 0;
    final sourceNumber = entry['number'] as String?;
    final bookTitle = isMuslim
        ? (_sahihMuslimBooks[book] ?? params.collection)
        : 'كتاب $book';
    final content = (entry['text'] as String? ?? '').trim();
    if (content.isEmpty) continue;
    final title = _shortHadithTitle(content, bookTitle);

    result.add(
      HadithData(
        id: '$collectionPrefix:$id',
        title: title,
        content: content,
        collection: params.collection,
        searchText: _normalizeArabic(
          '$title $bookTitle $sourceNumber $content',
        ),
        bookTitle: bookTitle,
        bookNumber: book,
        hadithNumber: id,
        sourceNumber: sourceNumber,
      ),
    );
  }

  if (isMuslim) {
    final blocks = params.curatedText.split(RegExp(r'\n\s*#\s*\n'));
    for (var index = 0; index < blocks.length; index++) {
      final lines = blocks[index].trim().split('\n');
      if (lines.length < 2) continue;

      final content = lines.skip(1).join('\n').trim();
      if (content.isEmpty) continue;

      final quotedTitle = RegExp(r'[\(（«](.+?)[\)）»]')
          .firstMatch(content)
          ?.group(1);
      final title = quotedTitle?.trim().isNotEmpty == true
          ? quotedTitle!.trim()
          : content.substring(0, content.length > 55 ? 55 : content.length);

      result.add(
        HadithData(
          id: 'selected:${index + 1}',
          title: title,
          content: content,
          collection: 'مختارات سابقة',
          searchText: _normalizeArabic('$title $content'),
          legacyFavoriteKey: lines.first.trim(),
        ),
      );
    }
  }

  return result;
}
class HadithCache {
  HadithCache._();

  static final HadithCache instance = HadithCache._();

  final Map<String, List<HadithData>> _cache = {};
  final Map<String, Future<List<HadithData>>> _loading = {};

  Future<List<HadithData>> getHadiths({String collection = 'صحيح مسلم'}) {
    final cached = _cache[collection];
    if (cached != null) return Future.value(cached);

    final pending = _loading[collection];
    if (pending != null) return pending;

    final future = _load(collection);
    _loading[collection] = future;
    return future.whenComplete(() {
      if (identical(_loading[collection], future)) {
        _loading.remove(collection);
      }
    });
  }

  Future<List<HadithData>> _load(String collection) async {
    final isMuslim = collection == 'صحيح مسلم';
    final sourcePath = isMuslim
        ? 'assets/files/sahih_muslim_source.json'
        : 'assets/files/sahih_bukhari_source.json';
    final editionJson = await rootBundle.loadString(sourcePath);
    final curatedText = isMuslim
        ? await rootBundle.loadString('assets/files/h.txt')
        : '';

    final hadiths = await compute(
      _parseHadithsInIsolate,
      _ParseHadithParams(
        editionJson: editionJson,
        collection: collection,
        curatedText: curatedText,
      ),
    );
    _cache[collection] = hadiths;
    return hadiths;
  }
}
