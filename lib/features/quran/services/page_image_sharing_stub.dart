import 'dart:typed_data';

import 'package:flutter/painting.dart';

Future<void> sharePageImage(
  Uint8List bytes, {
  required Rect sharePositionOrigin,
}) async {
  throw UnsupportedError('Image sharing is not available on this platform.');
}
