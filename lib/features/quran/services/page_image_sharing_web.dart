import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePageImage(
  Uint8List bytes, {
  required Rect sharePositionOrigin,
}) async {
  await Share.shareXFiles(
    [XFile.fromData(bytes, mimeType: 'image/png')],
    subject: 'جزء من صفحة القرآن الكريم',
    fileNameOverrides: const ['quran-selection.png'],
    sharePositionOrigin: sharePositionOrigin,
  );
}
