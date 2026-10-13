import 'bucket_item.dart';

/// Describes what an edit changed between [before] and [after], one readable
/// line per field. Marking as done/pending is not included; it gets its own
/// entry in the activity log. [categoryName] turns a category id into its name.
List<String> describeChanges(
  BucketItem before,
  BucketItem after, {
  String Function(String categoryId)? categoryName,
}) {
  String quote(String value) {
    if (value.isEmpty) return 'vacío';
    return '«${value.length > 60 ? '${value.substring(0, 60)}…' : value}»';
  }

  String date(DateTime? value) =>
      value == null ? 'sin fecha' : formatDate(value);

  bool sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String counted(int count, String one, String many) =>
      count == 1 ? '1 $one' : '$count $many';

  final changes = <String>[];

  void text(String label, String a, String b) {
    if (a != b) changes.add('$label: ${quote(a)} → ${quote(b)}');
  }

  void list(List<String> a, List<String> b, String one, String many) {
    final added = b.where((e) => !a.contains(e)).length;
    final removed = a.where((e) => !b.contains(e)).length;
    if (added > 0) changes.add('Agregó ${counted(added, one, many)}');
    if (removed > 0) changes.add('Quitó ${counted(removed, one, many)}');
  }

  text('Nombre', before.title, after.title);
  if (before.category != after.category) {
    final name = categoryName ?? (id) => id;
    changes.add(
      'Categoría: ${name(before.category)} → ${name(after.category)}',
    );
  }
  text('Nota', before.note, after.note);
  text('Lugar', before.location, after.location);
  if (!sameDay(before.plannedAt, after.plannedAt)) {
    changes.add(
      'Fecha del plan: ${date(before.plannedAt)} → ${date(after.plannedAt)}',
    );
  }
  list(before.links, after.links, 'link', 'links');
  list(before.imageIds, after.imageIds, 'foto', 'fotos');
  // Only when it stays done; otherwise the done/pending entry covers it.
  if (before.done && after.done && !sameDay(before.doneAt, after.doneAt)) {
    changes.add(
      'Fecha de cumplido: ${date(before.doneAt)} → ${date(after.doneAt)}',
    );
  }
  return changes;
}
