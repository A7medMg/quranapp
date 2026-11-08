class SebhaDhikr {
  const SebhaDhikr({required this.id, required this.text});

  final String id;
  final String text;
}

abstract final class SebhaDhikrList {
  static const items = <SebhaDhikr>[
    SebhaDhikr(id: 'subhan_allah', text: 'سُبْحَانَ اللَّهِ'),
    SebhaDhikr(id: 'alhamdulillah', text: 'الْحَمْدُ لِلَّهِ'),
    SebhaDhikr(id: 'allahu_akbar', text: 'اللَّهُ أَكْبَرُ'),
    SebhaDhikr(id: 'la_ilaha_illa_allah', text: 'لَا إِلَهَ إِلَّا اللَّهُ'),
    SebhaDhikr(id: 'astaghfirullah', text: 'أَسْتَغْفِرُ اللَّهَ'),
    SebhaDhikr(
      id: 'salawat',
      text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    ),
  ];
}
