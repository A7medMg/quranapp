import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/features/quran/data/quran_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Save and retrieve page position for surah', () async {
    final initialPage = await QuranPreferences.getPagePosition(1);
    expect(initialPage, equals(0));

    await QuranPreferences.savePagePosition(
      surahIndex: 1,
      surahName: 'البقرة',
      pageIndex: 5,
    );

    final savedPage = await QuranPreferences.getPagePosition(1);
    expect(savedPage, equals(5));

    final lastRead = await QuranPreferences.getLastReadPosition();
    expect(lastRead, isNotNull);
    expect(lastRead!.surahIndex, equals(1));
    expect(lastRead.surahName, equals('البقرة'));
    expect(lastRead.pageIndex, equals(5));
  });

  test('Save and retrieve scroll position for surah (backward compatibility)',
      () async {
    final initial = await QuranPreferences.getScrollPosition(1);
    expect(initial, equals(0.0));

    await QuranPreferences.saveScrollPosition(
      surahIndex: 1,
      surahName: 'البقرة',
      scrollOffset: 1542.5,
    );

    final saved = await QuranPreferences.getScrollPosition(1);
    expect(saved, equals(1542.5));
  });

  test('Different surahs maintain separate positions', () async {
    await QuranPreferences.savePagePosition(
      surahIndex: 1,
      surahName: 'البقرة',
      pageIndex: 4,
    );
    await QuranPreferences.savePagePosition(
      surahIndex: 2,
      surahName: 'آل عمران',
      pageIndex: 2,
    );

    expect(await QuranPreferences.getPagePosition(1), equals(4));
    expect(await QuranPreferences.getPagePosition(2), equals(2));
  });
}
