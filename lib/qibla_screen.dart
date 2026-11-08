import 'dart:async';
import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_device_compass/flutter_device_compass.dart';
import 'package:geomag/geomag.dart';
import 'package:geolocator/geolocator.dart';

import 'constans/theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const _ink = Color(0xFF26343B);
  static const _muted = Color(0xFF73817E);

  final Stream<CompassEvent>? _headingStream = FlutterCompass.eventsFor(
    CompassUpdateOptions.balanced,
  );
  late final Future<bool?> _compassAvailability;

  Position? _position;
  double? _qiblaBearing;
  double _magneticDeclination = 0;
  String? _locationError;
  _SettingsAction? _settingsAction;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _compassAvailability = _checkCompassAvailability();
    unawaited(_loadLocation());
  }

  Future<bool?> _checkCompassAvailability() async {
    try {
      return await FlutterCompass.hasSensors;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
      _settingsAction = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationError = 'شغّل خدمة الموقع على الجهاز عشان نحدد اتجاه القبلة.';
        _settingsAction = _SettingsAction.location;
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _locationError = 'إذن الموقع مرفوض نهائيًا. فعّله من إعدادات التطبيق.';
        _settingsAction = _SettingsAction.app;
        return;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _locationError = 'اسمح للتطبيق باستخدام موقعك لحساب اتجاه القبلة.';
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = position;
        _qiblaBearing = Qibla(
          Coordinates(position.latitude, position.longitude),
        ).direction;
        _magneticDeclination = GeoMag()
            .calculate(
              position.latitude,
              position.longitude,
              0,
              DateTime.now(),
            )
            .dec;
      });
    } catch (error) {
      _locationError = 'تعذر تحديد موقعك. تأكد من تشغيل GPS ثم حاول مرة أخرى.';
      debugPrint('Loading Qibla location failed: $error');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _openSettings() async {
    switch (_settingsAction) {
      case _SettingsAction.location:
        await Geolocator.openLocationSettings();
        return;
      case _SettingsAction.app:
        await Geolocator.openAppSettings();
        return;
      case null:
        await _loadLocation();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          title: const Text('اتجاه القبلة'),
          centerTitle: true,
          backgroundColor: palette.surface,
          foregroundColor: _ink,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingLocation) {
      return Center(
        child: CircularProgressIndicator(color: context.appPalette.primary),
      );
    }

    if (_locationError != null || _position == null || _qiblaBearing == null) {
      return _LocationError(
        message: _locationError ?? 'تعذر حساب اتجاه القبلة.',
        action: _settingsAction,
        onPressed: _openSettings,
      );
    }

    return FutureBuilder<bool?>(
      future: _compassAvailability,
      builder: (context, availability) {
        final hasCompass = availability.data == true;
        if (!hasCompass) {
          return _QiblaContent(
            position: _position!,
            bearing: _qiblaBearing!,
            magneticDeclination: _magneticDeclination,
            heading: null,
            sensorMessage: availability.connectionState == ConnectionState.waiting
                ? 'جاري التحقق من بوصلة الجهاز…'
                : 'البوصلة غير متاحة على هذا الجهاز؛ يمكنك معرفة اتجاه القبلة بالدرجات من الشمال.',
          );
        }

        final stream = _headingStream;
        if (stream == null) {
          return _QiblaContent(
            position: _position!,
            bearing: _qiblaBearing!,
            magneticDeclination: _magneticDeclination,
            heading: null,
            sensorMessage: 'تعذر تشغيل بوصلة الجهاز.',
          );
        }

        return StreamBuilder<CompassEvent>(
          stream: stream,
          builder: (context, snapshot) {
            final rawHeading = snapshot.data?.heading;
            final heading = rawHeading != null && rawHeading.isFinite
                ? rawHeading
                : null;
            final message = snapshot.hasError
                ? 'تعذر قراءة البوصلة. حرّك الجهاز بعيدًا عن المعادن والمغناطيس.'
                : heading == null
                ? 'حرّك الجهاز قليلًا للحصول على قراءة البوصلة.'
                : null;
            return _QiblaContent(
              position: _position!,
              bearing: _qiblaBearing!,
              magneticDeclination: _magneticDeclination,
              heading: heading,
              sensorMessage: message,
            );
          },
        );
      },
    );
  }
}

class _QiblaContent extends StatelessWidget {
  const _QiblaContent({
    required this.position,
    required this.bearing,
    required this.magneticDeclination,
    required this.heading,
    required this.sensorMessage,
  });

  final Position position;
  final double bearing;
  final double magneticDeclination;
  final double? heading;
  final String? sensorMessage;

  static const _ink = Color(0xFF26343B);
  static const _muted = Color(0xFF73817E);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final palette = context.appPalette;
        final size = math.max(
          120.0,
          math.min(320.0, constraints.maxWidth - 32),
        ).toDouble();
        final trueHeading = heading == null
            ? null
            : (heading! + magneticDeclination + 360) % 360;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            const Text(
              'وجّه الهاتف حتى يشير السهم إلى القبلة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.09),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE4ECE8)),
                ),
                child: AnimatedRotation(
                  turns: -(trueHeading ?? 0) / 360,
                  duration: const Duration(milliseconds: 180),
                  child: CustomPaint(
                    painter: _CompassRosePainter(
                      qiblaBearing: bearing,
                      primary: palette.primary,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: palette.soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'اتجاه القبلة ${_arabicDigits(bearing.round().toString())}° من الشمال',
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (heading != null) ...[
              const SizedBox(height: 8),
              Text(
                'اتجاه الهاتف بعد تصحيح الشمال: ${_arabicDigits(trueHeading!.round().toString())}°',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
            if (sensorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFAD7414)),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        sensorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF795A20),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5ECE9)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تم حساب الاتجاه حسب موقعك الحالي',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_arabicDigits(position.latitude.toStringAsFixed(3))}°، ${_arabicDigits(position.longitude.toStringAsFixed(3))}°',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LocationError extends StatelessWidget {
  const _LocationError({
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final String message;
  final _SettingsAction? action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = switch (action) {
      _SettingsAction.location => 'تشغيل الموقع',
      _SettingsAction.app => 'إعدادات التطبيق',
      null => 'إعادة المحاولة',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_searching_rounded,
              color: context.appPalette.primary,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF26343B),
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.settings_rounded),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: context.appPalette.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SettingsAction { location, app }

class _CompassRosePainter extends CustomPainter {
  const _CompassRosePainter({required this.qiblaBearing, required this.primary});

  final double qiblaBearing;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFF7FAF8),
    );
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = const Color(0xFFDCE8E2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tickPaint = Paint()
      ..color = const Color(0xFF9BADA4)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    for (var degree = 0; degree < 360; degree += 10) {
      final major = degree % 30 == 0;
      final angle = (degree - 90) * math.pi / 180;
      final outer = radius * 0.91;
      final inner = radius * (major ? 0.82 : 0.86);
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * inner, center.dy + math.sin(angle) * inner),
        Offset(center.dx + math.cos(angle) * outer, center.dy + math.sin(angle) * outer),
        tickPaint
          ..color = major ? const Color(0xFF71837C) : const Color(0xFFB7C5BF)
          ..strokeWidth = major ? 2 : 1,
      );
    }

    _drawLabel(canvas, 'شمال', Offset(center.dx, center.dy - radius * 0.68));
    _drawLabel(canvas, 'شرق', Offset(center.dx + radius * 0.68, center.dy));
    _drawLabel(canvas, 'جنوب', Offset(center.dx, center.dy + radius * 0.68));
    _drawLabel(canvas, 'غرب', Offset(center.dx - radius * 0.68, center.dy));

    final angle = (qiblaBearing - 90) * math.pi / 180;
    final direction = Offset(math.cos(angle), math.sin(angle));
    final perpendicular = Offset(-direction.dy, direction.dx);
    final tip = center + direction * (radius * 0.61);
    final tail = center - direction * (radius * 0.26);
    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..color = primary
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    final arrowBase = tip - direction * (radius * 0.15);
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        arrowBase.dx + perpendicular.dx * radius * 0.11,
        arrowBase.dy + perpendicular.dy * radius * 0.11,
      )
      ..lineTo(
        arrowBase.dx - perpendicular.dx * radius * 0.11,
        arrowBase.dy - perpendicular.dy * radius * 0.11,
      )
      ..close();
    canvas.drawPath(arrow, Paint()..color = primary);
    canvas.drawCircle(center, radius * 0.12, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius * 0.075, Paint()..color = primary);
  }

  void _drawLabel(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF52645C),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassRosePainter oldDelegate) =>
      oldDelegate.qiblaBearing != qiblaBearing || oldDelegate.primary != primary;
}

String _arabicDigits(String value) => value
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
