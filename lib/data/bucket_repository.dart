import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/bucket_item.dart';
import 'seed_data.dart';

/// Storage boundary for the list. The app only talks to this interface, so
/// the local implementation can be swapped for a synced one (e.g. Firestore).
abstract class BucketRepository {
  Future<List<BucketItem>> loadItems();
  Future<void> saveItem(BucketItem item);
  Future<void> deleteItem(String id);

  Future<void> saveImage(String id, Uint8List bytes);
  Future<Uint8List?> loadImage(String id);
  Future<void> deleteImage(String id);
}

/// Stores everything on the device (IndexedDB on web).
class LocalBucketRepository implements BucketRepository {
  LocalBucketRepository._(this._items, this._images);

  final Box<String> _items;
  final LazyBox<dynamic> _images;

  static Future<LocalBucketRepository> open() async {
    await Hive.initFlutter();
    final items = await Hive.openBox<String>('items');
    final images = await Hive.openLazyBox<dynamic>('images');
    final meta = await Hive.openBox<dynamic>('meta');

    if (meta.get('seeded') != true) {
      await items.putAll({
        for (final item in buildSeedItems()) item.id: jsonEncode(item.toJson()),
      });
      await meta.put('seeded', true);
    }
    return LocalBucketRepository._(items, images);
  }

  @override
  Future<List<BucketItem>> loadItems() async {
    return [
      for (final raw in _items.values)
        BucketItem.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> saveItem(BucketItem item) =>
      _items.put(item.id, jsonEncode(item.toJson()));

  @override
  Future<void> deleteItem(String id) => _items.delete(id);

  @override
  Future<void> saveImage(String id, Uint8List bytes) => _images.put(id, bytes);

  @override
  Future<Uint8List?> loadImage(String id) async {
    final value = await _images.get(id);
    if (value is Uint8List) return value;
    if (value is List) return Uint8List.fromList(value.cast<int>());
    return null;
  }

  @override
  Future<void> deleteImage(String id) => _images.delete(id);
}
