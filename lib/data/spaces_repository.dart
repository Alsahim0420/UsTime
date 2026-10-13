import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/space.dart';

/// Thrown when nobody has a list with the given code.
class SpaceNotFound implements Exception {
  const SpaceNotFound();
}

/// Per-user settings, synced across the user's devices.
class UserPrefs {
  const UserPrefs({this.activeSpaceId, this.theme});

  final String? activeSpaceId;

  /// `light`, `dark`, or null to follow the system.
  final String? theme;
}

/// Shared lists and user settings in Firestore:
/// - `users/{uid}`: the user's settings.
/// - `spaces/{id}`: a shared list and its members.
/// - `codes/{code}`: which list a 6-digit code belongs to. The code is the
///   document id, so two lists can never have the same one.
class SpacesRepository {
  SpacesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _spaces =>
      _firestore.collection('spaces');
  CollectionReference<Map<String, dynamic>> get _codes =>
      _firestore.collection('codes');

  Stream<UserPrefs> watchPrefs(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? const {};
      return UserPrefs(
        activeSpaceId: data['activeSpaceId'] as String?,
        theme: data['theme'] as String?,
      );
    });
  }

  /// Lists the user belongs to, oldest first.
  Stream<List<Space>> watchSpaces(String uid) {
    return _spaces.where('members', arrayContains: uid).snapshots().map((
      snapshot,
    ) {
      final spaces = [
        for (final doc in snapshot.docs) Space.fromJson(doc.id, doc.data()),
      ];
      final newest = DateTime(9999);
      spaces.sort(
        (a, b) => (a.createdAt ?? newest).compareTo(b.createdAt ?? newest),
      );
      return spaces;
    });
  }

  /// Creates a list with a fresh unique code and makes it the active one.
  /// Returns the new list's id.
  Future<String> createSpace(
    String uid,
    String name,
    List<Category> categories,
  ) async {
    final spaceRef = _spaces.doc();
    for (var attempt = 0; attempt < 20; attempt++) {
      final code = '${100000 + _random.nextInt(900000)}';
      final codeRef = _codes.doc(code);
      // The transaction only succeeds if the code is still free.
      final created = await _firestore.runTransaction<bool>((tx) async {
        if ((await tx.get(codeRef)).exists) return false;
        tx.set(codeRef, {'spaceId': spaceRef.id, 'ownerUid': uid});
        tx.set(spaceRef, {
          'name': name,
          'code': code,
          'ownerUid': uid,
          'members': [uid],
          'categories': [for (final c in categories) c.toJson()],
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (created) {
        await setActiveSpace(uid, spaceRef.id);
        return spaceRef.id;
      }
    }
    throw StateError('Could not find a free code');
  }

  /// Adds the user to the list with [code] and makes it the active one.
  /// Throws [SpaceNotFound] if the code doesn't exist.
  Future<String> joinSpace(String uid, String code) async {
    final codeDoc = await _codes.doc(code).get();
    final spaceId = codeDoc.data()?['spaceId'] as String?;
    if (spaceId == null) throw const SpaceNotFound();

    await _spaces.doc(spaceId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
    await setActiveSpace(uid, spaceId);
    return spaceId;
  }

  /// Replaces the list's categories for all its members.
  Future<void> saveCategories(String spaceId, List<Category> categories) {
    return _spaces.doc(spaceId).update({
      'categories': [for (final c in categories) c.toJson()],
    });
  }

  Future<void> setActiveSpace(String uid, String spaceId) =>
      _users.doc(uid).set({'activeSpaceId': spaceId}, SetOptions(merge: true));

  Future<void> setTheme(String uid, String? theme) =>
      _users.doc(uid).set({'theme': theme}, SetOptions(merge: true));
}
