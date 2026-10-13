import 'package:flutter/material.dart';

/// Icons a category can use, by the key stored in the database.
const categoryIcons = <String, IconData>{
  'restaurant': Icons.restaurant_rounded,
  'flight': Icons.flight_rounded,
  'favorite': Icons.favorite_rounded,
  'movie': Icons.movie_rounded,
  'cafe': Icons.local_cafe_rounded,
  'bar': Icons.local_bar_rounded,
  'cake': Icons.cake_rounded,
  'beach': Icons.beach_access_rounded,
  'hiking': Icons.hiking_rounded,
  'car': Icons.directions_car_rounded,
  'hotel': Icons.hotel_rounded,
  'camera': Icons.photo_camera_rounded,
  'music': Icons.music_note_rounded,
  'game': Icons.sports_esports_rounded,
  'sports': Icons.sports_soccer_rounded,
  'fitness': Icons.fitness_center_rounded,
  'book': Icons.menu_book_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'party': Icons.celebration_rounded,
  'gift': Icons.card_giftcard_rounded,
  'home': Icons.home_rounded,
  'pets': Icons.pets_rounded,
  'nature': Icons.park_rounded,
  'star': Icons.star_rounded,
};

/// Pastel gradients a category can use, by the index stored in the database.
const categoryColors = <(Color, Color)>[
  (Color(0xFFFFC9B5), Color(0xFFF7A1B5)),
  (Color(0xFFB9CCFA), Color(0xFFC3A6F0)),
  (Color(0xFFF9B4D0), Color(0xFFE39AD8)),
  (Color(0xFFCDB4F5), Color(0xFF9C8CE8)),
  (Color(0xFFB5EAD7), Color(0xFF8FCFC0)),
  (Color(0xFFFFE2A8), Color(0xFFF9C08A)),
  (Color(0xFFAEE3F5), Color(0xFF93BDEB)),
  (Color(0xFFD9D3E3), Color(0xFFB9B0C9)),
];

/// A group of plans inside a shared list. Each list has its own categories,
/// which every member sees and can change.
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    this.iconKey = 'favorite',
    this.colorIndex = 0,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorIndex;

  IconData get icon => categoryIcons[iconKey] ?? Icons.label_rounded;

  (Color, Color) get _colors =>
      categoryColors[colorIndex % categoryColors.length];
  Color get colorA => _colors.$1;
  Color get colorB => _colors.$2;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [colorA, colorB],
  );

  Category copyWith({String? name, String? iconKey, int? colorIndex}) =>
      Category(
        id: id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        colorIndex: colorIndex ?? this.colorIndex,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': iconKey,
    'color': colorIndex,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    iconKey: json['icon'] as String? ?? 'favorite',
    colorIndex: (json['color'] as num?)?.toInt() ?? 0,
  );

  /// Suggested when creating a list, and used by lists made before
  /// categories were editable.
  static const defaults = [
    Category(
      id: 'restaurantes',
      name: 'Restaurantes',
      iconKey: 'restaurant',
      colorIndex: 0,
    ),
    Category(id: 'viajes', name: 'Viajes', iconKey: 'flight', colorIndex: 1),
    Category(id: 'planes', name: 'Planes', iconKey: 'favorite', colorIndex: 2),
    Category(id: 'series', name: 'Series', iconKey: 'movie', colorIndex: 3),
  ];

  /// Stands in for a category that no longer exists.
  static const none = Category(
    id: '',
    name: 'Sin categoría',
    iconKey: 'none',
    colorIndex: 7,
  );
}
