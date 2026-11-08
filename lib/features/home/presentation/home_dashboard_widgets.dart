import 'package:flutter/material.dart';
import 'package:quran_app/core/constants/surah_info.dart';
import 'package:quran_app/core/theme/app_theme.dart';
import 'package:quran_app/features/calendar/presentation/calendar_screen.dart';
import 'package:quran_app/features/prayer/data/prayer_schedule_service.dart';
import 'package:quran_app/features/quran/models/quran_reading_position.dart';

const _dashboardInk = Color(0xFF26343B);
const _dashboardMuted = Color(0xFF73817E);
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader();

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
                  color: _dashboardInk,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'ابدأ يومك بذكر الله وقراءة القرآن',
                style: TextStyle(
                  color: _dashboardMuted,
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

class PrayerTimesStrip extends StatelessWidget {
  const PrayerTimesStrip({required this.service, required this.onEnable});

  final PrayerScheduleService service;
  final VoidCallback onEnable;

  static const _items = [
    ('الفجر', Icons.wb_twilight_rounded, Color(0xFFF2B970)),
    ('الضحى', Icons.wb_sunny_outlined, Color(0xFFE9B85B)),
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
                        color: _dashboardInk,
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
                        entry: _entryForName(_items[index].$1, service),
                      ),
                    ),
                ],
              ),
              if (service.duhaTime != null) ...[
                const SizedBox(height: 4),
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'يبدأ وقت الضحى بعد الشروق بنحو 25 دقيقة',
                    style: TextStyle(
                      color: _dashboardMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
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
                            color: _dashboardInk,
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
                    color: _dashboardMuted,
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

  static PrayerTimeEntry? _entryForName(
    String name,
    PrayerScheduleService service,
  ) {
    if (name == 'الضحى') return service.duhaTime;
    for (final prayer in service.prayers) {
      if (prayer.name == name) return prayer;
    }
    return null;
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
            color: _dashboardInk,
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
            color: _dashboardInk,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          remaining,
          maxLines: 1,
          style: const TextStyle(
            color: _dashboardMuted,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _dashboardInk,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class ShortcutGrid extends StatelessWidget {
  const ShortcutGrid({
    required this.onOpenTab,
    required this.onOpenAdhkar,
    required this.onOpenPrayer,
    required this.onOpenCalendar,
    required this.onOpenQibla,
    required this.onOpenThemes,
    required this.onComingSoon,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenAdhkar;
  final VoidCallback onOpenPrayer;
  final ValueChanged<CalendarView> onOpenCalendar;
  final VoidCallback onOpenQibla;
  final VoidCallback onOpenThemes;
  final VoidCallback onComingSoon;

  static const _items = [
    _Shortcut('القرآن', Icons.menu_book_rounded, tabIndex: 1),
    _Shortcut('هجري', Icons.calendar_month_rounded, calendarView: CalendarView.hijri),
    _Shortcut('القبلة', Icons.explore_rounded, openQibla: true),
    _Shortcut('دعاء', Icons.volunteer_activism_rounded, tabIndex: 3),
    _Shortcut('الأذكار', Icons.auto_awesome_rounded, openAdhkar: true),
    _Shortcut('تسبيح', Icons.spa_rounded, tabIndex: 4),
    _Shortcut('حديث', Icons.auto_stories_rounded, tabIndex: 2),
    _Shortcut('الصلاة', Icons.mosque_rounded, openPrayer: true),
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
                : item.openAdhkar
                ? onOpenAdhkar
                : item.openPrayer
                ? onOpenPrayer
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
    this.openAdhkar = false,
    this.openPrayer = false,
    this.calendarView,
    this.openQibla = false,
    this.openThemes = false,
  });

  final String label;
  final IconData icon;
  final int? tabIndex;
  final bool openAdhkar;
  final bool openPrayer;
  final CalendarView? calendarView;
  final bool openQibla;
  final bool openThemes;
}

class LastReadCard extends StatelessWidget {
  const LastReadCard({
    required this.loading,
    required this.lastRead,
    required this.onTap,
  });

  final bool loading;
  final QuranReadingPosition? lastRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final index = lastRead?.surahIndex ?? 0;
    final surahName = lastRead?.surahName ??
        QuranMetadata.getByZeroIndex(index).name;
    final savedPage = lastRead?.pageIndex;

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

class PrayerNotificationSettingsCard extends StatelessWidget {
  const PrayerNotificationSettingsCard({required this.service});

  final PrayerScheduleService service;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(Icons.notifications_active_outlined,
                color: palette.primary),
            title: const Text(
              'إعدادات التنبيهات',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('الأذان والتذكير بالصلاة والأذكار'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('أذان الصلاة'),
                subtitle: const Text('إشعار بصوت الأذان عند دخول الوقت'),
                value: service.adhanNotificationsEnabled,
                onChanged: service.isLoading
                    ? null
                    : service.setAdhanNotificationsEnabled,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('تنبيه قبل الصلاة'),
                subtitle: const Text('تنبيه صوتي قبل دخول وقت الصلاة'),
                value: service.prayerRemindersEnabled,
                onChanged: service.isLoading
                    ? null
                    : service.setPrayerRemindersEnabled,
              ),
              if (service.prayerRemindersEnabled)
                _ReminderIntervalRow(
                  label: 'قبل موعد الصلاة',
                  value: service.prayerReminderMinutes,
                  values: const [5, 10, 15, 30],
                  suffix: 'دقيقة',
                  onChanged: service.setPrayerReminderMinutes,
                ),
              const Divider(height: 18),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('تذكير بالأذكار'),
                subtitle: const Text('من 8 صباحًا إلى 10 مساءً'),
                value: service.dhikrRemindersEnabled,
                onChanged: service.isLoading
                    ? null
                    : service.setDhikrRemindersEnabled,
              ),
              if (service.dhikrRemindersEnabled)
                _ReminderIntervalRow(
                  label: 'التكرار',
                  value: service.dhikrReminderIntervalHours,
                  values: const [2, 3, 4],
                  suffix: 'ساعات',
                  onChanged: service.setDhikrReminderIntervalHours,
                ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'صوت الأذان منفصل عن صوت إشعارات التذكير.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _dashboardMuted, fontSize: 11),
                ),
              ),
              if (service.needsNotificationSettings)
                TextButton.icon(
                  onPressed: service.openNotificationSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('فتح إعدادات الإشعارات'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderIntervalRow extends StatelessWidget {
  const _ReminderIntervalRow({
    required this.label,
    required this.value,
    required this.values,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> values;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          DropdownButton<int>(
            value: value,
            isDense: true,
            items: [
              for (final option in values)
                DropdownMenuItem(
                  value: option,
                  child: Text('$option $suffix'),
                ),
            ],
            onChanged: (nextValue) {
              if (nextValue != null) onChanged(nextValue);
            },
          ),
        ],
      ),
    );
  }
}

class PrayerTrackerCard extends StatelessWidget {
  const PrayerTrackerCard({required this.service});

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
                        color: _dashboardInk,
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
                  color: _dashboardMuted,
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
                                  color: _dashboardInk,
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
