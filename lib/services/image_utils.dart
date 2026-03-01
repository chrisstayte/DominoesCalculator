import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageUtils {
  static Uint8List preprocessForModel(Uint8List jpegBytes, int inputSize) {
    final image = img.decodeImage(jpegBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    final buffer = Uint8List(inputSize * inputSize * 3);
    var index = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[index++] = pixel.r.toInt();
        buffer[index++] = pixel.g.toInt();
        buffer[index++] = pixel.b.toInt();
      }
    }

    return buffer;
  }
}
