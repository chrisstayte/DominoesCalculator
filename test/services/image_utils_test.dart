import 'dart:typed_data';

import 'package:dominoes/services/image_utils.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageUtils', () {
    group('preprocessForModel', () {
      /// Creates a minimal valid JPEG from a solid-colour image.
      Uint8List _makeJpeg(int width, int height) {
        final image = img.Image(width: width, height: height);
        img.fill(image, color: img.ColorRgb8(128, 64, 32));
        return Uint8List.fromList(img.encodeJpg(image));
      }

      test('returns a buffer of inputSize * inputSize * 3 bytes', () {
        final jpeg = _makeJpeg(64, 64);
        final result = ImageUtils.preprocessForModel(jpeg, 32);
        expect(result.length, 32 * 32 * 3);
      });

      test('output buffer has correct size for inputSize=64', () {
        final jpeg = _makeJpeg(128, 128);
        final result = ImageUtils.preprocessForModel(jpeg, 64);
        expect(result.length, 64 * 64 * 3);
      });

      test('pixel values are in the range 0..255', () {
        final jpeg = _makeJpeg(32, 32);
        final result = ImageUtils.preprocessForModel(jpeg, 16);
        for (final byte in result) {
          expect(byte, inInclusiveRange(0, 255));
        }
      });

      test('throws an exception for invalid (non-image) bytes', () {
        final invalid = Uint8List.fromList([0, 1, 2, 3, 4, 5]);
        expect(
          () => ImageUtils.preprocessForModel(invalid, 32),
          throwsException,
        );
      });

      test('handles non-square source image by resizing to a square', () {
        final jpeg = _makeJpeg(200, 100);
        final result = ImageUtils.preprocessForModel(jpeg, 32);
        expect(result.length, 32 * 32 * 3);
      });
    });
  });
}
