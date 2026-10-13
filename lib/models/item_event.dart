/// The person who did something, with what's needed to show their avatar.
class Actor {
  const Actor({required this.uid, this.name, this.photoUrl});

  final String uid;
  final String? name;
  final String? photoUrl;

  /// First name only, for compact labels.
  String get shortName {
    final first = name?.trim().split(' ').first ?? '';
    return first.isEmpty ? 'Alguien' : first;
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'photoUrl': photoUrl,
  };

  factory Actor.fromJson(Map<String, dynamic> json) => Actor(
    uid: json['uid'] as String? ?? '',
    name: json['name'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );
}

enum ItemEventType {
  created('creó el plan'),
  edited('editó el plan'),
  done('lo marcó como cumplido'),
  undone('lo volvió a dejar pendiente');

  const ItemEventType(this.label);

  /// Reads after the person's name, e.g. "Pablo creó el plan".
  final String label;
}

/// One entry in a plan's activity log: who did what, and when.
class ItemEvent {
  const ItemEvent({
    required this.type,
    required this.actor,
    required this.at,
    this.changes = const [],
  });

  final ItemEventType type;
  final Actor actor;
  final DateTime at;

  /// For edits, a readable line per thing that changed.
  final List<String> changes;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'actor': actor.toJson(),
    'at': at.toIso8601String(),
    if (changes.isNotEmpty) 'changes': changes,
  };

  factory ItemEvent.fromJson(Map<String, dynamic> json) => ItemEvent(
    type: ItemEventType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => ItemEventType.edited,
    ),
    actor: Actor.fromJson(
      Map<String, dynamic>.from(json['actor'] as Map? ?? const {}),
    ),
    at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    changes: (json['changes'] as List? ?? const []).cast<String>(),
  );
}
