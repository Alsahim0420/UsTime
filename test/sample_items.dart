import 'package:ustime/models/bucket_item.dart';

/// A small list for tests, already in display order (newest first).
List<BucketItem> sampleItems() {
  BucketItem item(int i, String category, String title) => BucketItem(
    id: 'sample-$i',
    category: category,
    title: title,
    createdAt: DateTime(2026, 1, 1).subtract(Duration(minutes: i)),
  );

  return [
    item(0, 'restaurantes', 'Cosaica'),
    item(1, 'viajes', 'Grecia'),
    item(2, 'series', 'Gossip Girl'),
  ];
}
