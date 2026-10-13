import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Largest photo the app stores.
const maxImageBytes = 300 * 1024;

/// Returns [bytes] as an image of at most [maxBytes], or null if it isn't a
/// readable image.
///
/// Photos already under the limit are returned untouched. Larger ones are
/// re-encoded as JPEG, lowering the quality first and then the dimensions
/// until they fit.
Uint8List? compressImage(Uint8List bytes, {int maxBytes = maxImageBytes}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  if (bytes.length <= maxBytes) return bytes;

  var image = img.bakeOrientation(decoded);
  if (image.hasAlpha) {
    // JPEG has no transparency; put the picture on white instead of black.
    final background = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 3,
    )..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(background, image);
  }

  const maxSide = 1600;
  const minSide = 320;
  const qualities = [82, 72, 62, 50];

  var side = image.width > image.height ? image.width : image.height;
  if (side > maxSide) {
    image = _resize(image, maxSide);
    side = maxSide;
  }

  late Uint8List smallest;
  while (true) {
    for (final quality in qualities) {
      smallest = img.encodeJpg(image, quality: quality);
      if (smallest.length <= maxBytes) return smallest;
    }
    if (side <= minSide) return smallest;
    side = (side * 0.8).round();
    image = _resize(image, side);
  }
}

/// Scales [image] so its longest side is [side] pixels.
img.Image _resize(img.Image image, int side) {
  final landscape = image.width >= image.height;
  return img.copyResize(
    image,
    width: landscape ? side : null,
    height: landscape ? null : side,
    interpolation: img.Interpolation.average,
  );
}
