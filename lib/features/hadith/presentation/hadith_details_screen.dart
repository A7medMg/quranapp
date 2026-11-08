import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quran_app/features/hadith/data/hadith_cache.dart';
import 'package:quran_app/features/hadith/state/hadith_library_controller.dart';
import 'package:quran_app/features/hadith/widgets/item_hadith_details.dart';

enum _HadithAction { copy, share }

class HadithDetailsScreen extends StatelessWidget {
  const HadithDetailsScreen({super.key});

  static const String routeName = 'HadithDetailsScreen';

  @override
  Widget build(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final navigation = switch (routeArguments) {
      HadithNavigationArgs args => args,
      HadithData hadith => HadithNavigationArgs(
        hadiths: [hadith],
        initialIndex: 0,
      ),
      _ => const HadithNavigationArgs(hadiths: [], initialIndex: 0),
    };
    if (navigation.hadiths.isEmpty) {
      return const Scaffold(body: Center(child: Text('الحديث غير متاح')));
    }

    final startIndex = navigation.initialIndex
        .clamp(0, navigation.hadiths.length - 1)
        .toInt();
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbacklight.png',
              fit: BoxFit.cover,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                navigation.hadiths[startIndex].collection,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            body: ListView.separated(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 32),
              itemCount: navigation.hadiths.length - startIndex,
              itemBuilder: (context, visibleIndex) {
                final hadith = navigation.hadiths[startIndex + visibleIndex];
                return _HadithDetailCard(
                  key: ValueKey(hadith.id),
                  hadith: hadith,
                );
              },
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithDetailCard extends StatelessWidget {
  const _HadithDetailCard({required this.hadith, super.key});

  final HadithData hadith;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hadith.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hadith.referenceLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer<HadithLibraryController>(
                builder: (context, library, _) {
                  final favorite = library.isFavorite(hadith);
                  return IconButton(
                    tooltip: favorite
                        ? 'إزالة من المفضلة'
                        : 'إضافة للمفضلة',
                    onPressed: library.isLoaded
                        ? () => library.toggleFavorite(hadith)
                        : null,
                    icon: Icon(
                      favorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: favorite ? colors.primary : colors.outline,
                    ),
                  );
                },
              ),
              PopupMenuButton<_HadithAction>(
                tooltip: 'خيارات الحديث',
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _HadithAction.copy,
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded),
                        SizedBox(width: 10),
                        Text('نسخ الحديث'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _HadithAction.share,
                    child: Row(
                      children: [
                        Icon(Icons.ios_share_rounded),
                        SizedBox(width: 10),
                        Text('مشاركة الحديث'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ItemHadithDetails(content: hadith.content),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    _HadithAction action,
  ) async {
    try {
      switch (action) {
        case _HadithAction.copy:
          await Clipboard.setData(
            ClipboardData(text: '${hadith.referenceLabel}\n\n${hadith.content}'),
          );
          if (!context.mounted) return;
          _showMessage(context, 'تم نسخ الحديث');
          return;
        case _HadithAction.share:
          await Share.share(
            '${hadith.referenceLabel}\n\n${hadith.content}',
            subject: hadith.title,
          );
          return;
      }
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'تعذّر تنفيذ العملية، حاول مرة أخرى');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
