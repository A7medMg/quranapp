import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'package:quran_app/core/constants/surah_info.dart';
import 'package:quran_app/features/quran/models/surah_details_args.dart';
import 'package:quran_app/features/quran/presentation/page_image_crop_screen.dart';
import 'package:quran_app/features/quran/data/quran_cache.dart';
import 'package:quran_app/features/quran/data/quran_preferences.dart';
import 'package:quran_app/features/quran/services/quran_audio_service.dart';
import 'package:quran_app/features/quran/state/quran_reading_controller.dart';
import 'package:quran_app/features/quran/widgets/quran_page_widgets.dart';

class SurahDetailsScreen extends StatefulWidget {
  const SurahDetailsScreen({super.key});

  static const String routeName = 'surahDetailsScreen';

  @override
  State<SurahDetailsScreen> createState() => _SurahDetailsScreenState();
}

class _SurahDetailsScreenState extends State<SurahDetailsScreen> {
  int _currentSurahIndex = 0;
  String _currentSurahName = '';
  SurahData? _data;
  SurahData? _prevData;
  SurahData? _nextData;
  List<SurahPage> _pages = const [];
  List<SurahPage> _prevPages = const [];
  List<SurahPage> _nextPages = const [];
  Object? _error;

  PageController? _pageController;
  bool _isTransitioningSurah = false;
  int _currentPageIndex = 0;
  final Map<int, GlobalKey> _pageCaptureKeys = {};
  static final LinkedHashMap<(SurahData, String), List<SurahPage>>
      _paginationCache = LinkedHashMap();
  int _loadRequestId = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPreparingAudio = false;
  String? _audioLabel;
  bool _isPlayingPageAudio = false;
  int _audioRequestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null && _error == null) {
      final args =
          ModalRoute.of(context)!.settings.arguments as SurahDetailsArgs;
      _currentSurahIndex = args.index;
      _currentSurahName = args.surahName;
      _initSurah(args.index, targetPage: args.startAtBeginning ? 0 : null);
    }
  }

  /// يعرض السورة المطلوبة أولاً، ثم يجهز السورتين المجاورتين بالخلفية.
  Future<void> _initSurah(int surahIndex, {int? targetPage}) async {
    final requestId = ++_loadRequestId;
    if (_isPlayingPageAudio || _isPreparingAudio) {
      unawaited(_stopAudio());
    }
    try {
      final results = await Future.wait([
        QuranCache.instance.getSurah(surahIndex),
        targetPage != null
            ? Future.value(targetPage)
            : QuranPreferences.getPagePosition(surahIndex),
      ]);

      final data = results[0] as SurahData;
      final savedPage = results[1] as int;
      if (!mounted || requestId != _loadRequestId) return;

      final pages = _paginateForScreen(data);

      if (mounted) {
        final totalPages = pages.length;
        final pageInSurah = savedPage.clamp(
          0,
          totalPages > 0 ? totalPages - 1 : 0,
        );

        final hasPrev = surahIndex > 0;
        final prevOffset = hasPrev ? 1 : 0;
        final initialControllerPage = prevOffset + pageInSurah;

        _pageController?.dispose();
        _pageController = PageController(
          initialPage: initialControllerPage,
          keepPage: false,
        );

        setState(() {
          _currentSurahIndex = surahIndex;
          _currentSurahName = QuranMetadata.getByZeroIndex(surahIndex).name;
          _data = data;
          _prevData = null;
          _nextData = null;
          _pages = pages;
          _prevPages = const [];
          _nextPages = const [];
          _currentPageIndex = initialControllerPage;
          _pageCaptureKeys.clear();
          _isTransitioningSurah = false;
        });

        unawaited(context.read<QuranReadingController>().savePagePosition(
          surahIndex: _currentSurahIndex,
          surahName: _currentSurahName,
          pageIndex: pageInSurah,
        ));
        unawaited(_loadAdjacentSurahs(surahIndex, requestId));
      }
    } catch (e) {
      if (mounted && requestId == _loadRequestId) {
        setState(() {
          _error = e;
          _isTransitioningSurah = false;
        });
      }
    }
  }

  Future<void> _loadAdjacentSurahs(int surahIndex, int requestId) async {
    try {
      final previous = surahIndex > 0
          ? QuranCache.instance.getSurah(surahIndex - 1)
          : Future<SurahData?>.value(null);
      final next = surahIndex < 113
          ? QuranCache.instance.getSurah(surahIndex + 1)
          : Future<SurahData?>.value(null);
      final adjacent = await Future.wait<SurahData?>([previous, next]);

      // اترك أول صفحة تظهر قبل قياس صفحات السور المجاورة على واجهة المستخدم.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || requestId != _loadRequestId) return;

      final previousData = adjacent[0];
      final nextData = adjacent[1];
      final previousPages = previousData == null
          ? const <SurahPage>[]
          : _paginateForScreen(previousData);
      final nextPages = nextData == null
          ? const <SurahPage>[]
          : _paginateForScreen(nextData);

      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _prevData = previousData;
        _nextData = nextData;
        _prevPages = previousPages;
        _nextPages = nextPages;
      });
    } catch (_) {
      // Neighbor pages remain available as loading placeholders if prefetch fails.
    }
  }

  /// تقسيم الآيات حسب مساحة الصفحة الظاهرة على الجهاز، مع الاحتفاظ بالآيات
  /// كاملة قدر الإمكان وربط كل صفحة بآياتها المستخدمة في التلاوة.
  List<SurahPage> _paginateForScreen(SurahData data) {
    final screen = MediaQuery.sizeOf(context);
    final safeArea = MediaQuery.paddingOf(context);
    final viewportKey = '${screen.width}x${screen.height}:${safeArea.vertical}';
    final cacheKey = (data, viewportKey);
    final cachedPages = _paginationCache.remove(cacheKey);
    if (cachedPages != null) {
      _paginationCache[cacheKey] = cachedPages;
      return cachedPages;
    }

    final pageHeight = screen.height - safeArea.vertical - 48;
    final textWidth = (screen.width - 50)
        .clamp(120.0, double.infinity)
        .toDouble();
    const verseStyle = TextStyle(
      fontFamily: 'Amiri',
      fontSize: 26,
      height: 1.85,
    );

    double measureHeight(List<SurahPageFragment> fragments) {
      final spans = <InlineSpan>[];
      for (final fragment in fragments) {
        spans.add(TextSpan(text: fragment.text));
        if (fragment.endsVerse) {
          spans.add(
            TextSpan(
              text:
                  ' ﴿${QuranPageWidget.toArabicDigits(fragment.verseNumber)}﴾ ',
              style: verseStyle.copyWith(
                fontSize: verseStyle.fontSize! * 0.78,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      }

      final painter = TextPainter(
        text: TextSpan(children: spans, style: verseStyle),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      )..layout(maxWidth: textWidth);
      return painter.height;
    }

    final pages = <SurahPage>[];
    var pageFragments = <SurahPageFragment>[];

    void finishPage() {
      if (pageFragments.isEmpty) return;
      pages.add(
        SurahPage(
          pageIndex: pages.length,
          startingVerseNumber: pageFragments.first.verseNumber,
          verses: List.unmodifiable(
            pageFragments.map((fragment) => fragment.text),
          ),
          fragments: List.unmodifiable(pageFragments),
        ),
      );
      pageFragments = <SurahPageFragment>[];
    }

    for (var verseIndex = 0; verseIndex < data.verses.length; verseIndex++) {
      final verseNumber = verseIndex + 1;
      final words = RegExp(r'\S+\s*')
          .allMatches(data.verses[verseIndex])
          .map((match) => match.group(0)!)
          .toList();
      final wholeVerse = SurahPageFragment(
        verseNumber: verseNumber,
        text: data.verses[verseIndex],
        endsVerse: true,
      );

      final reservedHeight = pages.isEmpty
          ? (data.basmala == null ? 110.0 : 180.0)
          : 50.0;
      if (measureHeight([...pageFragments, wholeVerse]) <=
          pageHeight - reservedHeight) {
        pageFragments.add(wholeVerse);
        continue;
      }

      var wordStart = 0;
      while (wordStart < words.length) {
        final availableTextHeight =
            pageHeight - (pages.isEmpty
                ? (data.basmala == null ? 110.0 : 180.0)
                : 50.0);
        var low = 1;
        var high = words.length - wordStart;
        var bestFit = 0;

        while (low <= high) {
          final count = (low + high) ~/ 2;
          final end = wordStart + count;
          final fragment = SurahPageFragment(
            verseNumber: verseNumber,
            text: words.skip(wordStart).take(count).join(),
            endsVerse: end == words.length,
          );
          if (measureHeight([...pageFragments, fragment]) <=
              availableTextHeight) {
            bestFit = count;
            low = count + 1;
          } else {
            high = count - 1;
          }
        }

        if (bestFit == 0 && pageFragments.isNotEmpty) {
          finishPage();
          continue;
        }
        if (bestFit == 0) bestFit = 1;

        final end = wordStart + bestFit;
        pageFragments.add(
          SurahPageFragment(
            verseNumber: verseNumber,
            text: words.skip(wordStart).take(bestFit).join(),
            endsVerse: end == words.length,
          ),
        );
        wordStart = end;
        if (wordStart < words.length) finishPage();
      }
    }
    finishPage();

    if (pages.isEmpty) {
      pages.add(
        const SurahPage(
          pageIndex: 0,
          startingVerseNumber: 1,
          verses: [],
        ),
      );
    }
    _paginationCache[cacheKey] = pages;
    if (_paginationCache.length > 8) {
      _paginationCache.remove(_paginationCache.keys.first);
    }
    return pages;
  }

  void _onPageChanged(int globalIndex) {
    if (_data == null || _isTransitioningSurah) return;
    if ((_isPlayingPageAudio || _isPreparingAudio) &&
        globalIndex != _currentPageIndex) {
      unawaited(_stopAudio());
    }
    if (_currentPageIndex != globalIndex) {
      setState(() => _currentPageIndex = globalIndex);
    }

    final hasPrev = _currentSurahIndex > 0;
    final hasNext = _currentSurahIndex < 113;
    final prevOffset = hasPrev ? 1 : 0;
    final currentPagesCount = _pages.length;

    // حالة 1: وصل إلى صفحة السورة السابقة (سحب لليسار عند أول صفحة)
    if (hasPrev && globalIndex == 0) {
      _isTransitioningSurah = true;
      final prevIndex = _currentSurahIndex - 1;
      final lastPageOfPrev = _prevPages.isNotEmpty ? _prevPages.length - 1 : 0;
      _initSurah(prevIndex, targetPage: lastPageOfPrev);
      return;
    }

    // حالة 2: وصل إلى صفحة السورة التالية (سحب لليمين عند آخر صفحة)
    if (hasNext && globalIndex == prevOffset + currentPagesCount) {
      _isTransitioningSurah = true;
      final nextIndex = _currentSurahIndex + 1;
      _initSurah(nextIndex, targetPage: 0);
      return;
    }

    // حالة 3: تقليب طبيعي داخل صفحات السورة الحالية
    final pageInSurah = globalIndex - prevOffset;
    if (pageInSurah >= 0 && pageInSurah < currentPagesCount) {
      unawaited(context.read<QuranReadingController>().savePagePosition(
        surahIndex: _currentSurahIndex,
        surahName: _currentSurahName,
        pageIndex: pageInSurah,
      ));
    }
  }

  GlobalKey _captureKeyForPage(int globalIndex) =>
      _pageCaptureKeys.putIfAbsent(globalIndex, GlobalKey.new);

  int get _currentLocalPageIndex =>
      _currentPageIndex - (_currentSurahIndex > 0 ? 1 : 0);

  Future<Uint8List> _captureCurrentPage() async {
    final pixelRatio = MediaQuery.devicePixelRatioOf(
      context,
    ).clamp(2.0, 4.0).toDouble();
    await WidgetsBinding.instance.endOfFrame;
    final key = _pageCaptureKeys[_currentPageIndex];
    final renderObject = key?.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('The current page is not ready to capture.');
    }

    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode the page image.');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _openPageImageCropper() async {
    try {
      final bytes = await _captureCurrentPage();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PageImageCropScreen(imageBytes: bytes),
        ),
      );
    } catch (_) {
      if (mounted) _showActionMessage('تعذر فتح تحديد جزء الصفحة');
    }
  }

  void _showActionMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPageActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.crop),
              title: const Text('اختيار جزء لمشاركته كصورة'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openPageImageCropper();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('نسخ جزء من النص'),
              subtitle: const Text('اضغط مطولًا على النص وحدد الجزء المطلوب'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showActionMessage('اضغط مطولًا على النص ثم اختر نسخ');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playCurrentPageAudio() async {
    if (_data == null || _isPreparingAudio) return;

    final requestId = ++_audioRequestId;
    final surahNumber = _currentSurahIndex + 1;
    final surahName = _currentSurahName;
    final requestedPageIndex = _currentPageIndex;
    final verseNumbers = _verseNumbersOnCurrentPage();

    if (verseNumbers.isEmpty) {
      _showActionMessage('لا توجد آيات لتشغيلها في الصفحة الحالية');
      return;
    }

    setState(() => _isPreparingAudio = true);
    try {
      final sources = QuranAudioService.ayahUris(
        surahNumber: surahNumber,
        ayahNumbers: verseNumbers,
      ).map((uri) => AudioSource.uri(uri)).toList(growable: false);

      await _audioPlayer.setAudioSources(sources);
      if (!mounted) return;
      if (requestId != _audioRequestId ||
          _currentSurahIndex + 1 != surahNumber ||
          _currentPageIndex != requestedPageIndex) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _isPreparingAudio = false);
        return;
      }
      setState(() {
        _audioLabel = 'الصفحة الحالية • سورة $surahName';
        _isPlayingPageAudio = true;
        _isPreparingAudio = false;
      });
      _startAudioPlayback();
    } catch (error, stackTrace) {
      debugPrint('Quran audio loading failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isPreparingAudio = false);
      _showActionMessage(
        'تعذّر تحميل ملف التلاوة من المصدر. حاول مرة أخرى بعد قليل.',
      );
    }
  }

  List<int> _verseNumbersOnCurrentPage() {
    final localPageIndex = _currentLocalPageIndex;
    if (localPageIndex < 0 || localPageIndex >= _pages.length) {
      return const [];
    }

    final page = _pages[localPageIndex];
    final verseNumbers = page.fragments.isNotEmpty
        ? page.fragments.map((fragment) => fragment.verseNumber)
        : Iterable<int>.generate(
            page.verses.length,
            (index) => page.startingVerseNumber + index,
          );
    return verseNumbers.toSet().toList()..sort();
  }

  Future<void> _stopAudio() async {
    _audioRequestId++;
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _audioLabel = null;
      _isPlayingPageAudio = false;
      _isPreparingAudio = false;
    });
  }

  void _startAudioPlayback() {
    unawaited(() async {
      try {
        await _audioPlayer.play();
      } on PlayerInterruptedException {
        // A new source or an explicit stop can interrupt the current request.
      } catch (_) {
        if (mounted) {
          _showActionMessage('انقطع تشغيل التلاوة. حاول تشغيلها مرة أخرى.');
        }
      }
    }());
  }

  void _showAudioPlayer() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.84,
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تلاوة القرآن',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${QuranAudioService.reciterName} · ${QuranAudioService.recitationStyle}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: const Icon(Icons.menu_book_rounded),
                    title: const Text('الصفحة الحالية'),
                    subtitle: const Text('تشغيل الآيات الظاهرة'),
                    trailing: const Icon(Icons.play_arrow_rounded),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      unawaited(_playCurrentPageAudio());
                    },
                  ),
                  if (_audioLabel != null) ...[
                    const Divider(height: 24),
                    Text(_audioLabel!, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    StreamBuilder<PlayerState>(
                      stream: _audioPlayer.playerStateStream,
                      builder: (context, snapshot) {
                        final state = snapshot.data;
                        final isPlaying = state?.playing ?? false;
                        final isLoading =
                            state?.processingState == ProcessingState.loading ||
                            state?.processingState == ProcessingState.buffering;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'إيقاف التلاوة',
                              onPressed: () => unawaited(_stopAudio()),
                              icon: const Icon(Icons.stop_circle_outlined),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filled(
                              tooltip: isPlaying
                                  ? 'إيقاف مؤقت'
                                  : 'استكمال التلاوة',
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (isPlaying) {
                                        unawaited(_audioPlayer.pause());
                                      } else {
                                        if (state?.processingState ==
                                            ProcessingState.completed) {
                                          unawaited(
                                            _audioPlayer.seek(Duration.zero),
                                          );
                                        }
                                        _startAudioPlayback();
                                      }
                                    },
                              icon: isLoading
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                    AudioProgressSlider(player: _audioPlayer),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'المصدر الصوتي: Al Quran Cloud',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = Center(
        child: Text(
          'حدث خطأ أثناء تحميل السورة',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    } else if (_data == null || _pageController == null) {
      body = Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    } else {
      final hasPrev = _currentSurahIndex > 0;
      final hasNext = _currentSurahIndex < 113;
      final prevOffset = hasPrev ? 1 : 0;
      final currentPagesCount = _pages.length;
      final totalPageViewItems =
          prevOffset + currentPagesCount + (hasNext ? 1 : 0);

      body = SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'سورة $_currentSurahName  •  صفحة ${_currentLocalPageIndex.clamp(0, currentPagesCount - 1) + 1} من $currentPagesCount',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'الاستماع لتلاوة المنشاوي',
                        onPressed: _showAudioPlayer,
                        icon: _isPreparingAudio
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : StreamBuilder<bool>(
                                stream: _audioPlayer.playingStream,
                                builder: (context, snapshot) => Icon(
                                  snapshot.data == true
                                      ? Icons.graphic_eq_rounded
                                      : Icons.headphones_rounded,
                                ),
                              ),
                      ),
                      IconButton(
                        tooltip: 'نسخ أو مشاركة الصفحة',
                        onPressed: _showPageActions,
                        icon: const Icon(Icons.ios_share_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // الصفحة تملأ مساحة القراءة المتاحة بالكامل على كل حجم شاشة
            Expanded(
              child: PageView.builder(
                // Recreate PageView for each surah so it cannot retain the
                // previous surah's scroll offset when its controller changes.
                key: ValueKey('surah-$_currentSurahIndex'),
                controller: _pageController,
                reverse: true, // سحب لليمين يجلب التالي وسحب لليسار يجلب السابق
                itemCount: totalPageViewItems,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, globalIndex) {
                  // صفحة معاينة السورة السابقة
                  if (hasPrev && globalIndex == 0) {
                    if (_prevData != null && _prevPages.isNotEmpty) {
                      return _animatedPage(
                        globalIndex,
                        RepaintBoundary(
                          key: _captureKeyForPage(globalIndex),
                          child: QuranPageWidget(
                            page: _prevPages.last,
                            surahInfo: QuranMetadata.getByZeroIndex(
                              _currentSurahIndex - 1,
                            ),
                            isFirstPage: _prevPages.length == 1,
                            basmala: _prevPages.length == 1
                                ? _prevData!.basmala
                                : null,
                          ),
                        ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  }

                  // صفحة معاينة السورة التالية
                  if (hasNext &&
                      globalIndex == prevOffset + currentPagesCount) {
                    if (_nextData != null && _nextPages.isNotEmpty) {
                      return _animatedPage(
                        globalIndex,
                        RepaintBoundary(
                          key: _captureKeyForPage(globalIndex),
                          child: QuranPageWidget(
                            page: _nextPages.first,
                            surahInfo: QuranMetadata.getByZeroIndex(
                              _currentSurahIndex + 1,
                            ),
                            isFirstPage: true,
                            basmala: _nextData!.basmala,
                          ),
                        ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  }

                  // صفحات السورة الحالية
                  final localPageIndex = globalIndex - prevOffset;
                  final isFirst = localPageIndex == 0;
                  return _animatedPage(
                    globalIndex,
                    RepaintBoundary(
                      key: _captureKeyForPage(globalIndex),
                      child: QuranPageWidget(
                        page: _pages[localPageIndex],
                        surahInfo: QuranMetadata.getByZeroIndex(
                          _currentSurahIndex,
                        ),
                        isFirstPage: isFirst,
                        basmala: isFirst ? _data!.basmala : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Image.asset(
          'assets/images/mainbacklight.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.fill,
        ),
        Scaffold(backgroundColor: Colors.transparent, body: body),
      ],
    );
  }

  Widget _animatedPage(int index, Widget page) {
    return AnimatedBuilder(
      animation: _pageController!,
      child: page,
      builder: (context, child) {
        final pagePosition = _pageController!.hasClients
            ? (_pageController!.page ?? _pageController!.initialPage.toDouble())
            : index.toDouble();
        final progress = (index - pagePosition).clamp(-1.0, 1.0);
        return Transform(
          alignment: progress >= 0
              ? Alignment.centerLeft
              : Alignment.centerRight,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(progress * 0.07),
          child: child,
        );
      },
    );
  }
}
