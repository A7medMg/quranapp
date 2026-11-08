import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/core/constants/surah_info.dart';
import 'package:quran_app/features/calendar/presentation/calendar_screen.dart';
import 'package:quran_app/features/home/presentation/home_dashboard_widgets.dart';
import 'package:quran_app/features/prayer/data/prayer_schedule_service.dart';
import 'package:quran_app/features/prayer/presentation/prayer_screen.dart';
import 'package:quran_app/features/qibla/presentation/qibla_screen.dart';
import 'package:quran_app/features/quran/models/quran_reading_position.dart';
import 'package:quran_app/features/quran/models/surah_details_args.dart';
import 'package:quran_app/features/quran/presentation/surah_details_screen.dart';
import 'package:quran_app/features/quran/state/quran_reading_controller.dart';
import 'package:quran_app/features/settings/presentation/theme_picker_screen.dart';
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.onOpenTab,
    required this.onOpenAdhkar,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenAdhkar;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with WidgetsBindingObserver {
  late final PrayerScheduleService _prayerService;
  Timer? _prayerClockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prayerService = context.read<PrayerScheduleService>();
    unawaited(_prayerService.initialize());
    _prayerClockTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_prayerService.refreshClock()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_prayerService.onAppResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prayerClockTimer?.cancel();
    super.dispose();
  }

  Future<void> _openLastRead(QuranReadingPosition? lastRead) async {
    final index = lastRead?.surahIndex ?? 0;
    final surahName = lastRead?.surahName ??
        QuranMetadata.getByZeroIndex(index).name;

    await Navigator.of(context).pushNamed(
      SurahDetailsScreen.routeName,
      arguments: SurahDetailsArgs(
        surahName: surahName,
        index: index,
        startAtBeginning: lastRead == null,
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('الخدمة دي لسه مش متاحة في التطبيق')),
      );
  }

  void _openCalendar(CalendarView view) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CalendarScreen(initialView: view),
      ),
    );
  }

  void _openQibla() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QiblaScreen()),
    );
  }

  void _openPrayer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrayerScreen(service: _prayerService),
      ),
    );
  }

  void _openThemePicker() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ThemePickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            const WelcomeHeader(),
            const SizedBox(height: 16),
            TodayDateCard(onTap: () => _openCalendar(CalendarView.hijri)),
            const SizedBox(height: 16),
            PrayerTimesStrip(
              service: _prayerService,
              onEnable: _prayerService.enablePrayerTimes,
            ),
            const SizedBox(height: 10),
            PrayerNotificationSettingsCard(service: _prayerService),
            const SizedBox(height: 18),
            const SectionHeading(title: 'اختصارات'),
            const SizedBox(height: 10),
            ShortcutGrid(
              onOpenTab: widget.onOpenTab,
              onOpenAdhkar: widget.onOpenAdhkar,
              onOpenPrayer: _openPrayer,
              onOpenCalendar: _openCalendar,
              onOpenQibla: _openQibla,
              onOpenThemes: _openThemePicker,
              onComingSoon: _showComingSoon,
            ),
            const SizedBox(height: 18),
            Selector<
                QuranReadingController,
                (bool, QuranReadingPosition?)>(
              selector: (_, controller) =>
                  (controller.isLoaded, controller.lastRead),
              builder: (context, state, _) => LastReadCard(
                loading: !state.$1,
                lastRead: state.$2,
                onTap: () => _openLastRead(state.$2),
              ),
            ),
            const SizedBox(height: 18),
            PrayerTrackerCard(service: _prayerService),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
