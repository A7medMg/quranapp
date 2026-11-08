import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class PrayerTimeEntry {
  const PrayerTimeEntry({
    required this.name,
    required this.time,
    required this.nextOccurrence,
  });

  final String name;
  final DateTime time;
  final DateTime nextOccurrence;
}

class PrayerScheduleService extends ChangeNotifier {
  PrayerScheduleService._();

  static final PrayerScheduleService instance = PrayerScheduleService._();

  static const _latitudeKey = 'prayer_location_latitude';
  static const _longitudeKey = 'prayer_location_longitude';
  static const _notificationsEnabledKey = 'prayer_notifications_enabled';
  static const _adhanEnabledKey = 'adhan_notifications_enabled';
  static const _prayerReminderEnabledKey = 'prayer_reminders_enabled';
  static const _prayerReminderMinutesKey = 'prayer_reminder_minutes';
  static const _dhikrRemindersEnabledKey = 'dhikr_reminders_enabled';
  static const _dhikrReminderIntervalKey = 'dhikr_reminder_interval_hours';
  static const _notificationIdBase = 1000000;
  static const _notificationIdRange = 1000000;
  static const _scheduledDays = 10;
  static const _prayerReminderIdBase = 2000000;
  static const _dhikrReminderIdBase = 3500000;
  static const _dhikrStartHour = 8;
  static const _dhikrEndHour = 22;

  static const prayerNames = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<PrayerTimeEntry> prayers = const [];
  List<bool> completed = List<bool>.filled(5, false);
  PrayerTimeEntry? nextPrayer;
  PrayerTimeEntry? duhaTime;
  bool isConfigured = false;
  bool isLoading = true;
  bool notificationsEnabled = false;
  bool needsNotificationSettings = false;
  bool adhanNotificationsEnabled = true;
  bool prayerRemindersEnabled = true;
  int prayerReminderMinutes = 10;
  bool dhikrRemindersEnabled = true;
  int dhikrReminderIntervalHours = 2;
  bool exactNotificationsEnabled = false;
  bool needsSystemSettings = false;
  String? statusMessage;

  double? _latitude;
  double? _longitude;
  bool _initialized = false;
  bool _timezoneReady = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _initializePlatformServices();
      final preferences = await SharedPreferences.getInstance();
      _latitude = preferences.getDouble(_latitudeKey);
      _longitude = preferences.getDouble(_longitudeKey);
      notificationsEnabled =
          preferences.getBool(_notificationsEnabledKey) ?? false;
      adhanNotificationsEnabled =
          preferences.getBool(_adhanEnabledKey) ?? true;
      prayerRemindersEnabled =
          preferences.getBool(_prayerReminderEnabledKey) ?? true;
      prayerReminderMinutes =
          preferences.getInt(_prayerReminderMinutesKey) ?? 10;
      dhikrRemindersEnabled =
          preferences.getBool(_dhikrRemindersEnabledKey) ?? true;
      dhikrReminderIntervalHours =
          preferences.getInt(_dhikrReminderIntervalKey) ?? 2;
      await _readNotificationPermissions();
      isConfigured = _latitude != null && _longitude != null;
      if (isConfigured) {
        await _refreshPrayerData(scheduleNotifications: true);
        statusMessage = notificationsEnabled
            ? 'مواقيت الصلاة حسب موقعك المحفوظ.'
            : 'المواقيت جاهزة. اضغط تحديث الموقع لتفعيل التنبيهات.';
        notifyListeners();
      } else {
        isLoading = false;
        statusMessage = 'فعّل موقعك لعرض مواقيت الصلاة.';
        if (notificationsEnabled && dhikrRemindersEnabled && _timezoneReady) {
          await _scheduleNotifications(DateTime.now());
        }
        notifyListeners();
      }
    } catch (error) {
      _initialized = false;
      isLoading = false;
      statusMessage = 'تعذر تجهيز مواقيت الصلاة. حاول مرة أخرى.';
      debugPrint('Prayer schedule initialization failed: $error');
      notifyListeners();
    }
  }

  Future<void> _initializePlatformServices() async {
    timezone_data.initializeTimeZones();
    final timezoneName = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(timezoneName));
    _timezoneReady = true;

    if (!_isAndroid && !_isIOS) return;

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<void> _readNotificationPermissions() async {
    if (_isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      notificationsEnabled =
          await android?.areNotificationsEnabled() ?? notificationsEnabled;
      needsNotificationSettings = !notificationsEnabled;
      exactNotificationsEnabled =
          await android?.canScheduleExactNotifications() ?? true;
    } else if (_isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final permissions = await ios?.checkPermissions();
      if (permissions != null) {
        notificationsEnabled = permissions.isEnabled;
        needsNotificationSettings = !notificationsEnabled;
        exactNotificationsEnabled = permissions.isEnabled;
      }
    }
  }

  Future<void> openRelevantSettings() async {
    if (!needsSystemSettings) return;
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> openNotificationSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> enablePrayerTimes() async {
    if (!_initialized) await initialize();
    if (isLoading) return;

    isLoading = true;
    statusMessage = null;
    notifyListeners();

    try {
      needsSystemSettings = false;
      if (!await Geolocator.isLocationServiceEnabled()) {
        statusMessage = 'فعّل خدمة الموقع في الجهاز ثم حاول مرة أخرى.';
        needsSystemSettings = true;
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        statusMessage = 'إذن الموقع مرفوض. اسمح به لعرض المواقيت.';
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        statusMessage = 'إذن الموقع مرفوض نهائيًا. فعّله من إعدادات التطبيق.';
        needsSystemSettings = true;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
      isConfigured = true;

      final preferences = await SharedPreferences.getInstance();
      await preferences.setDouble(_latitudeKey, position.latitude);
      await preferences.setDouble(_longitudeKey, position.longitude);

      await _requestNotificationPermissions();
      await preferences.setBool(
        _notificationsEnabledKey,
        notificationsEnabled,
      );
      await _refreshPrayerData(scheduleNotifications: notificationsEnabled);
      if (!notificationsEnabled) {
        statusMessage =
            'المواقيت جاهزة، لكن إذن الإشعارات غير مفعّل على الجهاز.';
      } else if (!exactNotificationsEnabled && _isAndroid) {
        statusMessage =
            'المواقيت جاهزة. قد يتأخر التنبيه قليلًا لأن التنبيه الدقيق غير مفعّل.';
      } else {
        statusMessage = 'تم تفعيل المواقيت والتنبيهات حسب موقعك.';
      }
    } catch (error) {
      statusMessage =
          'تعذر تحديد الموقع. تأكد من تشغيل GPS واتصال خدمات الموقع.';
      debugPrint('Enabling prayer times failed: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _requestNotificationPermissions() async {
    if (_isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final notificationPermission =
          await android?.requestNotificationsPermission();
      notificationsEnabled = notificationPermission != false;

      if (!notificationsEnabled) {
        needsNotificationSettings = true;
        exactNotificationsEnabled = false;
        needsSystemSettings = true;
        return;
      }

      final canScheduleExactly =
          await android?.canScheduleExactNotifications() ?? true;
      exactNotificationsEnabled = canScheduleExactly ||
          (await android?.requestExactAlarmsPermission() ?? false);
      needsNotificationSettings = false;
      return;
    }

    if (_isIOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      notificationsEnabled =
          await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
              false;
      exactNotificationsEnabled = notificationsEnabled;
      needsSystemSettings = !notificationsEnabled;
      needsNotificationSettings = !notificationsEnabled;
      return;
    }

    notificationsEnabled = false;
    needsNotificationSettings = true;
    exactNotificationsEnabled = false;
  }

  Future<bool> _requestNotificationAccess() async {
    if (!_initialized) await initialize();
    if (!_timezoneReady) return false;
    if (notificationsEnabled) return true;

    if (_isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final permission = await android?.requestNotificationsPermission();
      notificationsEnabled = permission != false;
      exactNotificationsEnabled =
          await android?.canScheduleExactNotifications() ?? true;
    } else if (_isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      notificationsEnabled =
          await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
              false;
      exactNotificationsEnabled = notificationsEnabled;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsEnabledKey, notificationsEnabled);
    needsSystemSettings = !notificationsEnabled;
    needsNotificationSettings = !notificationsEnabled;
    notifyListeners();
    return notificationsEnabled;
  }

  Future<void> setPrayerRemindersEnabled(bool enabled) async {
    if (enabled && !await _requestNotificationAccess()) return;
    prayerRemindersEnabled = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_prayerReminderEnabledKey, enabled);
    await _refreshNotificationSchedule();
  }

  Future<void> setAdhanNotificationsEnabled(bool enabled) async {
    if (enabled && !await _requestNotificationAccess()) return;
    adhanNotificationsEnabled = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_adhanEnabledKey, enabled);
    await _refreshNotificationSchedule();
  }

  Future<void> setPrayerReminderMinutes(int minutes) async {
    if (![5, 10, 15, 30].contains(minutes)) return;
    prayerReminderMinutes = minutes;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_prayerReminderMinutesKey, minutes);
    await _refreshNotificationSchedule();
  }

  Future<void> setDhikrRemindersEnabled(bool enabled) async {
    if (enabled && !await _requestNotificationAccess()) return;
    dhikrRemindersEnabled = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_dhikrRemindersEnabledKey, enabled);
    await _refreshNotificationSchedule();
  }

  Future<void> setDhikrReminderIntervalHours(int hours) async {
    if (![2, 3, 4].contains(hours)) return;
    dhikrReminderIntervalHours = hours;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_dhikrReminderIntervalKey, hours);
    await _refreshNotificationSchedule();
  }

  Future<void> _refreshNotificationSchedule() async {
    if (!_timezoneReady) return;
    if (isConfigured && notificationsEnabled) {
      await _refreshPrayerData(scheduleNotifications: true);
    } else if (notificationsEnabled) {
      await _scheduleNotifications(DateTime.now());
      notifyListeners();
    } else {
      await _cancelScheduledNotifications();
      notifyListeners();
    }
  }

  Future<void> refreshClock() async {
    if (!isConfigured || _latitude == null || _longitude == null) return;
    try {
      await _refreshPrayerData(scheduleNotifications: false);
    } catch (error) {
      debugPrint('Refreshing prayer times failed: $error');
    }
  }

  Future<void> onAppResumed() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(timezoneName));
      _timezoneReady = true;
      await _readNotificationPermissions();
      needsSystemSettings = !notificationsEnabled;
      if (isConfigured && _latitude != null && _longitude != null) {
        await _refreshPrayerData(scheduleNotifications: notificationsEnabled);
        statusMessage = !notificationsEnabled
            ? 'المواقيت جاهزة، لكن الإشعارات متوقفة من إعدادات الجهاز.'
            : _isAndroid && !exactNotificationsEnabled
                ? 'التنبيهات مفعلة، وقد يتأخر وقت وصولها قليلًا.'
                : 'مواقيت الصلاة حسب موقعك المحفوظ.';
      } else {
        if (notificationsEnabled) await _scheduleNotifications(DateTime.now());
        statusMessage = notificationsEnabled
            ? 'فعّل موقعك لعرض مواقيت الصلاة.'
            : 'الإشعارات متوقفة من إعدادات الجهاز.';
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Refreshing prayer schedule failed: $error');
    }
  }

  Future<void> _refreshPrayerData({required bool scheduleNotifications}) async {
    if (_latitude == null || _longitude == null) return;

    final now = DateTime.now();
    final today = _calculatePrayerTimes(now);
    final tomorrow = _calculatePrayerTimes(_calendarDateAfter(now, 1));
    prayers = [
      for (var index = 0; index < prayerNames.length; index++)
        PrayerTimeEntry(
          name: prayerNames[index],
          time: today[index],
          nextOccurrence:
              today[index].isAfter(now) ? today[index] : tomorrow[index],
        ),
    ];

    final todayDuha = _calculateDuhaTime(now);
    final tomorrowDuha = _calculateDuhaTime(_calendarDateAfter(now, 1));
    duhaTime = PrayerTimeEntry(
      name: 'الضحى',
      time: todayDuha,
      nextOccurrence: todayDuha.isAfter(now) ? todayDuha : tomorrowDuha,
    );

    final upcomingToday = today.where((time) => time.isAfter(now));
    final nextTime = upcomingToday.isNotEmpty ? upcomingToday.first : tomorrow[0];
    final nextIndex = upcomingToday.isNotEmpty ? today.indexOf(nextTime) : 0;
    nextPrayer = PrayerTimeEntry(
      name: prayerNames[nextIndex],
      time: nextTime,
      nextOccurrence: nextTime,
    );

    await _refreshCompletion(today, now);
    if (scheduleNotifications && notificationsEnabled && _timezoneReady) {
      await _scheduleNotifications(now);
    }
    isLoading = false;
    notifyListeners();
  }

  List<DateTime> _calculatePrayerTimes(DateTime date) {
    final times = _calculateTimesForDate(date);
    return [times.fajr, times.dhuhr, times.asr, times.maghrib, times.isha]
        .map(
          (time) => DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
            time.second,
          ),
        )
        .toList(growable: false);
  }

  DateTime _calculateDuhaTime(DateTime date) {
    final sunrise = _calculateTimesForDate(date).sunrise;
    return DateTime(
      date.year,
      date.month,
      date.day,
      sunrise.hour,
      sunrise.minute,
      sunrise.second,
    ).add(const Duration(minutes: 25));
  }

  PrayerTimes _calculateTimesForDate(DateTime date) {
    final localNoon = DateTime(date.year, date.month, date.day, 12);
    final calculationParameters =
        CalculationMethod.egyptian.getParameters()..madhab = Madhab.shafi;
    return PrayerTimes(
      Coordinates(_latitude!, _longitude!),
      DateComponents.from(localNoon),
      calculationParameters,
      utcOffset: localNoon.timeZoneOffset,
    );
  }

  DateTime _calendarDateAfter(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days, 12);

  Future<void> _refreshCompletion(List<DateTime> today, DateTime now) async {
    final preferences = await SharedPreferences.getInstance();
    final storageKey = _trackerStorageKey(now);
    final saved = preferences.getStringList(storageKey);
    final updated = saved == null || saved.length != prayerNames.length
        ? List<bool>.filled(prayerNames.length, false)
        : saved.map((value) => value == '1').toList();

    var changed = false;
    for (var index = 0; index < today.length; index++) {
      if (!updated[index] && !now.isBefore(today[index].add(
        const Duration(minutes: 15),
      ))) {
        updated[index] = true;
        changed = true;
      }
    }

    completed = updated;
    if (changed || saved == null || saved.length != prayerNames.length) {
      await _saveCompletion(preferences, storageKey, updated);
    }
  }

  Future<void> togglePrayer(int index) async {
    if (index < 0 || index >= prayerNames.length) return;
    final updated = List<bool>.of(completed);
    updated[index] = !updated[index];
    completed = updated;
    final now = DateTime.now();
    final preferences = await SharedPreferences.getInstance();
    await _saveCompletion(
      preferences,
      _trackerStorageKey(now),
      updated,
    );
    notifyListeners();
  }

  Future<void> _saveCompletion(
    SharedPreferences preferences,
    String key,
    List<bool> values,
  ) async {
    await preferences.setStringList(
      key,
      values.map((value) => value ? '1' : '0').toList(growable: false),
    );
  }

  String _trackerStorageKey(DateTime date) =>
      'prayer_tracker_${date.year}_${date.month}_${date.day}';

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _scheduleNotifications(DateTime now) async {
    await _cancelScheduledNotifications();
    if (!notificationsEnabled || !_timezoneReady) return;

    if (_latitude != null && _longitude != null) {
      // Keep iOS under its 64 pending-request limit, including daily adhkar.
      final daysToSchedule = _isIOS ? 5 : _scheduledDays;
      for (var dayOffset = 0; dayOffset < daysToSchedule; dayOffset++) {
        final date = _calendarDateAfter(now, dayOffset);
        final times = _calculatePrayerTimes(date);
        for (var index = 0; index < times.length; index++) {
          final time = times[index];
          if (!time.isAfter(now)) continue;

          final dayNumber = DateTime.utc(
            time.year,
            time.month,
            time.day,
          ).difference(DateTime.utc(2000)).inDays;
          final notificationId =
              _notificationIdBase + (dayNumber * prayerNames.length) + index;

          if (adhanNotificationsEnabled) {
            await _notifications.zonedSchedule(
              id: notificationId,
              title: 'حان الآن وقت صلاة ${prayerNames[index]}',
              body: 'حي على الصلاة، حي على الفلاح',
              scheduledDate: _zonedTime(time),
              notificationDetails: _adhanNotificationDetails,
              androidScheduleMode: _scheduleMode,
              payload: 'prayer:${time.year}-${time.month}-${time.day}:$index',
            );
          }

          if (prayerRemindersEnabled) {
            final reminderTime =
                time.subtract(Duration(minutes: prayerReminderMinutes));
            if (reminderTime.isAfter(now)) {
              await _notifications.zonedSchedule(
                id: _prayerReminderIdBase +
                    (dayNumber * prayerNames.length) +
                    index,
                title: 'اقترب وقت صلاة ${prayerNames[index]}',
                body: 'باقي $prayerReminderMinutes دقيقة على موعد الصلاة.',
                scheduledDate: _zonedTime(reminderTime),
                notificationDetails: _reminderNotificationDetails,
                androidScheduleMode: _scheduleMode,
                payload:
                    'prayer-reminder:${time.year}-${time.month}-${time.day}:$index',
              );
            }
          }
        }
      }
    }

    if (dhikrRemindersEnabled) await _scheduleDhikrNotifications(now);
  }

  Future<void> _scheduleDhikrNotifications(DateTime now) async {
    var index = 0;
    for (
      var hour = _dhikrStartHour;
      hour <= _dhikrEndHour;
      hour += dhikrReminderIntervalHours
    ) {
      var date = timezone.TZDateTime(
        timezone.local,
        now.year,
        now.month,
        now.day,
        hour,
      );
      if (!date.isAfter(timezone.TZDateTime.from(now, timezone.local))) {
        date = date.add(const Duration(days: 1));
      }

      final dhikr = _reminderAdhkar[index % _reminderAdhkar.length];
      await _notifications.zonedSchedule(
        id: _dhikrReminderIdBase + index,
        title: 'تذكير بذكر الله',
        body: dhikr,
        scheduledDate: date,
        notificationDetails: _dhikrNotificationDetails,
        androidScheduleMode: _scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'dhikr:$index',
      );
      index++;
    }
  }

  timezone.TZDateTime _zonedTime(DateTime time) => timezone.TZDateTime(
    timezone.local,
    time.year,
    time.month,
    time.day,
    time.hour,
    time.minute,
    time.second,
  );

  AndroidScheduleMode get _scheduleMode => exactNotificationsEnabled
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  NotificationDetails get _adhanNotificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_adhan_channel_v2',
      'تنبيهات الصلاة',
      channelDescription: 'تنبيه عند دخول وقت كل صلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  NotificationDetails get _reminderNotificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_reminder_channel_v1',
      'التنبيه قبل الصلاة',
      channelDescription: 'تذكير صوتي قبل دخول وقت الصلاة',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  NotificationDetails get _dhikrNotificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'dhikr_reminder_channel_v1',
      'تذكير الأذكار',
      channelDescription: 'تذكير صوتي دوري بالأذكار',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static const _reminderAdhkar = [
    'صلِّ على النبي ﷺ',
    'فاذكروني أذكركم',
    'سبحان الله وبحمده',
    'أستغفر الله وأتوب إليه',
    'لا إله إلا الله وحده لا شريك له',
  ];

  Future<void> _cancelScheduledNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= _notificationIdBase &&
          request.id < _notificationIdBase + _notificationIdRange * 3) {
        await _notifications.cancel(id: request.id);
      }
    }
  }
}
