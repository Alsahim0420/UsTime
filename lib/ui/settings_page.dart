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
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final space = account.activeSpace;

        final appearance = SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeading(
                title: 'Apariencia',
                description:
                    'Se guarda en tu cuenta y aplica en todos tus '
                    'dispositivos.',
              ),
              const SizedBox(height: 16),
              for (final option in _themeOptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ThemeOption(
                    option: option,
                    selected: account.themeMode == option.mode,
                    onTap: () => account.setThemeMode(option.mode),
                  ),
                ),
            ],
          ),
        );

        final categories = space == null
            ? null
            : SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeading(
                      title: 'Categorías',
                      description:
                          'De la lista «${space.name}». Todas las personas '
                          'de la lista las ven y pueden cambiarlas. Toca una '
                          'para editarla.',
                    ),
                    const SizedBox(height: 18),
                    CategoryListEditor(
                      categories: space.categories,
                      confirmRemoval: true,
                      onChanged: (categories) =>
                          _saveCategories(context, space, categories),
                    ),
                  ],
                ),
              );

        final session = SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                title: 'Sesión',
                description:
                    'Tu sesión queda abierta en este navegador hasta que la '
                    'cierres.',
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: AppColors.danger.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        );

        return SubPage(
          title: 'Ajustes',
          subtitle: 'Apariencia, categorías de la lista y sesión.',
          builder: (context, wide) {
            const gap = SizedBox(height: 20);
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [appearance, gap, ?categories, gap, session],
              );
            }
            return SideBySide(
              wide: true,
              side: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [appearance, gap, session],
              ),
              main: categories ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

typedef _ThemeChoice = ({
  ThemeMode mode,
  IconData icon,
  String label,
  String description,
});

const _themeOptions = <_ThemeChoice>[
  (
    mode: ThemeMode.system,
    icon: Icons.brightness_auto_outlined,
    label: 'Sistema',
    description: 'Igual que tu dispositivo',
  ),
  (
    mode: ThemeMode.light,
    icon: Icons.light_mode_outlined,
    label: 'Claro',
    description: 'Rosados y lavandas suaves',
  ),
  (
    mode: ThemeMode.dark,
    icon: Icons.dark_mode_outlined,
    label: 'Oscuro',
    description: 'Morados profundos',
  ),
];

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ThemeChoice option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? palette.soft : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? palette.amethyst : palette.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                option.icon,
                color: selected ? palette.amethyst : palette.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      option.description,
                      style: TextStyle(fontSize: 12.5, color: palette.muted),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: palette.amethyst),
            ],
          ),
        ),
      ),
    );
  }
}
