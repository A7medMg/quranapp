import 'dart:async';

import 'package:flutter/material.dart';

import 'calendar_screen.dart';
import 'constans/surah_info.dart';
import 'constans/theme.dart';
import 'hadithtab.dart';
import 'qibla_screen.dart';
import 'qaurantab.dart';
import 'sebha_tab.dart';
import 'theme_picker_screen.dart';
import 'services/quran_preferences.dart';
import 'services/prayer_schedule_service.dart';
import 'surah_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = 'Home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _homeRefreshVersion = 0;

  void _openTab(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _homeRefreshVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: palette.primary,
          primaryContainer: palette.soft,
          secondary: palette.primary,
          surface: palette.surface,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: palette.background,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _HomeDashboard(
                key: ValueKey(_homeRefreshVersion),
                onOpenTab: _openTab,
              ),
              const Qaurantab(),
              const HadithTab(),
              const SebhaTab(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            height: 70,
            backgroundColor: palette.surface,
            indicatorColor: palette.soft,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _openTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'القرآن',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books_rounded),
                label: 'الحديث',
              ),
              NavigationDestination(
                icon: Icon(Icons.spa_outlined),
                selectedIcon: Icon(Icons.spa_rounded),
                label: 'التسبيح',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard>
    with WidgetsBindingObserver {
  static const _ink = Color(0xFF26343B);
  static const _muted = Color(0xFF73817E);

  late Future<Map<String, dynamic>?> _lastReadFuture;
  final PrayerScheduleService _prayerService = PrayerScheduleService.instance;
  Timer? _prayerClockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastReadFuture = QuranPreferences.getLastReadSurah();
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

  Future<void> _openLastRead(Map<String, dynamic>? lastRead) async {
    final index = lastRead?['index'] as int? ?? 0;
    final surahName = lastRead?['name'] as String? ??
        QuranMetadata.getByZeroIndex(index).name;

    await Navigator.of(context).pushNamed(
      SurahDetailsScreen.routeName,
      arguments: SurahdetailsArgs(
        surahName: surahName,
        index: index,
        startAtBeginning: lastRead == null,
      ),
    );
    if (!mounted) return;
    setState(() => _lastReadFuture = QuranPreferences.getLastReadSurah());
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
            const _WelcomeHeader(),
            const SizedBox(height: 16),
            TodayDateCard(onTap: () => _openCalendar(CalendarView.hijri)),
            const SizedBox(height: 16),
            _PrayerTimesStrip(
              service: _prayerService,
              onEnable: _prayerService.enablePrayerTimes,
            ),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'اختصارات'),
            const SizedBox(height: 10),
            _ShortcutGrid(
              onOpenTab: widget.onOpenTab,
              onOpenCalendar: _openCalendar,
              onOpenQibla: _openQibla,
              onOpenThemes: _openThemePicker,
              onComingSoon: _showComingSoon,
            ),
            const SizedBox(height: 18),
            FutureBuilder<Map<String, dynamic>?>(
              future: _lastReadFuture,
              builder: (context, snapshot) => _LastReadCard(
                loading: snapshot.connectionState == ConnectionState.waiting,
                lastRead: snapshot.data,
                onTap: () => _openLastRead(snapshot.data),
              ),
            ),
            const SizedBox(height: 18),
            _PrayerTrackerCard(service: _prayerService),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'السلام عليكم',
                style: TextStyle(
                  color: _HomeDashboardState._ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'ابدأ يومك بذكر الله وقراءة القرآن',
                style: TextStyle(
                  color: _HomeDashboardState._muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 21,
          backgroundColor: palette.soft,
          child: Icon(Icons.wb_sunny_outlined, color: palette.primary),
        ),
      ],
    );
  }
}

class _PrayerTimesStrip extends StatelessWidget {
  const _PrayerTimesStrip({required this.service, required this.onEnable});

  final PrayerScheduleService service;
  final VoidCallback onEnable;

  static const _items = [
    ('الفجر', Icons.wb_twilight_rounded, Color(0xFFF2B970)),
    ('الظهر', Icons.wb_sunny_rounded, Color(0xFF66BCE8)),
    ('العصر', Icons.cloud_rounded, Color(0xFFE6A660)),
    ('المغرب', Icons.nights_stay_rounded, Color(0xFFED8E6A)),
    ('العشاء', Icons.nightlight_round, Color(0xFF5FB79A)),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final palette = context.appPalette;
        final nextPrayer = service.nextPrayer;
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'مواقيت الصلاة',
                      style: TextStyle(
                        color: _HomeDashboardState._ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: service.isLoading ? null : onEnable,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: service.isLoading
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.location_on_outlined, size: 16),
                    label: Text(
                      service.isConfigured ? 'تحديث الموقع' : 'تفعيل الموقع',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  for (var index = 0; index < _items.length; index++)
                    Expanded(
                      child: _PrayerTimeCell(
                        name: _items[index].$1,
                        icon: _items[index].$2,
                        color: _items[index].$3,
                        entry: index < service.prayers.length
                            ? service.prayers[index]
                            : null,
                      ),
                    ),
                ],
              ),
              if (nextPrayer != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: palette.soft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: palette.primary,
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'الصلاة القادمة: ${nextPrayer.name}',
                          style: const TextStyle(
                            color: _HomeDashboardState._ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'بعد ${_remainingText(nextPrayer.nextOccurrence)}',
                        style: TextStyle(
                          color: palette.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (service.statusMessage != null) ...[
                const SizedBox(height: 7),
                Text(
                  service.statusMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _HomeDashboardState._muted,
                    fontSize: 10,
                  ),
                ),
                if (service.needsSystemSettings)
                  TextButton(
                    onPressed: () => service.openRelevantSettings(),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'فتح الإعدادات',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _remainingText(DateTime target) {
    final minutes = target.difference(DateTime.now()).inMinutes.clamp(0, 2880);
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours >= 24) return 'غدًا';
    if (hours == 0) return '${remainingMinutes}د';
    return '${hours}س ${remainingMinutes}د';
  }
}

class _PrayerTimeCell extends StatelessWidget {
  const _PrayerTimeCell({
    required this.name,
    required this.icon,
    required this.color,
    required this.entry,
  });

  final String name;
  final IconData icon;
  final Color color;
  final PrayerTimeEntry? entry;

  @override
  Widget build(BuildContext context) {
    final time = entry?.time;
    final timeLabel = time == null
        ? '—:—'
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final minutes = entry?.nextOccurrence.difference(DateTime.now()).inMinutes;
    final remaining = minutes == null
        ? '--'
        : minutes >= 1440
            ? 'غدًا'
            : minutes >= 60
                ? '${minutes ~/ 60}س ${minutes % 60}د'
                : '${minutes.clamp(0, 59)}د';

    return Column(
      children: [
        Text(
          name,
          maxLines: 1,
          style: const TextStyle(
            color: _HomeDashboardState._ink,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.72), color],
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          timeLabel,
          style: const TextStyle(
            color: _HomeDashboardState._ink,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          remaining,
          maxLines: 1,
          style: const TextStyle(
            color: _HomeDashboardState._muted,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _HomeDashboardState._ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({
    required this.onOpenTab,
    required this.onOpenCalendar,
    required this.onOpenQibla,
    required this.onOpenThemes,
    required this.onComingSoon,
  });

  final ValueChanged<int> onOpenTab;
  final ValueChanged<CalendarView> onOpenCalendar;
  final VoidCallback onOpenQibla;
  final VoidCallback onOpenThemes;
  final VoidCallback onComingSoon;

  static const _items = [
    _Shortcut('القرآن', Icons.menu_book_rounded, tabIndex: 1),
    _Shortcut('هجري', Icons.calendar_month_rounded, calendarView: CalendarView.hijri),
    _Shortcut('القبلة', Icons.explore_rounded, openQibla: true),
    _Shortcut('تسبيح', Icons.spa_rounded, tabIndex: 3),
    _Shortcut('دعاء', Icons.volunteer_activism_rounded),
    _Shortcut('حديث', Icons.auto_stories_rounded, tabIndex: 2),
    _Shortcut('الصلاة', Icons.mosque_rounded),
    _Shortcut('المظهر', Icons.palette_outlined, openThemes: true),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final item = _items[index];
        final palette = context.appPalette;
        return Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: item.tabIndex != null
                ? () => onOpenTab(item.tabIndex!)
                : item.calendarView != null
                ? () => onOpenCalendar(item.calendarView!)
                : item.openQibla
                ? onOpenQibla
                : item.openThemes
                ? onOpenThemes
                : onComingSoon,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: palette.primary, size: 21),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF43514E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Shortcut {
  const _Shortcut(
    this.label,
    this.icon, {
    this.tabIndex,
    this.calendarView,
    this.openQibla = false,
    this.openThemes = false,
  });

  final String label;
  final IconData icon;
  final int? tabIndex;
  final CalendarView? calendarView;
  final bool openQibla;
  final bool openThemes;
}

class _LastReadCard extends StatelessWidget {
  const _LastReadCard({
    required this.loading,
    required this.lastRead,
    required this.onTap,
  });

  final bool loading;
  final Map<String, dynamic>? lastRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final index = lastRead?['index'] as int? ?? 0;
    final surahName = lastRead?['name'] as String? ??
        QuranMetadata.getByZeroIndex(index).name;
    final savedPage = lastRead?['page'] as int?;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: loading ? null : onTap,
        child: Ink(
          height: 142,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [palette.gradientStart, palette.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              const Positioned(
                left: -20,
                bottom: -46,
                child: CircleAvatar(
                  radius: 92,
                  backgroundColor: Color(0x22FFFFFF),
                ),
              ),
              Positioned(
                left: 22,
                bottom: 12,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 88,
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'آخر قراءة',
                      style: TextStyle(
                        color: Color(0xDFFFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      loading ? '...' : 'سورة $surahName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      savedPage == null
                          ? 'ابدأ القراءة من أول السورة'
                          : 'صفحة ${savedPage + 1}',
                      style: const TextStyle(
                        color: Color(0xEFFFFFFF),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'متابعة القراءة',
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: palette.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerTrackerCard extends StatelessWidget {
  const _PrayerTrackerCard({required this.service});

  final PrayerScheduleService service;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final palette = context.appPalette;
        final completed = service.completed;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'متابعة الصلاة',
                      style: TextStyle(
                        color: _HomeDashboardState._ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${completed.where((done) => done).length}/${PrayerScheduleService.prayerNames.length}',
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'تُحدّث العلامة تلقائيًا بعد مرور 15 دقيقة على الصلاة',
                style: TextStyle(
                  color: _HomeDashboardState._muted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  for (var index = 0;
                      index < PrayerScheduleService.prayerNames.length;
                      index++)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          service.togglePrayer(index);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            children: [
                              Icon(
                                completed[index]
                                    ? Icons.check_circle_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: completed[index]
                                    ? palette.primary
                                    : const Color(0xFFB7C1BE),
                                size: 22,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                PrayerScheduleService.prayerNames[index],
                                style: const TextStyle(
                                  color: _HomeDashboardState._ink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
