/// نموذج بيانات ومعلومات السورة
class SurahInfo {
  final int number; // 1-based index (1 to 114)
  final String name;
  final String type; // "مكية" أو "مدنية"
  final int totalVerses;

  const SurahInfo({
    required this.number,
    required this.name,
    required this.type,
    required this.totalVerses,
  });

  /// تحويل الأرقام إلى أرقام عربية-هندية
  String get arabicNumber => _toArabic(number);
  String get arabicTotalVerses => _toArabic(totalVerses);

  static String _toArabic(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}

/// قائمة بيانات جميع سور القرآن الكريم الـ 114 بالترتيب العثماني
class QuranMetadata {
  static const List<SurahInfo> surahs = [
    SurahInfo(number: 1, name: "الفاتحة", type: "مكية", totalVerses: 7),
    SurahInfo(number: 2, name: "البقرة", type: "مدنية", totalVerses: 286),
    SurahInfo(number: 3, name: "آل عمران", type: "مدنية", totalVerses: 200),
    SurahInfo(number: 4, name: "النساء", type: "مدنية", totalVerses: 176),
    SurahInfo(number: 5, name: "المائدة", type: "مدنية", totalVerses: 120),
    SurahInfo(number: 6, name: "الأنعام", type: "مكية", totalVerses: 165),
    SurahInfo(number: 7, name: "الأعراف", type: "مكية", totalVerses: 206),
    SurahInfo(number: 8, name: "الأنفال", type: "مدنية", totalVerses: 75),
    SurahInfo(number: 9, name: "التوبة", type: "مدنية", totalVerses: 129),
    SurahInfo(number: 10, name: "يونس", type: "مكية", totalVerses: 109),
    SurahInfo(number: 11, name: "هود", type: "مكية", totalVerses: 123),
    SurahInfo(number: 12, name: "يوسف", type: "مكية", totalVerses: 111),
    SurahInfo(number: 13, name: "الرعد", type: "مدنية", totalVerses: 43),
    SurahInfo(number: 14, name: "إبراهيم", type: "مكية", totalVerses: 52),
    SurahInfo(number: 15, name: "الحجر", type: "مكية", totalVerses: 99),
    SurahInfo(number: 16, name: "النحل", type: "مكية", totalVerses: 128),
    SurahInfo(number: 17, name: "الإسراء", type: "مكية", totalVerses: 111),
    SurahInfo(number: 18, name: "الكهف", type: "مكية", totalVerses: 110),
    SurahInfo(number: 19, name: "مريم", type: "مكية", totalVerses: 98),
    SurahInfo(number: 20, name: "طه", type: "مكية", totalVerses: 135),
    SurahInfo(number: 21, name: "الأنبياء", type: "مكية", totalVerses: 112),
    SurahInfo(number: 22, name: "الحج", type: "مدنية", totalVerses: 78),
    SurahInfo(number: 23, name: "المؤمنون", type: "مكية", totalVerses: 118),
    SurahInfo(number: 24, name: "النّور", type: "مدنية", totalVerses: 64),
    SurahInfo(number: 25, name: "الفرقان", type: "مكية", totalVerses: 77),
    SurahInfo(number: 26, name: "الشعراء", type: "مكية", totalVerses: 227),
    SurahInfo(number: 27, name: "النّمل", type: "مكية", totalVerses: 93),
    SurahInfo(number: 28, name: "القصص", type: "مكية", totalVerses: 88),
    SurahInfo(number: 29, name: "العنكبوت", type: "مكية", totalVerses: 69),
    SurahInfo(number: 30, name: "الرّوم", type: "مكية", totalVerses: 60),
    SurahInfo(number: 31, name: "لقمان", type: "مكية", totalVerses: 34),
    SurahInfo(number: 32, name: "السجدة", type: "مكية", totalVerses: 30),
    SurahInfo(number: 33, name: "الأحزاب", type: "مدنية", totalVerses: 73),
    SurahInfo(number: 34, name: "سبأ", type: "مكية", totalVerses: 54),
    SurahInfo(number: 35, name: "فاطر", type: "مكية", totalVerses: 45),
    SurahInfo(number: 36, name: "يس", type: "مكية", totalVerses: 83),
    SurahInfo(number: 37, name: "الصافات", type: "مكية", totalVerses: 182),
    SurahInfo(number: 38, name: "ص", type: "مكية", totalVerses: 88),
    SurahInfo(number: 39, name: "الزمر", type: "مكية", totalVerses: 75),
    SurahInfo(number: 40, name: "غافر", type: "مكية", totalVerses: 85),
    SurahInfo(number: 41, name: "فصلت", type: "مكية", totalVerses: 54),
    SurahInfo(number: 42, name: "الشورى", type: "مكية", totalVerses: 53),
    SurahInfo(number: 43, name: "الزخرف", type: "مكية", totalVerses: 89),
    SurahInfo(number: 44, name: "الدّخان", type: "مكية", totalVerses: 59),
    SurahInfo(number: 45, name: "الجاثية", type: "مكية", totalVerses: 37),
    SurahInfo(number: 46, name: "الأحقاف", type: "مكية", totalVerses: 35),
    SurahInfo(number: 47, name: "محمد", type: "مدنية", totalVerses: 38),
    SurahInfo(number: 48, name: "الفتح", type: "مدنية", totalVerses: 29),
    SurahInfo(number: 49, name: "الحجرات", type: "مدنية", totalVerses: 18),
    SurahInfo(number: 50, name: "ق", type: "مكية", totalVerses: 45),
    SurahInfo(number: 51, name: "الذاريات", type: "مكية", totalVerses: 60),
    SurahInfo(number: 52, name: "الطور", type: "مكية", totalVerses: 49),
    SurahInfo(number: 53, name: "النجم", type: "مكية", totalVerses: 62),
    SurahInfo(number: 54, name: "القمر", type: "مكية", totalVerses: 55),
    SurahInfo(number: 55, name: "الرحمن", type: "مدنية", totalVerses: 78),
    SurahInfo(number: 56, name: "الواقعة", type: "مكية", totalVerses: 96),
    SurahInfo(number: 57, name: "الحديد", type: "مدنية", totalVerses: 29),
    SurahInfo(number: 58, name: "المجادلة", type: "مدنية", totalVerses: 22),
    SurahInfo(number: 59, name: "الحشر", type: "مدنية", totalVerses: 24),
    SurahInfo(number: 60, name: "الممتحنة", type: "مدنية", totalVerses: 13),
    SurahInfo(number: 61, name: "الصف", type: "مدنية", totalVerses: 14),
    SurahInfo(number: 62, name: "الجمعة", type: "مدنية", totalVerses: 11),
    SurahInfo(number: 63, name: "المنافقون", type: "مدنية", totalVerses: 11),
    SurahInfo(number: 64, name: "التغابن", type: "مدنية", totalVerses: 18),
    SurahInfo(number: 65, name: "الطلاق", type: "مدنية", totalVerses: 12),
    SurahInfo(number: 66, name: "التحريم", type: "مدنية", totalVerses: 12),
    SurahInfo(number: 67, name: "الملك", type: "مكية", totalVerses: 30),
    SurahInfo(number: 68, name: "القلم", type: "مكية", totalVerses: 52),
    SurahInfo(number: 69, name: "الحاقة", type: "مكية", totalVerses: 52),
    SurahInfo(number: 70, name: "المعارج", type: "مكية", totalVerses: 44),
    SurahInfo(number: 71, name: "نوح", type: "مكية", totalVerses: 28),
    SurahInfo(number: 72, name: "الجن", type: "مكية", totalVerses: 28),
    SurahInfo(number: 73, name: "المزّمّل", type: "مكية", totalVerses: 20),
    SurahInfo(number: 74, name: "المدّثر", type: "مكية", totalVerses: 56),
    SurahInfo(number: 75, name: "القيامة", type: "مكية", totalVerses: 40),
    SurahInfo(number: 76, name: "الإنسان", type: "مدنية", totalVerses: 31),
    SurahInfo(number: 77, name: "المرسلات", type: "مكية", totalVerses: 50),
    SurahInfo(number: 78, name: "النبأ", type: "مكية", totalVerses: 40),
    SurahInfo(number: 79, name: "النازعات", type: "مكية", totalVerses: 46),
    SurahInfo(number: 80, name: "عبس", type: "مكية", totalVerses: 42),
    SurahInfo(number: 81, name: "التكوير", type: "مكية", totalVerses: 29),
    SurahInfo(number: 82, name: "الانفطار", type: "مكية", totalVerses: 19),
    SurahInfo(number: 83, name: "المطفّفين", type: "مكية", totalVerses: 36),
    SurahInfo(number: 84, name: "الانشقاق", type: "مكية", totalVerses: 25),
    SurahInfo(number: 85, name: "البروج", type: "مكية", totalVerses: 22),
    SurahInfo(number: 86, name: "الطارق", type: "مكية", totalVerses: 17),
    SurahInfo(number: 87, name: "الأعلى", type: "مكية", totalVerses: 19),
    SurahInfo(number: 88, name: "الغاشية", type: "مكية", totalVerses: 26),
    SurahInfo(number: 89, name: "الفجر", type: "مكية", totalVerses: 30),
    SurahInfo(number: 90, name: "البلد", type: "مكية", totalVerses: 20),
    SurahInfo(number: 91, name: "الشمس", type: "مكية", totalVerses: 15),
    SurahInfo(number: 92, name: "الليل", type: "مكية", totalVerses: 21),
    SurahInfo(number: 93, name: "الضحى", type: "مكية", totalVerses: 11),
    SurahInfo(number: 94, name: "الشرح", type: "مكية", totalVerses: 8),
    SurahInfo(number: 95, name: "التين", type: "مكية", totalVerses: 8),
    SurahInfo(number: 96, name: "العلق", type: "مكية", totalVerses: 19),
    SurahInfo(number: 97, name: "القدر", type: "مكية", totalVerses: 5),
    SurahInfo(number: 98, name: "البينة", type: "مدنية", totalVerses: 8),
    SurahInfo(number: 99, name: "الزلزلة", type: "مدنية", totalVerses: 8),
    SurahInfo(number: 100, name: "العاديات", type: "مكية", totalVerses: 11),
    SurahInfo(number: 101, name: "القارعة", type: "مكية", totalVerses: 11),
    SurahInfo(number: 102, name: "التكاثر", type: "مكية", totalVerses: 8),
    SurahInfo(number: 103, name: "العصر", type: "مكية", totalVerses: 3),
    SurahInfo(number: 104, name: "الهمزة", type: "مكية", totalVerses: 9),
    SurahInfo(number: 105, name: "الفيل", type: "مكية", totalVerses: 5),
    SurahInfo(number: 106, name: "قريش", type: "مكية", totalVerses: 4),
    SurahInfo(number: 107, name: "الماعون", type: "مكية", totalVerses: 7),
    SurahInfo(number: 108, name: "الكوثر", type: "مكية", totalVerses: 3),
    SurahInfo(number: 109, name: "الكافرون", type: "مكية", totalVerses: 6),
    SurahInfo(number: 110, name: "النصر", type: "مدنية", totalVerses: 3),
    SurahInfo(number: 111, name: "المسد", type: "مكية", totalVerses: 5),
    SurahInfo(number: 112, name: "الإخلاص", type: "مكية", totalVerses: 4),
    SurahInfo(number: 113, name: "الفلق", type: "مكية", totalVerses: 5),
    SurahInfo(number: 114, name: "الناس", type: "مكية", totalVerses: 6),
  ];

  static SurahInfo getByZeroIndex(int index) {
    if (index >= 0 && index < surahs.length) {
      return surahs[index];
    }
    return surahs[0];
  }
}
