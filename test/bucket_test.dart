import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ustime/data/bucket_repository.dart';
import 'package:ustime/models/bucket_item.dart';
import 'package:ustime/models/item_changes.dart';
import 'package:ustime/models/item_event.dart';
import 'package:ustime/state/bucket_controller.dart';

import 'sample_items.dart';

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
      category: 'viajes',
      title: 'Grecia',
      note: 'Verano',
      location: 'Atenas',
      links: const ['https://example.com'],
      imageIds: const ['img'],
      done: true,
      doneAt: DateTime(2026, 10, 12),
      plannedAt: DateTime(2026, 12, 24),
      createdAt: DateTime(2022, 1, 1),
      history: [
        ItemEvent(
          type: ItemEventType.edited,
          actor: const Actor(uid: 'u1', name: 'Pablo Melo', photoUrl: 'p'),
          at: DateTime(2026, 10, 12, 22, 13),
          changes: const ['Nombre: «A» → «B»'],
        ),
      ],
    );
    final copy = BucketItem.fromJson(item.toJson());
    expect(copy.toJson(), item.toJson());
  });

  test('links without a scheme get https', () {
    expect(normalizeLink(' instagram.com/x '), 'https://instagram.com/x');
    expect(normalizeLink('http://a.co'), 'http://a.co');
    expect(linkLabel('https://www.instagram.com/reel/1'), 'instagram.com');
  });

  test('controller toggles, sorts, deletes and restores', () async {
    final repository = _MemoryRepository();
    final controller = BucketController(repository);
    for (final item in sampleItems()) {
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

  test('edits are described field by field', () {
    final before = sampleItems().first;
    final after = before.copyWith(
      title: 'Cosaica 2',
      location: 'Chía',
      plannedAt: DateTime(2026, 12, 24),
      links: ['https://a.co'],
      done: true,
    );
    expect(describeChanges(before, after), [
      'Nombre: «Cosaica» → «Cosaica 2»',
      'Lugar: vacío → «Chía»',
      'Fecha del plan: sin fecha → 24 dic 2026',
      'Agregó 1 link',
    ]);
    expect(describeChanges(before, before), isEmpty);
  });

  test('controller records who created, edited and completed a plan', () async {
    const pablo = Actor(uid: 'u1', name: 'Pablo Melo');
    final repository = _MemoryRepository();
    final controller = BucketController(repository, actor: pablo);
    await controller.load();

    await controller.save(sampleItems().first);
    var item = controller.items.single;
    expect(item.createdBy?.uid, 'u1');
    expect(item.history.map((e) => e.type), [ItemEventType.created]);

    await controller.save(item.copyWith(note: 'Familias'));
    await controller.save(controller.items.single);
    item = controller.items.single;
    expect(item.history.map((e) => e.type), [
      ItemEventType.created,
      ItemEventType.edited,
    ]);
    expect(item.history.last.changes, ['Nota: vacío → «Familias»']);

    await controller.toggleDone(item);
    expect(controller.items.single.doneBy?.shortName, 'Pablo');
    await controller.toggleDone(controller.items.single);
    item = controller.items.single;
    expect(item.doneBy, isNull);
    expect(item.history.last.type, ItemEventType.undone);

    // Deleting and undoing doesn't add entries.
    await controller.remove(item);
    await controller.save(item);
    expect(controller.items.single.history.length, item.history.length);
    expect(repository.items[item.id]!.history.length, 4);
  });
}
