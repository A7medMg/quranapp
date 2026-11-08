import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePageImage(
  Uint8List bytes, {
  required Rect sharePositionOrigin,
}) async {
  final directory = await Directory.systemTemp.createTemp('quran_share_');
  final file = File('${directory.path}${Platform.pathSeparator}selection.png');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png')],
    subject: 'جزء من صفحة القرآن الكريم',
    fileNameOverrides: const ['quran-selection.png'],
    sharePositionOrigin: sharePositionOrigin,
  );
}
