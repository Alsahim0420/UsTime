import 'package:ustime/models/bucket_item.dart';

/// A small list for tests, already in display order (newest first).
List<BucketItem> sampleItems() {
  BucketItem item(int i, BucketCategory category, String title) => BucketItem(
    id: 'sample-$i',
    category: category,
    title: title,
    createdAt: DateTime(2026, 1, 1).subtract(Duration(minutes: i)),
  );

  return [
    item(0, BucketCategory.restaurantes, 'Cosaica'),
    item(1, BucketCategory.viajes, 'Grecia'),
    item(2, BucketCategory.series, 'Gossip Girl'),
  ];
}
