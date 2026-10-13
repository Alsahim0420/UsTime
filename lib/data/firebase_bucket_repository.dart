import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/bucket_item.dart';
import 'bucket_repository.dart';

/// The items of one shared list: they live in Firestore
/// (`spaces/{spaceId}/items/{id}`) and their photos in Cloud Storage
/// (`spaces/{spaceId}/images/{id}`). Only members of the list have access,
/// enforced by firestore.rules and storage.rules.
class FirebaseBucketRepository implements BucketRepository {
  FirebaseBucketRepository(
    this.spaceId, {
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final String spaceId;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('spaces/$spaceId/items');

  Reference _image(String id) => _storage.ref('spaces/$spaceId/images/$id');

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
