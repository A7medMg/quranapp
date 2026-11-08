import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quran_app/features/sebha/state/sebha_controller.dart';

class SebhaTab extends StatefulWidget {
  const SebhaTab({super.key});

  @override
  State<SebhaTab> createState() => _SebhaTabState();
}

class _SebhaTabState extends State<SebhaTab> {
  double _angle = 0;

  void _increment(SebhaController controller) {
    if (!controller.isLoaded) return;
    setState(() => _angle += 0.18);
    controller.increment();
  }

  Future<void> _confirmReset(SebhaController controller) async {
    if (controller.selectedCount == 0) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تصفير العداد'),
        content: Text('هل تريد تصفير عداد «${controller.selectedDhikr.text}»؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );

    if (!mounted || shouldReset != true) return;
    controller.resetSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SebhaController>(
      builder: (context, controller, _) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.spa_rounded,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المسبحة الإلكترونية',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'اختر الذكر، ولكل ذكر عدّاده الخاص',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'اختر الذكر',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.dhikrs.length,
                          itemBuilder: (context, index) {
                            final dhikr = controller.dhikrs[index];
                            final selected =
                                dhikr.id == controller.selectedDhikrId;
                            return ChoiceChip(
                              avatar: CircleAvatar(
                                radius: 11,
                                backgroundColor: selected
                                    ? colors.primary
                                    : colors.primaryContainer,
                                child: Text(
                                  '${controller.countFor(dhikr.id)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: selected
                                        ? colors.onPrimary
                                        : colors.onPrimaryContainer,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              label: Text(dhikr.text),
                              selected: selected,
                              onSelected: controller.isLoaded
                                  ? (_) => controller.selectDhikr(dhikr.id)
                                  : null,
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              controller.selectedDhikr.text,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontFamily: 'Amiri',
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              controller.isLoaded
                                  ? 'العدد الحالي'
                                  : 'جارٍ تحميل العدّادات...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${controller.selectedCount}',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 250,
                              height: 250,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: controller.isLoaded
                                          ? () => _increment(controller)
                                          : null,
                                      child: Transform.rotate(
                                        angle: _angle,
                                        child: Image.asset(
                                          'assets/images/body of seb7a.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IgnorePointer(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.touch_app_rounded,
                                          color: colors.primary,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'اضغط للعدّ',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    child: Image.asset(
                                      'assets/images/head of seb7a.png',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.contain,
                                      excludeFromSemantics: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: controller.isLoaded
                                  ? () => _confirmReset(controller)
                                  : null,
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('تصفير عدّاد هذا الذكر'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
