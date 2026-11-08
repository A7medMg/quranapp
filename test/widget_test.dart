import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/home_screen.dart';
import 'package:quran_app/main.dart';
import 'package:quran_app/surah_details_screen.dart';

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

  testWidgets('App opens SurahDetailsScreen directly when lastRead is present',
      (tester) async {
    await tester.pumpWidget(
      const MyApp(
        lastRead: {'index': 1, 'name': 'البقرة'},
      ),
    );
    await tester.pump();

    expect(find.byType(SurahDetailsScreen), findsOneWidget);
  });
}
