import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ustime/data/bucket_repository.dart';
import 'package:ustime/data/seed_data.dart';
import 'package:ustime/models/bucket_item.dart';
import 'package:ustime/state/bucket_controller.dart';

class _MemoryRepository implements BucketRepository {
  final items = <String, BucketItem>{};
  final images = <String, Uint8List>{};

  @override
  Stream<List<BucketItem>> watchItems() => Stream.value(items.values.toList());
  @override
  Future<void> saveItem(BucketItem item) async => items[item.id] = item;
  @override
  Future<void> deleteItem(String id) async => items.remove(id);
  @override
  Future<void> saveImage(String id, Uint8List bytes) async =>
      images[id] = bytes;
  @override
  Future<ImageData?> loadImage(String id) async {
    final bytes = images[id];
    return bytes == null ? null : ImageData.bytes(bytes);
  }

  @override
  Future<void> deleteImage(String id) async => images.remove(id);
}

void main() {
  test('items survive a JSON round trip', () {
    final item = BucketItem(
      id: 'a',
      category: BucketCategory.viajes,
      title: 'Grecia',
      note: 'Verano',
      location: 'Atenas',
      links: const ['https://example.com'],
      imageIds: const ['img'],
      done: true,
      doneAt: DateTime(2026, 10, 12),
      plannedAt: DateTime(2026, 12, 24),
      createdAt: DateTime(2022, 1, 1),
    );
    final copy = BucketItem.fromJson(item.toJson());
    expect(copy.toJson(), item.toJson());
  });

  test('links without a scheme get https', () {
    expect(normalizeLink(' instagram.com/x '), 'https://instagram.com/x');
    expect(normalizeLink('http://a.co'), 'http://a.co');
    expect(linkLabel('https://www.instagram.com/reel/1'), 'instagram.com');
  });

  test('seed list has unique ids and keeps the original order', () {
    final seed = buildSeedItems();
    expect(seed.map((i) => i.id).toSet().length, seed.length);
    expect(seed.first.title, 'Cosaica');
  });

  test('controller toggles, sorts, deletes and restores', () async {
    final repository = _MemoryRepository();
    final controller = BucketController(repository);
    for (final item in buildSeedItems().take(3)) {
      await repository.saveItem(item);
    }
    await controller.load();
    expect(controller.items.first.title, 'Cosaica');

    await controller.toggleDone(controller.items.first);
    expect(controller.doneCount, 1);
    expect(controller.items.last.title, 'Cosaica');
    expect(controller.items.last.doneAt, isNotNull);

    await controller.toggleDone(controller.items.last);
    expect(controller.items.first.doneAt, isNull);

    final withImage = controller.items.first.copyWith(imageIds: ['img']);
    await controller.save(withImage, newImages: {'img': Uint8List(1)});
    await controller.remove(withImage);
    expect(controller.total, 2);
    expect(repository.images, contains('img'));

    await controller.save(withImage);
    expect(controller.total, 3);

    await controller.remove(withImage);
    await controller.purgeImages(withImage);
    expect(repository.images, isEmpty);
  });
}
