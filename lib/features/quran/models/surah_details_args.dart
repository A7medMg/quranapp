class SurahDetailsArgs {
  const SurahDetailsArgs({
    required this.surahName,
    required this.index,
    this.startAtBeginning = false,
  });

  final String surahName;
  final int index;
  final bool startAtBeginning;
}
