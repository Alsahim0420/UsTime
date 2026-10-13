import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/bucket_repository.dart';
import '../models/bucket_item.dart';

class BucketController extends ChangeNotifier {
  BucketController(this._repository);

  final BucketRepository _repository;
  final _random = Random();
  final Map<String, Future<Uint8List?>> _imageCache = {};

  List<BucketItem> _items = [];
  bool _loading = true;

  bool get loading => _loading;

  /// Pending first, then newest first.
  List<BucketItem> get items => _items;

  int get total => _items.length;
  int get doneCount => _items.where((i) => i.done).length;

  int countFor(BucketCategory category) =>
      _items.where((i) => i.category == category).length;

  Future<void> load() async {
    _items = await _repository.loadItems();
    _sort();
    _loading = false;
    notifyListeners();
  }

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  /// Creates or updates [item]. [newImages] are stored under their ids and
  /// [removedImageIds] are deleted from storage.
  Future<void> save(
    BucketItem item, {
    Map<String, Uint8List> newImages = const {},
    List<String> removedImageIds = const [],
  }) async {
    for (final entry in newImages.entries) {
      await _repository.saveImage(entry.key, entry.value);
      _imageCache[entry.key] = Future.value(entry.value);
    }
    await _repository.saveItem(item);
    await _deleteImages(removedImageIds);

    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
    _sort();
    notifyListeners();
  }

  Future<void> toggleDone(BucketItem item) {
    final done = !item.done;
    return save(
      item.copyWith(
        done: done,
        doneAt: done ? DateTime.now() : null,
        clearDoneAt: !done,
      ),
    );
  }

  /// Removes the item from the list but keeps its images, so the removal can
  /// be undone with [save]. Call [purgeImages] once undo is no longer possible.
  Future<void> remove(BucketItem item) async {
    await _repository.deleteItem(item.id);
    _items.removeWhere((i) => i.id == item.id);
    notifyListeners();
  }

  Future<void> purgeImages(BucketItem item) => _deleteImages(item.imageIds);

  Future<Uint8List?> image(String id) =>
      _imageCache.putIfAbsent(id, () => _repository.loadImage(id));

  Future<void> _deleteImages(List<String> ids) async {
    for (final id in ids) {
      await _repository.deleteImage(id);
      _imageCache.remove(id);
    }
  }

  void _sort() {
    _items.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}
