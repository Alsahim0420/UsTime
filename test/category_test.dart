import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ustime/models/category.dart';
import 'package:ustime/models/space.dart';
import 'package:ustime/theme.dart';
import 'package:ustime/ui/category_editor.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('categories survive a JSON round trip', () {
    const category = Category(
      id: 'c1',
      name: 'Cafés',
      iconKey: 'cafe',
      colorIndex: 4,
    );
    final copy = Category.fromJson(category.toJson());
    expect(copy.toJson(), category.toJson());
    expect(copy.icon, categoryIcons['cafe']);
  });

  test('lists without stored categories get the defaults', () {
    final legacy = Space.fromJson('s1', {'name': 'Nuestra lista'});
    expect(legacy.categories, Category.defaults);

    final emptied = Space.fromJson('s2', {'name': 'Otra', 'categories': []});
    expect(emptied.categories, isEmpty);
  });

  for (final brightness in Brightness.values) {
    testWidgets('add, edit and remove categories (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var categories = Category.defaults;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => CategoryListEditor(
                categories: categories,
                confirmRemoval: true,
                onChanged: (value) => setState(() => categories = value),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Nueva categoría'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cafés');
      await tester.tap(find.byIcon(categoryIcons['cafe']!));
      await tester.tap(find.byTooltip('Color 5'));
      await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
      await tester.pumpAndSettle();
      expect(categories.last.name, 'Cafés');
      expect(categories.last.iconKey, 'cafe');
      expect(categories.last.colorIndex, 4);

      await tester.tap(find.text('Viajes'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Escapadas');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(categories[1].name, 'Escapadas');
      expect(categories[1].id, 'viajes');

      await tester.tap(find.byTooltip('Eliminar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(categories.map((c) => c.id), isNot(contains('restaurantes')));
      expect(categories.length, 4);
    });
  }
}
