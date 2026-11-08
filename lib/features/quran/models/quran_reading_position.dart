class QuranReadingPosition {
  const QuranReadingPosition({
    required this.surahIndex,
    required this.surahName,
    required this.pageIndex,
  });

  final int surahIndex;
  final String surahName;
  final int pageIndex;

  @override
  bool operator ==(Object other) =>
      other is QuranReadingPosition &&
      other.surahIndex == surahIndex &&
      other.surahName == surahName &&
      other.pageIndex == pageIndex;

  @override
  int get hashCode => Object.hash(surahIndex, surahName, pageIndex);
}
