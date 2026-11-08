import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:quran_app/features/quran/services/page_image_sharing.dart';
class PageImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const PageImageCropScreen({required this.imageBytes});

  @override
  State<PageImageCropScreen> createState() => _PageImageCropScreenState();
}

class _PageImageCropScreenState extends State<PageImageCropScreen> {
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
