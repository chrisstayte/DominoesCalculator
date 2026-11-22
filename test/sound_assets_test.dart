import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every bundled interaction cue contains audible PCM samples', () async {
    for (final cue in [
      'tap',
      'delete',
      'clear',
      'capture',
      'success',
      'toggle',
      'open',
      'close',
      'navigate',
    ]) {
      final key = 'assets/sfx/$cue.wav';
      final bytes = await rootBundle.load(key);
      final encoded = bytes.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
      expect(String.fromCharCodes(encoded.take(4)), 'RIFF', reason: key);
      expect(
        String.fromCharCodes(encoded.skip(8).take(4)),
        'WAVE',
        reason: key,
      );
      var loudSamples = 0;
      for (var offset = 12; offset + 8 <= bytes.lengthInBytes;) {
        final size = bytes.getUint32(offset + 4, Endian.little);
        final start = offset + 8;
        expect(
          start + size,
          lessThanOrEqualTo(bytes.lengthInBytes),
          reason: key,
        );
        if (String.fromCharCodes(encoded.sublist(offset, offset + 4)) ==
            'data') {
          for (var i = start; i + 1 < start + size; i += 2) {
            if (bytes.getInt16(i, Endian.little).abs() > 300) loudSamples++;
          }
        }
        offset = start + size + (size.isOdd ? 1 : 0);
      }
      expect(loudSamples, greaterThan(100), reason: key);
    }
  });
}
