import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// مقطع من عدة آيات متتالية يُعرض معاً في فقرة واحدة متدفقة
class VerseChunk {
  /// رقم أول آية في هذا المقطع (يبدأ من 1)
  final int startingVerseNumber;

  /// نصوص الآيات في هذا المقطع
  final List<String> verses;

  const VerseChunk({required this.startingVerseNumber, required this.verses});
}

/// صفحة واحدة من السورة تحتوي على عدد محدد من الآيات (9 آيات لكل صفحة كالمطلوب)
class SurahPageFragment {
  final int verseNumber;
  final String text;
  final bool endsVerse;

  const SurahPageFragment({
    required this.verseNumber,
    required this.text,
    required this.endsVerse,
  });
}

class SurahPage {
  /// رقم الصفحة داخل السورة (يبدأ من 0)
  final int pageIndex;

  /// رقم أول آية في هذه الصفحة (1-based)
  final int startingVerseNumber;

  /// نصوص الآيات في هذه الصفحة
  final List<String> verses;
  final List<SurahPageFragment> fragments;

  const SurahPage({
    required this.pageIndex,
    required this.startingVerseNumber,
    required this.verses,
    this.fragments = const [],
  });
}

/// نتيجة تحليل السورة
class SurahData {
  /// نص البسملة إن وُجدت مستقلة، أو null
  final String? basmala;

  /// قائمة الآيات بعد إزالة الأرقام والبسملة
  final List<String> verses;

  /// مقاطع مجمعة من الآيات للعرض السلس
  final List<VerseChunk> chunks;

  /// صفحات السورة (9 آيات في كل صفحة للتقليب الأفقي كالمصحف)
  final List<SurahPage> pages;

  const SurahData({
    required this.basmala,
    required this.verses,
    required this.chunks,
    required this.pages,
  });
}

/// معاملات تُمرَّر إلى compute() — يجب أن تكون قابلة للتسلسل (no closures)
class _ParseParams {
  final String rawContent;
  const _ParseParams(this.rawContent);
}

// تعبير نمطي للبسملة بجميع أشكالها في الملفات (مع تشكيل أو بدون، مع أو بدون شدّة)
final _basmalaRegex = RegExp(
  r'^(?:بِّسْمِ|بِسْمِ)\s+اللَّهِ\s+الرَّحْمَـٰنِ\s+الرَّحِيمِ\s*',
);

const _standardBasmala = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';

/// دالة pure تعمل في Isolate منفصل — لا تلمس الـ UI
SurahData _parseSurahInIsolate(_ParseParams params) {
  final numbering = RegExp(r'^\d+\.\s*');
  final rawLines = params.rawContent.split('\n');

  // ندمج السطور: كل سطر مرقَّم = آية جديدة.
  // السطر غير المرقَّم (مثل "الم" في البقرة بعد سطر البسملة) يُلحَق بالآية السابقة.
  final verses = <String>[];
  for (final raw in rawLines) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    if (numbering.hasMatch(line)) {
      // آية جديدة — أزِل الرقم وأضفها
      verses.add(line.replaceFirst(numbering, '').trim());
    } else {
      // سطر بدون رقم → يُلحَق بالآية السابقة (إن وُجدت)
      if (verses.isNotEmpty) {
        verses[verses.length - 1] = '${verses.last} $line';
      } else {
        verses.add(line);
      }
    }
  }

  // فصل البسملة لتكون في رأس السورة بدون ترقيم، وتبدأ السورة بدونها
  String? basmala;
  if (verses.isNotEmpty && _basmalaRegex.hasMatch(verses.first)) {
    basmala = _standardBasmala;
    final after = verses.first.replaceFirst(_basmalaRegex, '').trim();
    if (after.isEmpty) {
      // السطر الأول كان يحتوي على البسملة فقط (مثل الفاتحة)
      verses.removeAt(0);
    } else {
      // البسملة كانت متصلة ببداية الآية الأولى (مثل البقرة، آل عمران، النساء، الإخلاص...)
      verses[0] = after;
    }
  }

  // تجميع الآيات في مقاطع خفيفة (Chunks) للـ ListView.builder
  // هذا يضمن السلاسة التامة (60/120 FPS) في الاسكرول للسور الطويلة كالبقرة
  final chunks = <VerseChunk>[];
  var currentVerses = <String>[];
  var currentChars = 0;
  var chunkStartVerseNum = 1;

  for (int i = 0; i < verses.length; i++) {
    final v = verses[i];
    currentVerses.add(v);
    currentChars += v.length;

    // نقسم عند الوصول إلى 4 آيات أو ~350 حرف
    if (currentVerses.length >= 4 || currentChars >= 350) {
      chunks.add(
        VerseChunk(
          startingVerseNumber: chunkStartVerseNum,
          verses: List.unmodifiable(currentVerses),
        ),
      );
      chunkStartVerseNum = i + 2;
      currentVerses = <String>[];
      currentChars = 0;
    }
  }

  if (currentVerses.isNotEmpty) {
    chunks.add(
      VerseChunk(
        startingVerseNumber: chunkStartVerseNum,
        verses: List.unmodifiable(currentVerses),
      ),
    );
  }

  // تقسيم الآيات إلى صفحات تناسب شاشة الهاتف تماماً بدون حاجة للاسكرول
  final pages = <SurahPage>[];
  var pageVerses = <String>[];
  var pageChars = 0;
  var startVerseNum = 1;

  for (int i = 0; i < verses.length; i++) {
    final v = verses[i];
    final isFirstPage = pages.isEmpty;
    // الصفحة الأولى بها إطار السورة والبسملة فنخصص لها ميزانية مناسبة، وباقي الصفحات تملأ الشاشة
    // Keep page text at a consistent font size on phones. Smaller page
    // batches leave enough vertical room without scaling the text down.
    final maxVerses = isFirstPage ? 4 : 7;
    final maxChars = isFirstPage ? 250 : 350;

    pageVerses.add(v);
    // Quranic diacritics are separate Unicode characters. Exclude them from
    // the page budget so fully vocalized verses do not create tiny pages.
    pageChars += v
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .length;

    // نقسم الصفحة إذا استوفت الحد المناسب لحجم الشاشة
    if (pageVerses.length >= maxVerses || pageChars >= maxChars) {
      pages.add(
        SurahPage(
          pageIndex: pages.length,
          startingVerseNumber: startVerseNum,
          verses: List.unmodifiable(pageVerses),
        ),
      );
      startVerseNum = i + 2;
      pageVerses = <String>[];
      pageChars = 0;
    }
  }

  if (pageVerses.isNotEmpty) {
    pages.add(
      SurahPage(
        pageIndex: pages.length,
        startingVerseNumber: startVerseNum,
        verses: List.unmodifiable(pageVerses),
      ),
    );
  }

  if (pages.isEmpty) {
    pages.add(
      const SurahPage(pageIndex: 0, startingVerseNumber: 1, verses: []),
    );
  }

  return SurahData(
    basmala: basmala,
    verses: verses,
    chunks: chunks,
    pages: pages,
  );
}

/// معاملات تحليل الأحاديث
class _ParseHadithParams {
  final String rawContent;
  const _ParseHadithParams(this.rawContent);
}

/// بيانات حديث واحد
class HadithData {
  final String title;
  final String content;
  const HadithData({required this.title, required this.content});
}

/// دالة pure لتحليل ملف الأحاديث في Isolate منفصل
List<HadithData> _parseHadithInIsolate(_ParseHadithParams params) {
  final blocks = params.rawContent.split(RegExp(r'\n\s*#\s*\n'));
  final result = <HadithData>[];

  for (final block in blocks) {
    final trimmed = block.trim();
    if (trimmed.isEmpty) continue;

    final lines = trimmed.split('\n');
    if (lines.isEmpty) continue;

    final title = lines.first.trim();
    final content = lines.skip(1).join('\n').trim();
    result.add(HadithData(title: title, content: content));
  }

  return result;
}

/// Cache مركزي يحتفظ بنتائج القراءة والتحليل طوال دورة حياة التطبيق.
/// يمنع إعادة قراءة وتحليل نفس الملف عند العودة للسورة.
class QuranCache {
  QuranCache._();
  static final QuranCache instance = QuranCache._();

  final _surahCache = <int, SurahData>{};
  List<HadithData>? _hadithCache;

  /// جلب بيانات سورة — يُعيد النتيجة من الكاش مباشرةً إن كانت محمّلة،
  /// وإلا يقرأ الملف ويحلّله في background isolate.
  Future<SurahData> getSurah(int surahIndex) async {
    if (_surahCache.containsKey(surahIndex)) {
      return _surahCache[surahIndex]!;
    }

    final raw = await rootBundle.loadString(
      'assets/files/${surahIndex + 1}.txt',
    );

    // تحليل النص في isolate منفصل — لا يعطّل الـ UI thread
    final data = await compute(_parseSurahInIsolate, _ParseParams(raw));
    _surahCache[surahIndex] = data;
    return data;
  }

  /// جلب بيانات الأحاديث مع كاش
  Future<List<HadithData>> getHadiths() async {
    if (_hadithCache != null) return _hadithCache!;

    final raw = await rootBundle.loadString('assets/files/h.txt');
    final data = await compute(_parseHadithInIsolate, _ParseHadithParams(raw));
    _hadithCache = data;
    return data;
  }

  /// مسح الكاش (للاختبار فقط)
  @visibleForTesting
  void clearCache() {
    _surahCache.clear();
    _hadithCache = null;
  }
}
