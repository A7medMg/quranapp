import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:quran_app/features/dua/data/dua_library.dart';

class DuaTab extends StatefulWidget {
  const DuaTab({super.key, this.initialKind = 'dua'});

  final String initialKind;

  @override
  State<DuaTab> createState() => _DuaTabState();
}

class _DuaTabState extends State<DuaTab> {
  final _searchController = TextEditingController();
  List<DuaEntry> _entries = const [];
  late String _selectedKind;
  String _selectedCategory = 'all';
  String _query = '';
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _selectedKind = widget.initialKind;
    _loadEntries();
  }

  @override
  void didUpdateWidget(covariant DuaTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialKind != widget.initialKind) {
      setState(() {
        _selectedKind = widget.initialKind;
        _selectedCategory = 'all';
        _query = '';
        _searchController.clear();
      });
    }
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await DuaLibrary.load();
      if (mounted) setState(() => _entries = entries);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      .replaceAll('\u0640', '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final duasCount = _entries.where((entry) => entry.isDua).length;
    final adhkarCount = _entries.where((entry) => entry.isDhikr).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
                          Icons.auto_awesome_rounded,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الأدعية والأذكار',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loading
                                  ? 'جارٍ تحميل المكتبة'
                                  : '${_entries.length} نصًا من مصادر إسلامية',
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
                  const SizedBox(height: 14),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'dua',
                        icon: const Icon(Icons.volunteer_activism_rounded),
                        label: Text('الأدعية ($duasCount)'),
                      ),
                      ButtonSegment(
                        value: 'adhkar',
                        icon: const Icon(Icons.loop_rounded),
                        label: Text('الأذكار ($adhkarCount)'),
                      ),
                    ],
                    selected: {_selectedKind},
                    onSelectionChanged: (selection) => setState(() {
                      _selectedKind = selection.first;
                      _selectedCategory = 'all';
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: _selectedKind == 'adhkar'
                          ? 'ابحث في الأذكار أو المواقف'
                          : 'ابحث في الأدعية أو المواقف',
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
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ChoiceChip(
                          label: const Text('الكل'),
                          selected: _selectedCategory == 'all',
                          onSelected: (_) =>
                              setState(() => _selectedCategory = 'all'),
                        ),
                        const SizedBox(width: 8),
                        for (final category in _categories) ...[
                          ChoiceChip(
                            avatar: Icon(category.icon, size: 16),
                            label: Text(category.title),
                            selected: _selectedCategory == category.id,
                            onSelected: (_) => setState(
                              () => _selectedCategory = category.id,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildEntries(theme)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DuaCategory> get _categories => DuaLibrary.categoriesFor(
    _entries.where((entry) =>
      _selectedKind == 'adhkar' ? entry.isDhikr : entry.isDua,
    ),
  );

  Widget _buildEntries(ThemeData theme) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }
    if (_error != null) {
      return _Message(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل الأدعية والأذكار',
        message: 'أغلق الصفحة وافتحها مرة أخرى لإعادة المحاولة.',
        action: FilledButton.tonalIcon(
          onPressed: () {
            setState(() {
              _loading = true;
              _error = null;
            });
            _loadEntries();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      );
    }

    final query = _normalize(_query);
    final entries = _entries.where((entry) {
      final matchesKind = _selectedKind == 'adhkar'
          ? entry.isDhikr
          : entry.isDua;
      final matchesCategory =
          _selectedCategory == 'all' || entry.categoryTitle == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          _normalize(
            '${entry.title} ${entry.categoryTitle} ${entry.whenToSay} ${entry.text} ${entry.source}',
          ).contains(query);
      return matchesKind && matchesCategory && matchesQuery;
    }).toList(growable: false);

    if (entries.isEmpty) {
      return _Message(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج مطابقة',
        message: 'جرّب كلمة أخرى أو اختر موقفًا مختلفًا.',
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) => _DuaCard(entry: entries[index]),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({required this.entry});

  final DuaEntry entry;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: entry.text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('تم نسخ النص'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
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
                      entry.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (entry.whenToSay.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.whenToSay,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'نسخ النص',
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            entry.text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Amiri',
              fontSize: 22,
              height: 1.9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.source,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
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
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
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
