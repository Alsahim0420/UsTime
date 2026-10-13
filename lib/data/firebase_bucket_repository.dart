import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/bucket_item.dart';
import 'bucket_repository.dart';
import 'seed_data.dart';

/// Shared list: items live in Firestore (`items/{id}`) and photos in Cloud
/// Storage (`images/{id}`). Access is limited by firestore.rules and
/// storage.rules.
class FirebaseBucketRepository implements BucketRepository {
  FirebaseBucketRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  Reference _image(String id) => _storage.ref('images/$id');

  /// Uploads the original Drive list once. A marker document keeps it from
  /// coming back after the list has been emptied on purpose.
  Future<void> seedIfNeeded() async {
    final marker = _firestore.doc('meta/seed');
    if ((await marker.get()).exists) return;

    final batch = _firestore.batch();
    for (final item in buildSeedItems()) {
      batch.set(_items.doc(item.id), item.toJson());
    }
    batch.set(marker, {'seededAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  @override
  Stream<List<BucketItem>> watchItems() {
    return _items.snapshots().map(
      (snapshot) => [
        for (final doc in snapshot.docs) BucketItem.fromJson(doc.data()),
      ],
    );
  }

  @override
  Future<void> saveItem(BucketItem item) =>
      _items.doc(item.id).set(item.toJson());

  @override
  Future<void> deleteItem(String id) => _items.doc(id).delete();

  @override
  Future<void> saveImage(String id, Uint8List bytes) async {
    await _image(id).putData(
      bytes,
      SettableMetadata(
        contentType: _imageMimeType(bytes),
        cacheControl: 'private, max-age=31536000',
      ),
    );
  }

  @override
  Future<ImageData?> loadImage(String id) async {
    try {
      return ImageData.url(await _image(id).getDownloadURL());
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<void> deleteImage(String id) async {
    try {
      await _image(id).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}

/// Guesses the MIME type from the file signature; storage.rules only accepts
/// `image/*` uploads.
String _imageMimeType(Uint8List bytes) {
  bool startsWith(List<int> signature, [int offset = 0]) {
    if (bytes.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (startsWith([0x47, 0x49, 0x46])) return 'image/gif';
  if (startsWith([0x57, 0x45, 0x42, 0x50], 8)) return 'image/webp';
  return 'image/jpeg';
}
