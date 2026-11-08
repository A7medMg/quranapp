import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hijri_date/hijri.dart';

import 'constans/theme.dart';

enum CalendarView { hijri, gregorian }

class TodayDateCard extends StatelessWidget {
  const TodayDateCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return _DateSummaryCard(
      date: today,
      title: 'التاريخ الهجري اليوم',
      onTap: onTap,
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.initialView = CalendarView.hijri,
  });

  final CalendarView initialView;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _ink = Color(0xFF26343B);
  static const _muted = Color(0xFF73817E);
  static const _weekdaysGregorian = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];
  static const _weekdaysHijri = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];
  static const _gregorianMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  late CalendarView _view;
  late DateTime _focusedDate;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    HijriDate.setLocal('ar');
    _view = widget.initialView;
    _focusedDate = _dateOnly(DateTime.now());
    _selectedDate = _focusedDate;
  }

  void _changeMonth(int amount) {
    if (!_canNavigate(amount)) return;
    setState(() {
      if (_view == CalendarView.gregorian) {
        final month = DateTime(_focusedDate.year, _focusedDate.month + amount, 1);
        final lastDay = DateTime(month.year, month.month + 1, 0).day;
        final day = math.min(_selectedDate.day, lastDay);
        _focusedDate = DateTime(month.year, month.month, day);
      } else {
        final current = HijriDate.fromDate(_focusedDate);
        final firstOfMonth = HijriDate.fromHijri(
          current.hYear,
          current.hMonth,
          1,
        );
        final targetMonth = firstOfMonth.addMonths(amount);
        final day = math.min(current.hDay, targetMonth.lengthOfMonth);
        final hijriDate = HijriDate.fromHijri(
          targetMonth.hYear,
          targetMonth.hMonth,
          day,
        );
        _focusedDate = hijriDate.hijriToGregorian(
          hijriDate.hYear,
          hijriDate.hMonth,
          hijriDate.hDay,
        );
      }
      _selectedDate = _dateOnly(_focusedDate);
    });
  }

  bool _canNavigate(int amount) {
    if (_view == CalendarView.hijri) {
      final hijri = HijriDate.fromDate(_focusedDate);
      if (amount < 0) return hijri.hYear > 1356 || hijri.hMonth > 1;
      return hijri.hYear < 1500 || hijri.hMonth < 12;
    }

    final targetMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month + amount,
      1,
    );
    final targetLastDay = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
      0,
    );
    return !targetLastDay.isBefore(_minimumHijriDate) &&
        !targetMonth.isAfter(_maximumHijriDate);
  }

  DateTime get _minimumHijriDate {
    final first = HijriDate.fromHijri(1356, 1, 1);
    return _dateOnly(first.hijriToGregorian(1356, 1, 1));
  }

  DateTime get _maximumHijriDate {
    final lastMonth = HijriDate.fromHijri(1500, 12, 1);
    return _dateOnly(
      lastMonth.hijriToGregorian(1500, 12, lastMonth.lengthOfMonth),
    );
  }

  bool _isWithinHijriRange(DateTime date) {
    final day = _dateOnly(date);
    return !day.isBefore(_minimumHijriDate) &&
        !day.isAfter(_maximumHijriDate);
  }

  void _selectView(CalendarView view) {
    setState(() {
      _view = view;
      _focusedDate = _dateOnly(_selectedDate);
    });
  }

  void _jumpToToday() {
    final today = _dateOnly(DateTime.now());
    setState(() {
      _focusedDate = today;
      _selectedDate = today;
    });
  }

  DateTime _dateForCell(int day) {
    if (_view == CalendarView.gregorian) {
      return DateTime(_focusedDate.year, _focusedDate.month, day);
    }
    final current = HijriDate.fromDate(_focusedDate);
    final date = HijriDate.fromHijri(current.hYear, current.hMonth, day);
    return date.hijriToGregorian(date.hYear, date.hMonth, date.hDay);
  }

  int get _monthLength {
    if (_view == CalendarView.gregorian) {
      return DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    }
    return HijriDate.fromDate(_focusedDate).lengthOfMonth;
  }

  int get _firstWeekdayOffset {
    if (_view == CalendarView.gregorian) {
      return DateTime(_focusedDate.year, _focusedDate.month, 1).weekday % 7;
    }
    final hijri = HijriDate.fromDate(_focusedDate);
    final firstGregorian = HijriDate.fromHijri(
      hijri.hYear,
      hijri.hMonth,
      1,
    ).hijriToGregorian(hijri.hYear, hijri.hMonth, 1);
    // The Hijri month grid starts on Saturday.
    return (firstGregorian.weekday + 1) % 7;
  }

  String get _monthTitle {
    if (_view == CalendarView.gregorian) {
      return '${_gregorianMonths[_focusedDate.month - 1]} ${_arabicDigits(_focusedDate.year)}';
    }
    final hijri = HijriDate.fromDate(_focusedDate);
    return '${hijri.getLongMonthName()} ${_arabicDigits(hijri.hYear)} هـ';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final firstWeekdayOffset = _firstWeekdayOffset;
    final monthLength = _monthLength;
    final cellCount = ((firstWeekdayOffset + monthLength + 6) ~/ 7) * 7;
    final weekdays = _view == CalendarView.hijri
        ? _weekdaysHijri
        : _weekdaysGregorian;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          title: const Text('التقويم'),
          centerTitle: true,
          backgroundColor: palette.surface,
          foregroundColor: _ink,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _DateSummaryCard(
              date: _selectedDate,
              title: _sameDate(_selectedDate, DateTime.now())
                  ? 'التاريخ الهجري اليوم'
                  : 'التاريخ المحدد',
            ),
            const SizedBox(height: 16),
            SegmentedButton<CalendarView>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: CalendarView.hijri,
                  icon: Icon(Icons.nights_stay_outlined),
                  label: Text('هجري'),
                ),
                ButtonSegment(
                  value: CalendarView.gregorian,
                  icon: Icon(Icons.calendar_month_outlined),
                  label: Text('ميلادي'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (selection) => _selectView(selection.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: palette.soft,
                selectedForegroundColor: palette.primary,
                foregroundColor: _muted,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE5ECE9)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'الشهر السابق',
                        onPressed: _canNavigate(-1)
                            ? () => _changeMonth(-1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _monthTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'الشهر التالي',
                        onPressed: _canNavigate(1)
                            ? () => _changeMonth(1)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      TextButton(onPressed: _jumpToToday, child: const Text('اليوم')),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (final weekday in weekdays)
                        Expanded(
                          child: Center(
                            child: Text(
                              weekday,
                              maxLines: 1,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cellCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 3,
                          childAspectRatio: 0.82,
                        ),
                    itemBuilder: (context, index) {
                      final day = index - firstWeekdayOffset + 1;
                      if (day < 1 || day > monthLength) {
                        return const SizedBox.shrink();
                      }

                      final date = _dateOnly(_dateForCell(day));
                      if (!_isWithinHijriRange(date)) {
                        return Center(
                          child: Text(
                            _arabicDigits(day),
                            style: const TextStyle(
                              color: Color(0xFFCAD2CF),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      final selected = _sameDate(date, _selectedDate);
                      final today = _sameDate(date, DateTime.now());
                      final hijri = HijriDate.fromDate(date);
                      final primary = _view == CalendarView.hijri
                          ? hijri.hDay
                          : date.day;
                      final secondary = _view == CalendarView.hijri
                          ? date.day
                          : hijri.hDay;

                      return Material(
                        color: selected ? palette.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () => setState(() {
                            _selectedDate = date;
                            _focusedDate = date;
                          }),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _arabicDigits(primary),
                                style: TextStyle(
                                  color: selected ? Colors.white : _ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _arabicDigits(secondary),
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white70
                                      : _muted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (today && !selected)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: palette.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'الرقم الكبير هو التاريخ المختار، والرقم الصغير يوضح التاريخ المقابل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSummaryCard extends StatelessWidget {
  const _DateSummaryCard({
    required this.date,
    required this.title,
    this.onTap,
  });

  final DateTime date;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    HijriDate.setLocal('ar');
    final hijri = HijriDate.fromDate(date);
    final weekday = _arabicWeekday(date.weekday);
    final hijriLabel =
        '${_arabicDigits(hijri.hDay)} ${hijri.getLongMonthName()} ${_arabicDigits(hijri.hYear)} هـ';
    final gregorianLabel =
        '$weekday، ${_arabicDigits(date.day)} ${_arabicGregorianMonths[date.month - 1]} ${_arabicDigits(date.year)} م';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.gradientStart, palette.gradientEnd],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hijriLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gregorianLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _arabicGregorianMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String _arabicWeekday(int weekday) {
  const names = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  return names[weekday - 1];
}

String _arabicDigits(int value) => value
    .toString()
    .replaceAll('0', '٠')
    .replaceAll('1', '١')
    .replaceAll('2', '٢')
    .replaceAll('3', '٣')
    .replaceAll('4', '٤')
    .replaceAll('5', '٥')
    .replaceAll('6', '٦')
    .replaceAll('7', '٧')
    .replaceAll('8', '٨')
    .replaceAll('9', '٩');

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
