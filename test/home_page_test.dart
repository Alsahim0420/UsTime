import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ustime/data/bucket_repository.dart';
import 'package:ustime/data/seed_data.dart';
import 'package:ustime/models/bucket_item.dart';
import 'package:ustime/state/bucket_controller.dart';
import 'package:ustime/theme.dart';
import 'package:ustime/ui/home_page.dart';

class _SeededRepository implements BucketRepository {
  final items = {for (final item in buildSeedItems()) item.id: item};

  @override
  Future<List<BucketItem>> loadItems() async => items.values.toList();
  @override
  Future<void> saveItem(BucketItem item) async => items[item.id] = item;
  @override
  Future<void> deleteItem(String id) async => items.remove(id);
  @override
  Future<void> saveImage(String id, Uint8List bytes) async {}
  @override
  Future<Uint8List?> loadImage(String id) async => null;
  @override
  Future<void> deleteImage(String id) async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final size in const [Size(390, 844), Size(1280, 900)]) {
    testWidgets('add, check and delete at ${size.width.round()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = BucketController(_SeededRepository());
      await controller.load();
      final total = controller.total;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: HomePage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 de $total cumplidos'), findsOneWidget);
      expect(find.text('Cosaica'), findsOneWidget);

      // Mark the first item as done.
      await tester.tap(find.byIcon(Icons.check_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('1 de $total cumplidos'), findsOneWidget);

      // Add a new item with a link.
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '¿Qué queremos hacer?'),
        'Ver el amanecer',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Pega un link de Instagram, Maps…'),
        'maps.google.com/x',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
      await tester.pumpAndSettle();
      expect(controller.total, total + 1);
      expect(controller.items.first.title, 'Ver el amanecer');
      expect(controller.items.first.links, ['https://maps.google.com/x']);

      // Edit it, then delete it and undo.
      await tester.tap(find.text('Ver el amanecer'));
      await tester.pumpAndSettle();
      expect(find.text('Editar cosita'), findsOneWidget);
      await tester.ensureVisible(find.text('Eliminar'));
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(controller.total, total);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(controller.total, total + 1);

      // Pick a real date for the plan and change the day it was done.
      await tester.tap(find.text('Ver el amanecer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Fecha del plan'));
      await tester.tap(find.text('Fecha del plan'));
      await tester.pumpAndSettle();
      final ok = MaterialLocalizations.of(tester.element(find.text('15')))
          .okButtonLabel;
      await tester.tap(find.text('15'));
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('¡Ya lo hicimos!'));
      await tester.tap(find.text('¡Ya lo hicimos!'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('¿Cuándo lo hicimos?'));
      await tester.tap(find.text('¿Cuándo lo hicimos?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      final edited = controller.items.firstWhere(
        (i) => i.title == 'Ver el amanecer',
      );
      expect(edited.plannedAt?.day, 15);
      expect(edited.done, isTrue);
      expect(edited.doneAt?.day, 1);

      // Filter by category.
      await tester.ensureVisible(find.text('Series'));
      await tester.tap(find.text('Series'));
      await tester.pumpAndSettle();
      expect(find.text('Gossip Girl'), findsOneWidget);
      expect(find.text('Cosaica'), findsNothing);
    });
  }
}
