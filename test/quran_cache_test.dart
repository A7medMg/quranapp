import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final basmalaRegex = RegExp(
    r'^(?:بِّسْمِ|بِسْمِ)\s+اللَّهِ\s+الرَّحْمَـٰنِ\s+الرَّحِيمِ\s*',
  );
  const standardBasmala = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';

  List<String> parseSurah(String rawContent, {required bool expectBasmala}) {
    final numbering = RegExp(r'^\d+\.\s*');
    final rawLines = rawContent.split('\n');

    final verses = <String>[];
    for (final raw in rawLines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (numbering.hasMatch(line)) {
        verses.add(line.replaceFirst(numbering, '').trim());
      } else {
        if (verses.isNotEmpty) {
          verses[verses.length - 1] = '${verses.last} $line';
        } else {
          verses.add(line);
        }
      }
    }

    String? basmala;
    if (verses.isNotEmpty && basmalaRegex.hasMatch(verses.first)) {
      basmala = standardBasmala;
      final after = verses.first.replaceFirst(basmalaRegex, '').trim();
      if (after.isEmpty) {
        verses.removeAt(0);
      } else {
        verses[0] = after;
      }
    }

    if (expectBasmala) {
      expect(basmala, equals(standardBasmala));
    } else {
      expect(basmala, isNull);
    }

    return verses;
  }

  test('Surah Al-Fatihah (1.txt) has Basmala on top, v1 is Al-Hamdu lillah', () {
    final content = File('assets/files/1.txt').readAsStringSync();
    final verses = parseSurah(content, expectBasmala: true);
    expect(verses.first, startsWith('الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'));
  });

  test('Surah Al-Baqarah (2.txt) has Basmala on top, v1 is ONLY Alif-Lam-Mim', () {
    final content = File('assets/files/2.txt').readAsStringSync();
    final verses = parseSurah(content, expectBasmala: true);
    expect(verses[0], equals('الم'));
    expect(verses[1], startsWith('ذَٰلِكَ الْكِتَابُ'));
    expect(verses.length, equals(286));
  });

  test('Surah Ali-Imran (3.txt) has Basmala on top, v1 is ONLY Alif-Lam-Mim', () {
    final content = File('assets/files/3.txt').readAsStringSync();
    final verses = parseSurah(content, expectBasmala: true);
    expect(verses[0], equals('الم'));
    expect(verses[1], startsWith('اللَّهُ لَا إِلَـٰهَ'));
    expect(verses.length, equals(200));
  });

  test('Surah At-Tawbah (9.txt) has NO Basmala', () {
    final content = File('assets/files/9.txt').readAsStringSync();
    final verses = parseSurah(content, expectBasmala: false);
    expect(verses.first, startsWith('بَرَاءَةٌ مِّنَ اللَّهِ'));
    expect(verses.length, equals(129));
  });

  test('Surah Al-Ikhlas (112.txt) has Basmala on top, v1 is Qul Huwa Allahu Ahad', () {
    final content = File('assets/files/112.txt').readAsStringSync();
    final verses = parseSurah(content, expectBasmala: true);
    expect(verses[0], equals('قُلْ هُوَ اللَّهُ أَحَدٌ'));
    expect(verses.length, equals(4));
  });

  test('All 114 Surahs parse correctly without errors', () {
    for (int i = 1; i <= 114; i++) {
      final file = File('assets/files/$i.txt');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      final verses = parseSurah(content, expectBasmala: i != 9);
      expect(verses.isNotEmpty, isTrue, reason: 'File $i has no verses');
      expect(verses.first.contains('بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ'), isFalse,
          reason: 'File $i still has Basmala in verse 1: ${verses.first}');
    }
  });
}
