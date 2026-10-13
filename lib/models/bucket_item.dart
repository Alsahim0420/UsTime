import 'package:flutter/material.dart';

enum BucketCategory {
  restaurantes('Restaurantes', '🍔', Color(0xFFFFC9B5), Color(0xFFF7A1B5)),
  viajes('Viajes', '✈️', Color(0xFFB9CCFA), Color(0xFFC3A6F0)),
  planes('Planes', '❤️', Color(0xFFF9B4D0), Color(0xFFE39AD8)),
  series('Series', '🎬', Color(0xFFCDB4F5), Color(0xFF9C8CE8));

  const BucketCategory(this.label, this.emoji, this.colorA, this.colorB);

  final String label;
  final String emoji;
  final Color colorA;
  final Color colorB;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [colorA, colorB],
  );

  static BucketCategory fromName(String? name) => values.firstWhere(
    (c) => c.name == name,
    orElse: () => BucketCategory.planes,
  );
}

class BucketItem {
  const BucketItem({
    required this.id,
    required this.category,
    required this.title,
    required this.createdAt,
    this.note = '',
    this.location = '',
    this.links = const [],
    this.imageIds = const [],
    this.done = false,
    this.doneAt,
    this.plannedAt,
  });

  final String id;
  final BucketCategory category;
  final String title;
  final String note;
  final String location;
  final List<String> links;
  final List<String> imageIds;
  final bool done;
  final DateTime? doneAt;

  /// Day the plan is scheduled for, if any.
  final DateTime? plannedAt;
  final DateTime createdAt;

  BucketItem copyWith({
    BucketCategory? category,
    String? title,
    String? note,
    String? location,
    List<String>? links,
    List<String>? imageIds,
    bool? done,
    DateTime? doneAt,
    bool clearDoneAt = false,
    DateTime? plannedAt,
    bool clearPlannedAt = false,
  }) {
    return BucketItem(
      id: id,
      createdAt: createdAt,
      category: category ?? this.category,
      title: title ?? this.title,
      note: note ?? this.note,
      location: location ?? this.location,
      links: links ?? this.links,
      imageIds: imageIds ?? this.imageIds,
      done: done ?? this.done,
      doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
      plannedAt: clearPlannedAt ? null : (plannedAt ?? this.plannedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'note': note,
    'location': location,
    'links': links,
    'imageIds': imageIds,
    'done': done,
    'doneAt': doneAt?.toIso8601String(),
    'plannedAt': plannedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory BucketItem.fromJson(Map<String, dynamic> json) {
    return BucketItem(
      id: json['id'] as String,
      category: BucketCategory.fromName(json['category'] as String?),
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      location: json['location'] as String? ?? '',
      links: (json['links'] as List? ?? const []).cast<String>(),
      imageIds: (json['imageIds'] as List? ?? const []).cast<String>(),
      done: json['done'] as bool? ?? false,
      doneAt: DateTime.tryParse(json['doneAt'] as String? ?? ''),
      plannedAt: DateTime.tryParse(json['plannedAt'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Adds `https://` to links typed without a scheme.
String normalizeLink(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return value;
  return value.contains('://') ? value : 'https://$value';
}

/// Short label for a link, e.g. `instagram.com`.
String linkLabel(String link) {
  final host = Uri.tryParse(link)?.host ?? '';
  if (host.isEmpty) return link;
  return host.startsWith('www.') ? host.substring(4) : host;
}

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
