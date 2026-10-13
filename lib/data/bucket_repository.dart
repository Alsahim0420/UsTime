import 'dart:typed_data';

import '../models/bucket_item.dart';

/// An image that is either still in memory or already stored remotely.
class ImageData {
  const ImageData.bytes(Uint8List this.bytes) : url = null;
  const ImageData.url(String this.url) : bytes = null;

  final Uint8List? bytes;
  final String? url;
}

/// Storage boundary for the list. The app only talks to this interface.
abstract class BucketRepository {
  /// Emits the whole list now and again every time anyone changes it.
  Stream<List<BucketItem>> watchItems();
  Future<void> saveItem(BucketItem item);
  Future<void> deleteItem(String id);

  Future<void> saveImage(String id, Uint8List bytes);
  Future<ImageData?> loadImage(String id);
  Future<void> deleteImage(String id);
}
