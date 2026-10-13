import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/space.dart';
import '../state/account_controller.dart';
import '../theme.dart';
import 'category_editor.dart';
import 'page_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.account});

  final AccountController account;

  Future<void> _signOut(BuildContext context) async {
    // Close the pages stacked on top of the list before the session ends.
    Navigator.of(context).popUntil((route) => route.isFirst);
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _saveCategories(
    BuildContext context,
    Space space,
    List<Category> categories,
  ) async {
    try {
      await account.saveCategories(space, categories);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            width: 420,
            content: Text('No se pudo guardar. Revisa tu conexión.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final space = account.activeSpace;
        return SubPage(
          title: 'Ajustes',
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tema',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Se guarda en tu cuenta y aplica en todos tus dispositivos.',
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('Sistema'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Oscuro'),
                      ),
                    ],
                    selected: {account.themeMode},
                    onSelectionChanged: (value) =>
                        account.setThemeMode(value.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: palette.soft,
                      selectedForegroundColor: palette.amethyst,
                      side: BorderSide(color: palette.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            if (space != null) ...[
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'De la lista «${space.name}». Todas las personas de la '
                      'lista las ven y pueden cambiarlas.',
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                    const SizedBox(height: 16),
                    CategoryListEditor(
                      categories: space.categories,
                      confirmRemoval: true,
                      onChanged: (categories) =>
                          _saveCategories(context, space, categories),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SectionCard(
              padding: EdgeInsets.zero,
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  onTap: () => _signOut(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
