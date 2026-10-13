import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ustime/data/bucket_repository.dart';
import 'package:ustime/data/spaces_repository.dart';
import 'package:ustime/models/bucket_item.dart';
import 'package:ustime/models/category.dart';
import 'package:ustime/models/space.dart';
import 'package:ustime/state/account_controller.dart';
import 'package:ustime/state/bucket_controller.dart';
import 'package:ustime/theme.dart';
import 'package:ustime/ui/home_page.dart';
import 'package:ustime/ui/profile_page.dart';
import 'package:ustime/ui/settings_page.dart';

import 'sample_items.dart';

class _FakeSpaces implements SpacesRepository {
  @override
  Stream<UserPrefs> watchPrefs(String uid) =>
      Stream.value(const UserPrefs(activeSpaceId: 's1', theme: 'dark'));

  @override
  Stream<List<Space>> watchSpaces(String uid) => Stream.value([
    for (final (i, name) in const [
      'Nuestra lista',
      'Viaje con los amigos de la universidad',
      'Familia',
    ].indexed)
      Space(
        id: 's${i + 1}',
        name: name,
        code: '48291$i',
        ownerUid: 'u1',
        members: const ['u1', 'u2'],
      ),
  ]);

  @override
  Future<String> createSpace(String uid, String name, List<Category> c) =>
      throw UnimplementedError();
  @override
  Future<String> joinSpace(String uid, String code) =>
      throw UnimplementedError();
  @override
  Future<void> saveCategories(
    String spaceId,
    List<Category> categories,
  ) async {}
  @override
  Future<void> setActiveSpace(String uid, String spaceId) async {}
  @override
  Future<void> setTheme(String uid, String? theme) async {}
}

class _Items implements BucketRepository {
  @override
  Stream<List<BucketItem>> watchItems() => Stream.value([
    for (final item in sampleItems())
      item.copyWith(
        title: '${item.title} con un nombre bastante largo para probar',
        note: 'Una nota larga que no debería desbordar la tarjeta',
        links: const ['https://www.instagram.com/reel/abc'],
        plannedAt: DateTime(2026, 12, 24),
      ),
  ]);
  @override
  Future<void> saveItem(BucketItem item) async {}
  @override
  Future<void> deleteItem(String id) async {}
  @override
  Future<void> saveImage(String id, bytes) async {}
  @override
  Future<ImageData?> loadImage(String id) async => null;
  @override
  Future<void> deleteImage(String id) async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Small phone, phone, tablet, laptop, large desktop.
  const widths = [320.0, 390.0, 768.0, 1024.0, 1440.0];

  Future<void> pumpAt(WidgetTester tester, double width, Widget page) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(Brightness.light), home: page),
    );
    await tester.pumpAndSettle();
    // A layout overflow is reported as an exception.
    expect(tester.takeException(), isNull);
  }

  for (final width in widths) {
    testWidgets('profile fits at ${width.round()}px', (tester) async {
      final account = AccountController('u1', _FakeSpaces())..start();
      addTearDown(account.dispose);
      await pumpAt(
        tester,
        width,
        ProfilePage(
          account: account,
          name: 'Pablo Andrés Melo Cárdenas de la Torre',
          email: 'un.correo.bastante.largo.para.probar@gmail.com',
          photoUrl: null,
        ),
      );
      expect(find.text('Listas compartidas'), findsOneWidget);
      expect(find.text('482 910'), findsOneWidget);
    });

    testWidgets('settings fit at ${width.round()}px', (tester) async {
      final account = AccountController('u1', _FakeSpaces())..start();
      addTearDown(account.dispose);
      await pumpAt(tester, width, SettingsPage(account: account));
      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('home fits at ${width.round()}px', (tester) async {
      final controller = BucketController(_Items());
      await controller.load();
      await pumpAt(
        tester,
        width,
        HomePage(
          controller: controller,
          title: 'Viaje con los amigos de la universidad',
          trailing: const CircleAvatar(radius: 19),
        ),
      );
      // The editor too, since it is the densest dialog.
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Nueva cosita'), findsOneWidget);
    });
  }
}
