/// A list shared by a group of people (a couple, friends…). Others join it
/// with its 6-digit [code].
class Space {
  const Space({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerUid,
    required this.members,
    this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String ownerUid;
  final List<String> members;
  final DateTime? createdAt;

  factory Space.fromJson(String id, Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return Space(
      id: id,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? '',
      members: (json['members'] as List? ?? const []).cast<String>(),
      // A Firestore Timestamp; null while the server time is still pending.
      createdAt: createdAt == null
          ? null
          : (createdAt as dynamic).toDate() as DateTime,
    );
  }
}

/// Formats a code for reading aloud or typing: `482913` -> `482 913`.
String formatSpaceCode(String code) =>
    code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;
