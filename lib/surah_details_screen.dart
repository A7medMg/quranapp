import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:just_audio/just_audio.dart';

import 'constans/appcolor.dart';
import 'constans/surah_info.dart';
import 'services/quran_audio_service.dart';
import 'services/quran_cache.dart';
import 'services/quran_preferences.dart';
import 'services/page_image_sharing.dart';

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
  final Map<SurahData, List<SurahPage>> _paginationCache = {};
  String? _paginationCacheViewport;
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
          ModalRoute.of(context)!.settings.arguments as SurahdetailsArgs;
      _currentSurahIndex = args.index;
      _currentSurahName = args.surahName;
      _initSurah(args.index, targetPage: args.startAtBeginning ? 0 : null);
    }
  }

  /// تحميل السورة الحالية والسورتين السابقة والتالية للانتقال الفوري بين السور
  Future<void> _initSurah(int surahIndex, {int? targetPage}) async {
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

      // جلب السابقة والتالية مسبقاً في الذاكرة لتكون جاهزة لحظة السحب
      SurahData? prevData;
      SurahData? nextData;
      if (surahIndex > 0) {
        prevData = await QuranCache.instance.getSurah(surahIndex - 1);
      }
      if (surahIndex < 113) {
        nextData = await QuranCache.instance.getSurah(surahIndex + 1);
      }

      final pages = _paginateForScreen(data);
      final prevPages = prevData == null
          ? const <SurahPage>[]
          : _paginateForScreen(prevData);
      final nextPages = nextData == null
          ? const <SurahPage>[]
          : _paginateForScreen(nextData);

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
          _prevData = prevData;
          _nextData = nextData;
          _pages = pages;
          _prevPages = prevPages;
          _nextPages = nextPages;
          _currentPageIndex = initialControllerPage;
          _pageCaptureKeys.clear();
          _isTransitioningSurah = false;
        });

        QuranPreferences.savePagePosition(
          surahIndex: _currentSurahIndex,
          surahName: _currentSurahName,
          pageIndex: pageInSurah,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isTransitioningSurah = false;
        });
      }
    }
  }

  /// تقسيم الآيات حسب مساحة الصفحة الظاهرة على الجهاز، مع الاحتفاظ بالآيات
  /// كاملة قدر الإمكان وربط كل صفحة بآياتها المستخدمة في التلاوة.
  List<SurahPage> _paginateForScreen(SurahData data) {
    final screen = MediaQuery.sizeOf(context);
    final safeArea = MediaQuery.paddingOf(context);
    final viewportKey = '${screen.width}x${screen.height}:${safeArea.vertical}';
    if (_paginationCacheViewport != viewportKey) {
      _paginationCache.clear();
      _paginationCacheViewport = viewportKey;
    }
    final cachedPages = _paginationCache[data];
    if (cachedPages != null) return cachedPages;

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
                  ' ﴿${_SingleSurahPageWidget._toArabicDigits(fragment.verseNumber)}﴾ ',
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
    return _paginationCache[data] = pages;
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
      QuranPreferences.savePagePosition(
        surahIndex: _currentSurahIndex,
        surahName: _currentSurahName,
        pageIndex: pageInSurah,
      );
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
          builder: (_) => _PageImageCropScreen(imageBytes: bytes),
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
                    _AudioProgressSlider(player: _audioPlayer),
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
                          child: _SingleSurahPageWidget(
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
                          child: _SingleSurahPageWidget(
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
                      child: _SingleSurahPageWidget(
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

// ---------------------------------------------------------------------------
// زخرفة إطار رأس السورة (الاسم، مكية/مدنية، عدد الآيات) داخل الصفحة كعنصر طبيعي
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
class _SingleSurahPageWidget extends StatelessWidget {
  final SurahPage page;
  final SurahInfo surahInfo;
  final String? basmala;
  final bool isFirstPage;

  const _SingleSurahPageWidget({
    required this.page,
    required this.surahInfo,
    this.basmala,
    this.isFirstPage = false,
  });

  /// تحويل رقم عربي-هندي  1 → ١
  static String _toArabicDigits(int n) {
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
            text: ' ﴿${_toArabicDigits(fragment.verseNumber)}﴾ ',
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

class _AudioProgressSlider extends StatelessWidget {
  const _AudioProgressSlider({required this.player});

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

class SurahdetailsArgs {
  final String surahName;
  final int index;
  final bool startAtBeginning;

  const SurahdetailsArgs({
    required this.surahName,
    required this.index,
    this.startAtBeginning = false,
  });
}

class _PageImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const _PageImageCropScreen({required this.imageBytes});

  @override
  State<_PageImageCropScreen> createState() => _PageImageCropScreenState();
}

class _PageImageCropScreenState extends State<_PageImageCropScreen> {
  late final Future<ui.Image> _imageFuture;
  ui.Image? _decodedImage;
  Rect? _selection;
  Offset? _dragStart;
  bool _isWorking = false;

  bool get _hasSelection =>
      _selection != null && _selection!.width >= 48 && _selection!.height >= 48;

  @override
  void initState() {
    super.initState();
    _imageFuture = ui.instantiateImageCodec(widget.imageBytes).then((
      codec,
    ) async {
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (mounted) {
        setState(() => _decodedImage = frame.image);
      } else {
        frame.image.dispose();
      }
      return frame.image;
    });
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    super.dispose();
  }

  Offset _toImagePoint(Offset point, Rect imageRect, ui.Image image) {
    return Offset(
      ((point.dx - imageRect.left) / imageRect.width * image.width)
          .clamp(0.0, image.width.toDouble())
          .toDouble(),
      ((point.dy - imageRect.top) / imageRect.height * image.height)
          .clamp(0.0, image.height.toDouble())
          .toDouble(),
    );
  }

  Future<Uint8List> _cropImage(ui.Image image) async {
    final selection = _selection;
    if (selection == null || !_hasSelection) {
      throw StateError('Select an area before exporting.');
    }

    final left = selection.left.floor().clamp(0, image.width - 1);
    final top = selection.top.floor().clamp(0, image.height - 1);
    final right = selection.right.ceil().clamp(left + 1, image.width);
    final bottom = selection.bottom.ceil().clamp(top + 1, image.height);
    final width = right - left;
    final height = bottom - top;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTRB(
        left.toDouble(),
        top.toDouble(),
        right.toDouble(),
        bottom.toDouble(),
      ),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(width, height);
    try {
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode the crop.');
      return data.buffer.asUint8List();
    } finally {
      cropped.dispose();
      picture.dispose();
    }
  }

  Future<void> _saveSelection(ui.Image image) async {
    setState(() => _isWorking = true);
    try {
      final bytes = await _cropImage(image);
      await Gal.putImageBytes(bytes, name: 'quran-selection');
      if (mounted) _showMessage('تم حفظ الجزء المحدد في الصور');
    } catch (_) {
      if (mounted) _showMessage('تعذر حفظ الصورة. تحقق من إذن الصور.');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _shareSelection(ui.Image image) async {
    setState(() => _isWorking = true);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      final bytes = await _cropImage(image);
      await sharePageImage(bytes, sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) _showMessage('تعذرت مشاركة الجزء المحدد');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF292723),
      appBar: AppBar(
        backgroundColor: const Color(0xFF292723),
        foregroundColor: Colors.white,
        title: const Text('حدد الجزء المطلوب'),
      ),
      body: SafeArea(
        child: FutureBuilder<ui.Image>(
          future: _imageFuture,
          builder: (context, snapshot) {
            final image = snapshot.data;
            if (image == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bounds = Offset.zero & constraints.biggest;
                      final fitted = applyBoxFit(
                        BoxFit.contain,
                        Size(image.width.toDouble(), image.height.toDouble()),
                        constraints.biggest,
                      );
                      final imageRect = Alignment.center.inscribe(
                        fitted.destination,
                        bounds,
                      );

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) {
                          if (!imageRect.contains(details.localPosition)) {
                            return;
                          }
                          final point = _toImagePoint(
                            details.localPosition,
                            imageRect,
                            image,
                          );
                          setState(() {
                            _dragStart = point;
                            _selection = Rect.fromPoints(point, point);
                          });
                        },
                        onPanUpdate: (details) {
                          final start = _dragStart;
                          if (start == null) return;
                          final point = _toImagePoint(
                            details.localPosition,
                            imageRect,
                            image,
                          );
                          setState(
                            () => _selection = Rect.fromPoints(start, point),
                          );
                        },
                        onPanEnd: (_) => setState(() => _dragStart = null),
                        child: Stack(
                          children: [
                            Positioned.fromRect(
                              rect: imageRect,
                              child: Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                foregroundPainter: _PageCropOverlayPainter(
                                  imageRect: imageRect,
                                  imageSize: Size(
                                    image.width.toDouble(),
                                    image.height.toDouble(),
                                  ),
                                  selection: _selection,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _hasSelection
                            ? 'اسحب لتعديل التحديد'
                            : 'اسحب على الصفحة لتحديد الجزء',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _hasSelection && !_isWorking
                                  ? () => _saveSelection(image)
                                  : null,
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('حفظ'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _hasSelection && !_isWorking
                                  ? () => _shareSelection(image)
                                  : null,
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('مشاركة'),
                            ),
                          ),
                        ],
                      ),
                      if (_isWorking) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PageCropOverlayPainter extends CustomPainter {
  final Rect imageRect;
  final Size imageSize;
  final Rect? selection;

  const _PageCropOverlayPainter({
    required this.imageRect,
    required this.imageSize,
    required this.selection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final selected = selection;
    final displaySelection = selected == null
        ? null
        : Rect.fromLTRB(
            imageRect.left + selected.left / imageSize.width * imageRect.width,
            imageRect.top + selected.top / imageSize.height * imageRect.height,
            imageRect.left + selected.right / imageSize.width * imageRect.width,
            imageRect.top +
                selected.bottom / imageSize.height * imageRect.height,
          );
    final outside = Path()..addRect(imageRect);
    if (displaySelection != null) {
      final shade = Path.combine(
        PathOperation.difference,
        Path()..addRect(imageRect),
        Path()..addRect(displaySelection),
      );
      canvas.drawPath(
        shade,
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
      canvas.drawRect(
        displaySelection,
        Paint()
          ..color = const Color(0xFFE8C98A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      canvas.drawPath(
        outside,
        Paint()..color = Colors.black.withValues(alpha: 0.42),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PageCropOverlayPainter oldDelegate) =>
      oldDelegate.imageRect != imageRect ||
      oldDelegate.imageSize != imageSize ||
      oldDelegate.selection != selection;
}
