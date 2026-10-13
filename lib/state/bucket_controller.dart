import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/bucket_repository.dart';
import '../models/bucket_item.dart';

class BucketController extends ChangeNotifier {
  BucketController(this._repository);

  final BucketRepository _repository;
  final _random = Random();
  final Map<String, Future<ImageData?>> _imageCache = {};

  List<BucketItem> _items = [];
  bool _loading = true;
  Object? _error;
  StreamSubscription<List<BucketItem>>? _subscription;

  bool get loading => _loading;

  /// Set when the list could not be read, e.g. the account has no access.
  Object? get error => _error;

  /// Pending first, then newest first.
  List<BucketItem> get items => _items;

  int get total => _items.length;
  int get doneCount => _items.where((i) => i.done).length;

  int countFor(BucketCategory category) =>
      _items.where((i) => i.category == category).length;

  /// Starts listening to the shared list. Completes once the first result
  /// (or error) arrives; later changes by anyone keep updating [items].
  Future<void> load() {
    final first = Completer<void>();
    void done() {
      _loading = false;
      notifyListeners();
      if (!first.isCompleted) first.complete();
    }

    _subscription?.cancel();
    _subscription = _repository.watchItems().listen(
      (items) {
        _items = [...items];
        _sort();
        _error = null;
        done();
      },
      onError: (Object error) {
        _error = error;
        done();
      },
    );
    return first.future;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
      _imageCache[entry.key] = Future.value(ImageData.bytes(entry.value));
    }

    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
    _sort();
    notifyListeners();

    await _repository.saveItem(item);
    await _deleteImages(removedImageIds);
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
    _items.removeWhere((i) => i.id == item.id);
    notifyListeners();
    await _repository.deleteItem(item.id);
  }

  Future<void> purgeImages(BucketItem item) => _deleteImages(item.imageIds);

  Future<ImageData?> image(String id) =>
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
