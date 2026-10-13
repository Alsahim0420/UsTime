import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ustime/data/image_compressor.dart';

/// A noisy picture, which is the hardest kind to compress.
img.Image _noise(int width, int height, {int channels = 3}) {
  final random = Random(7);
  final image = img.Image(width: width, height: height, numChannels: channels);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
    if (channels == 4) pixel.a = random.nextInt(256);
  }
  return image;
}

void main() {
  test('large photos end up under 300 KB and still open', () {
    final original = img.encodeJpg(_noise(2400, 1800), quality: 95);
    expect(original.length, greaterThan(maxImageBytes));

    final compressed = compressImage(original)!;
    expect(compressed.length, lessThanOrEqualTo(maxImageBytes));

    final decoded = img.decodeImage(compressed)!;
    expect(decoded.width / decoded.height, closeTo(2400 / 1800, 0.01));
    expect(decoded.width, lessThanOrEqualTo(1600));
  });

  test('transparent PNGs are compressed too', () {
    final original = img.encodePng(_noise(1200, 1200, channels: 4));
    expect(original.length, greaterThan(maxImageBytes));
    final compressed = compressImage(original)!;
    expect(compressed.length, lessThanOrEqualTo(maxImageBytes));
  });

  test('photos already under the limit are left untouched', () {
    final small = img.encodeJpg(_noise(200, 150), quality: 80);
    expect(compressImage(small), same(small));
  });

  test('files that are not images are rejected', () {
    expect(compressImage(Uint8List.fromList(List.filled(64, 7))), isNull);
  });
}
