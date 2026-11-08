import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran_app/core/constants/app_colors.dart';
import 'package:quran_app/core/constants/surah_info.dart';
import 'package:quran_app/features/quran/data/quran_cache.dart';
// ---------------------------------------------------------------------------
class SurahOrnamentalHeader extends StatelessWidget {
  final SurahInfo info;

  const SurahOrnamentalHeader({required this.info, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // إطار زخرفي داخلي مزدوج
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // جهة اليمين: نوع السورة (مكية / مدنية)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '۞',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      info.type,
                      style: const TextStyle(
                        color: Appcolor.blackColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // الوسط: اسم السورة بخط بارز
                Text(
                  'سُورَةُ ${info.name}',
                  style: const TextStyle(
                    color: Appcolor.blackColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                // جهة اليسار: عدد الآيات
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'آياتها ${info.arabicTotalVerses}',
                      style: const TextStyle(
                        color: Appcolor.blackColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '۞',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ويدجت الصفحة الواحدة بكامل مساحة الشاشة
// ---------------------------------------------------------------------------
class QuranPageWidget extends StatelessWidget {
  final SurahPage page;
  final SurahInfo surahInfo;
  final String? basmala;
  final bool isFirstPage;

  const QuranPageWidget({
    required this.page,
    required this.surahInfo,
    this.basmala,
    this.isFirstPage = false,
  });

  /// تحويل رقم عربي-هندي  1 → ١
  static String toArabicDigits(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    // خط كبير وثابت، ويُستخدم قياسه نفسه عند تقسيم الصفحة والتلاوة
    final verseStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
      fontFamily: 'Amiri',
      fontSize: 26,
      height: 1.85,
      letterSpacing: 0,
    );

    final spans = <InlineSpan>[];
    final fragments = page.fragments.isNotEmpty
        ? page.fragments
        : <SurahPageFragment>[
            for (var i = 0; i < page.verses.length; i++)
              SurahPageFragment(
                verseNumber: page.startingVerseNumber + i,
                text: page.verses[i],
                endsVerse: true,
              ),
          ];

    for (final fragment in fragments) {
      spans.add(TextSpan(text: fragment.text));
      if (fragment.endsVerse) {
        spans.add(
          TextSpan(
            text: ' ﴿${toArabicDigits(fragment.verseNumber)}﴾ ',
            style: verseStyle.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontSize: (verseStyle.fontSize ?? 21) * 0.78,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }
    const pageGold = Color(0xFFB79A68);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pageGold.withValues(alpha: 0.75), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Appcolor.blackColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: pageGold.withValues(alpha: 0.28),
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // زخرفة بداية السورة (في الصفحة الأولى من كل سورة فقط كعنصر داخل الصفحة)
            if (isFirstPage) ...[
              SurahOrnamentalHeader(info: surahInfo),
              const SizedBox(height: 6),
            ],

            // البسملة (لجميع السور عدا التوبة)
            if (isFirstPage && basmala != null) ...[
              Text(
                basmala!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: verseStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 6),
              Divider(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                thickness: 1.2,
                indent: 45,
                endIndent: 45,
              ),
              const SizedBox(height: 10),
            ],

            // الآيات تستخدم كامل المساحة المتبقية وبخط واضح
            Expanded(
              child: SelectableText.rich(
                TextSpan(children: spans, style: verseStyle),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioProgressSlider extends StatelessWidget {
  const AudioProgressSlider({required this.player});

  final AudioPlayer player;

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds.toDouble();
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final value = maxMs <= 0
                ? 0.0
                : position.inMilliseconds.toDouble().clamp(0.0, maxMs);
            return Column(
              children: [
                Slider(
                  value: value,
                  max: maxMs > 0 ? maxMs : 1,
                  onChanged: maxMs <= 0
                      ? null
                      : (next) => unawaited(
                          player.seek(Duration(milliseconds: next.round())),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(duration)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
