import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_app/core/theme/app_theme.dart';
import 'package:quran_app/features/home/presentation/home_dashboard_widgets.dart';
import 'package:quran_app/features/prayer/data/prayer_schedule_service.dart';

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({required this.service, super.key});

  final PrayerScheduleService service;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          title: const Text('صلاتي'),
          backgroundColor: palette.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: AnimatedBuilder(
          animation: service,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              const _PageIntro(),
              const SizedBox(height: 18),
              if (service.isConfigured && service.nextPrayer != null)
                _NextPrayerCard(entry: service.nextPrayer!)
              else
                _LocationCard(service: service),
              if (service.isConfigured) ...[
                if (service.statusMessage != null) ...[
                  const SizedBox(height: 8),
                  _StatusMessage(message: service.statusMessage!),
                ],
                const SizedBox(height: 22),
                const _SectionTitle(
                  title: 'مواقيت اليوم',
                  subtitle: 'مواعيد الصلوات ووقت الضحى',
                ),
                const SizedBox(height: 11),
                _PrayerSchedule(entries: service.prayers, duha: service.duhaTime,
                    nextPrayer: service.nextPrayer),
                const SizedBox(height: 22),
                const _SectionTitle(
                  title: 'متابعة صلوات اليوم',
                  subtitle: 'تظهر العلامة تلقائيًا بعد 15 دقيقة، ويمكنك تعديلها يدويًا',
                ),
                const SizedBox(height: 11),
                PrayerTrackerCard(service: service),
              ],
              const SizedBox(height: 22),
              const _SectionTitle(
                title: 'التنبيهات والتذكير',
                subtitle: 'تحكم في الأذان والتنبيه قبل الصلاة والأذكار',
              ),
              const SizedBox(height: 11),
              PrayerNotificationSettingsCard(service: service),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.mosque_rounded, color: palette.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'صلاتك على وقتها',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'مواقيتك ومتابعتك وتنبيهاتك في مكان واحد',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF73817E),
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({required this.entry});

  final PrayerTimeEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [palette.gradientStart, palette.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: Colors.white70, size: 19),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'الصلاة القادمة',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              Text(
                _formatTime(entry.time),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            entry.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'متبقي ${_remainingText(entry.nextOccurrence)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.service});

  final PrayerScheduleService service;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.location_on_outlined, size: 34, color: palette.primary),
          const SizedBox(height: 9),
          Text(
            service.isLoading ? 'بنجهز مواقيت الصلاة' : 'فعّل موقعك للمواقيت',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'هنحسب المواعيد حسب مكانك، وتقدر تفعّل التنبيهات من نفس الصفحة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF73817E), fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: service.isLoading ? null : service.enablePrayerTimes,
            icon: service.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(service.isLoading ? 'لحظة واحدة' : 'تفعيل الموقع والمواقيت'),
          ),
          if (service.statusMessage != null) ...[
            const SizedBox(height: 9),
            _StatusMessage(message: service.statusMessage!),
          ],
          if (service.needsSystemSettings)
            TextButton.icon(
              onPressed: service.openRelevantSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('فتح إعدادات الجهاز'),
            ),
        ],
      ),
    );
  }
}

class _PrayerSchedule extends StatelessWidget {
  const _PrayerSchedule({
    required this.entries,
    required this.duha,
    required this.nextPrayer,
  });

  final List<PrayerTimeEntry> entries;
  final PrayerTimeEntry? duha;
  final PrayerTimeEntry? nextPrayer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 2;
        final gap = 10.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final allEntries = <PrayerTimeEntry>[
          if (entries.isNotEmpty) entries.first,
          if (duha != null) duha!,
          if (entries.length > 1) ...entries.skip(1),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final entry in allEntries)
              SizedBox(
                width: itemWidth,
                child: _PrayerTimeTile(
                  entry: entry,
                  isNext: _isNextOccurrence(entry, nextPrayer),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _isNextOccurrence(PrayerTimeEntry entry, PrayerTimeEntry? next) =>
      next != null &&
      entry.name == next.name &&
      entry.nextOccurrence.isAtSameMomentAs(next.nextOccurrence);
}

class _PrayerTimeTile extends StatelessWidget {
  const _PrayerTimeTile({required this.entry, required this.isNext});

  final PrayerTimeEntry entry;
  final bool isNext;

  static const _icons = <String, IconData>{
    'الفجر': Icons.wb_twilight_rounded,
    'الظهر': Icons.wb_sunny_rounded,
    'العصر': Icons.cloud_rounded,
    'المغرب': Icons.nights_stay_rounded,
    'العشاء': Icons.nightlight_round,
    'الضحى': Icons.wb_sunny_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNext ? palette.soft : palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isNext ? palette.primary.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isNext ? palette.primary : palette.soft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _icons[entry.name] ?? Icons.access_time_rounded,
              color: isNext ? Colors.white : palette.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (entry.name == 'الضحى')
                  const Text(
                    'بعد الشروق بنحو 25 دقيقة',
                    style: TextStyle(fontSize: 10, color: Color(0xFF73817E)),
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(entry.time),
            style: TextStyle(
              color: palette.primary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF73817E),
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.primary, fontSize: 12),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'ص' : 'م'}';
}

String _remainingText(DateTime target) {
  final remaining = target.difference(DateTime.now());
  final totalMinutes = math.max(0, remaining.inMinutes);
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours >= 24) {
    final days = hours ~/ 24;
    final leftoverHours = hours % 24;
    return '$days يوم و$leftoverHours ساعة';
  }
  if (hours == 0) return '$minutes دقيقة';
  return '$hours ساعة و$minutes دقيقة';
}
