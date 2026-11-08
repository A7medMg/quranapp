import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quran_app/features/hadith/data/hadith_cache.dart';
import 'package:quran_app/features/hadith/presentation/hadith_details_screen.dart';
import 'package:quran_app/features/hadith/state/hadith_library_controller.dart';
import 'package:quran_app/features/hadith/widgets/item_hadith_name.dart';

class HadithTab extends StatefulWidget {
  const HadithTab({super.key});

  @override
  State<HadithTab> createState() => _HadithTabState();
}

class _HadithTabState extends State<HadithTab> {
  final _searchController = TextEditingController();
  List<HadithData> _hadiths = [];
  String _query = '';
  String _selectedCollection = 'صحيح مسلم';
  bool _loaded = false;
  bool _favoritesOnly = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths({String? collection}) async {
    final targetCollection = collection ?? _selectedCollection;
    final sourceCollection = targetCollection == 'صحيح البخاري'
        ? 'صحيح البخاري'
        : 'صحيح مسلم';
    try {
      final hadiths = await HadithCache.instance.getHadiths(
        collection: sourceCollection,
      );
      if (mounted && targetCollection == _selectedCollection) {
        setState(() => _hadiths = hadiths);
      }
    } catch (error) {
      if (mounted && targetCollection == _selectedCollection) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted && targetCollection == _selectedCollection) {
        setState(() => _loaded = true);
      }
    }
  }

  void _selectCollection(String collection) {
    if (_selectedCollection == collection) return;
    setState(() {
      _selectedCollection = collection;
      _hadiths = const [];
      _loaded = false;
      _error = null;
    });
    _loadHadiths(collection: collection);
  }
  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      .replaceAll('\u0640', '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .trim();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme, palette),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'ابحث في اسم الكتاب أو نص الحديث',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح البحث',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: palette.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('صحيح البخاري'),
                          selected: _selectedCollection == 'صحيح البخاري',
                          onSelected: (_) => _selectCollection('صحيح البخاري'),
                        ),
                        ChoiceChip(
                          label: const Text('صحيح مسلم'),
                          selected: _selectedCollection == 'صحيح مسلم',
                          onSelected: (_) => _selectCollection('صحيح مسلم'),
                        ),
                        ChoiceChip(
                          label: const Text('مختارات سابقة'),
                          selected: _selectedCollection == 'مختارات سابقة',
                          onSelected: (_) => _selectCollection('مختارات سابقة'),
                        ),
                        FilterChip(
                          avatar: Icon(
                            _favoritesOnly
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 18,
                          ),
                          label: const Text('المفضلة فقط'),
                          selected: _favoritesOnly,
                          onSelected: (value) =>
                              setState(() => _favoritesOnly = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(child: _buildList(theme)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.menu_book_rounded, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مكتبة الأحاديث',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'تصفح صحيح مسلم وصحيح البخاري وابحث في النصوص',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Consumer<HadithLibraryController>(
          builder: (context, library, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  library.isLoaded ? '${library.favoriteCount}' : '…',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'مفضلة',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(ThemeData theme) {
    if (!_loaded && _error == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_error != null) {
      return _HadithMessage(
        icon: Icons.wifi_off_rounded,
        title: 'تعذّر تحميل الأحاديث',
        message: 'حاول تحميل القائمة مرة أخرى.',
        action: FilledButton.tonalIcon(
          onPressed: () {
            setState(() {
              _loaded = false;
              _error = null;
            });
            _loadHadiths();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      );
    }

    return Consumer<HadithLibraryController>(
      builder: (context, library, _) {
        final query = _normalize(_query);
        final collectionHadiths = _hadiths
            .where((hadith) => hadith.collection == _selectedCollection)
            .toList(growable: false);
        final filtered = collectionHadiths.where((hadith) {
          final matchesQuery =
              query.isEmpty || hadith.searchText.contains(query);
          final matchesFavorite =
              !_favoritesOnly || library.isFavorite(hadith);
          return matchesQuery && matchesFavorite;
        }).toList(growable: false);

        if (filtered.isEmpty) {
          final collectionHasFavorites =
              collectionHadiths.any(library.isFavorite);
          final hasNoFavorites = _favoritesOnly &&
              query.isEmpty &&
              !collectionHasFavorites;
          return _HadithMessage(
            icon: hasNoFavorites
                ? Icons.star_border_rounded
                : Icons.search_off_rounded,
            title: hasNoFavorites
                ? 'قائمة المفضلة فارغة'
                : _query.isEmpty && !_favoritesOnly
                    ? 'لا توجد أحاديث متاحة'
                    : 'لا توجد نتائج مطابقة',
            message: hasNoFavorites
                ? 'اضغط على علامة النجمة بجانب أي حديث لإضافته هنا.'
                : _query.isNotEmpty
                    ? 'جرّب كلمة أخرى أو ابحث بجزء من نص الحديث.'
                    : 'غيّر التصفية لعرض الأحاديث.',
          );
        }

        return Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${filtered.length} حديث',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final hadith = filtered[index];
                  return Itemhadithname(
                    hadithData: hadith,
                    onOpen: () {
                      final initialIndex = collectionHadiths.indexWhere(
                        (item) => item.id == hadith.id,
                      );
                      Navigator.of(context).pushNamed(
                        HadithDetailsScreen.routeName,
                        arguments: HadithNavigationArgs(
                          hadiths: collectionHadiths,
                          initialIndex: initialIndex < 0 ? 0 : initialIndex,
                        ),
                      );
                    },
                    isFavorite: library.isFavorite(hadith),
                    onToggleFavorite: library.isLoaded
                        ? () => library.toggleFavorite(hadith)
                        : null,
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HadithMessage extends StatelessWidget {
  const _HadithMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
