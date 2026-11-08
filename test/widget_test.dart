import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/features/home/presentation/home_screen.dart';
import 'package:quran_app/main.dart';
import 'package:quran_app/features/quran/presentation/surah_details_screen.dart';
import 'package:quran_app/features/quran/models/surah_details_args.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App opens HomeScreen when no lastRead is set', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SurahDetailsScreen), findsNothing);
  });

  testWidgets('The Quran route opens from the app', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final homeContext = tester.element(find.byType(HomeScreen));
    Navigator.of(homeContext).pushNamed(
      SurahDetailsScreen.routeName,
      arguments: const SurahDetailsArgs(surahName: 'البقرة', index: 1),
    );
    await tester.pump();

    expect(find.byType(SurahDetailsScreen), findsOneWidget);
  });
}
