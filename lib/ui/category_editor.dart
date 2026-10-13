import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category.dart';
import '../theme.dart';

/// Shows a list's categories as chips: tap one to edit it, the × to remove
/// it, and the last chip to add a new one.
class CategoryListEditor extends StatelessWidget {
  const CategoryListEditor({
    super.key,
    required this.categories,
    required this.onChanged,
    this.confirmRemoval = false,
  });

  final List<Category> categories;
  final ValueChanged<List<Category>> onChanged;

  /// Ask before removing, for categories that may already have plans.
  final bool confirmRemoval;

  Future<void> _add(BuildContext context) async {
    final created = await showCategoryDialog(
      context,
      // Start on a color the list isn't using yet.
      suggestedColor: categories.length % categoryColors.length,
    );
    if (created != null) onChanged([...categories, created]);
  }

  Future<void> _edit(BuildContext context, Category category) async {
    final edited = await showCategoryDialog(context, category: category);
    if (edited == null) return;
    onChanged([for (final c in categories) c.id == category.id ? edited : c]);
  }

  Future<void> _remove(BuildContext context, Category category) async {
    if (confirmRemoval) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Eliminar «${category.name}»?'),
          content: const Text(
            'Sus planes no se borran: quedan sin categoría y los sigues '
            'viendo en «Todo».',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    onChanged([
      for (final c in categories)
        if (c.id != category.id) c,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in categories)
          InputChip(
            avatar: _CategoryDot(category: category, size: 24),
            label: Text(category.name),
            tooltip: 'Editar',
            onPressed: () => _edit(context, category),
            onDeleted: () => _remove(context, category),
            deleteButtonTooltipMessage: 'Eliminar',
            backgroundColor: palette.surface,
            side: BorderSide(color: palette.line),
            shape: const StadiumBorder(),
          ),
        ActionChip(
          avatar: Icon(Icons.add_rounded, size: 18, color: palette.amethyst),
          label: const Text('Nueva categoría'),
          labelStyle: TextStyle(
            color: palette.amethyst,
            fontWeight: FontWeight.w600,
          ),
          onPressed: () => _add(context),
          backgroundColor: palette.soft,
          side: BorderSide.none,
          shape: const StadiumBorder(),
        ),
      ],
    );
  }
}

/// A category's icon on its gradient.
class _CategoryDot extends StatelessWidget {
  const _CategoryDot({required this.category, required this.size});

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: category.gradient,
        shape: BoxShape.circle,
      ),
      child: Icon(category.icon, size: size * 0.58, color: Colors.white),
    );
  }
}

/// Creates a category, or edits [category]. Returns null if cancelled.
Future<Category?> showCategoryDialog(
  BuildContext context, {
  Category? category,
  int suggestedColor = 0,
}) {
  return showDialog<Category>(
    context: context,
    builder: (context) =>
        _CategoryDialog(category: category, suggestedColor: suggestedColor),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.category, required this.suggestedColor});

  final Category? category;
  final int suggestedColor;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final _name = TextEditingController(text: widget.category?.name);
  late String _iconKey = widget.category?.iconKey ?? 'favorite';
  late int _colorIndex = widget.category?.colorIndex ?? widget.suggestedColor;
  bool _nameMissing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    final existing = widget.category;
    Navigator.of(context).pop(
      Category(
        id:
            existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        name: name,
        iconKey: _iconKey,
        colorIndex: _colorIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final preview = Category(
      id: '',
      name: '',
      iconKey: _iconKey,
      colorIndex: _colorIndex,
    );
    return Dialog(
      backgroundColor: palette.canvas,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryDot(category: preview, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.category == null
                          ? 'Nueva categoría'
                          : 'Editar categoría',
                      style: displayStyle(size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(24)],
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Cafés, Conciertos, Citas…',
                  errorText: _nameMissing ? 'Ponle un nombre' : null,
                ),
                onChanged: (_) {
                  if (_nameMissing) setState(() => _nameMissing = false);
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Text(
                'Color',
                style: TextStyle(fontSize: 12.5, color: palette.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < categoryColors.length; i++)
                    _Choice(
                      selected: i == _colorIndex,
                      tooltip: 'Color ${i + 1}',
                      onTap: () => setState(() => _colorIndex = i),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryColors[i].$1,
                              categoryColors[i].$2,
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Icono',
                style: TextStyle(fontSize: 12.5, color: palette.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final entry in categoryIcons.entries)
                    _Choice(
                      selected: entry.key == _iconKey,
                      tooltip: null,
                      onTap: () => setState(() => _iconKey = entry.key),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.surface,
                        ),
                        child: Icon(
                          entry.value,
                          size: 19,
                          color: entry.key == _iconKey
                              ? palette.amethyst
                              : palette.muted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(
                      widget.category == null ? 'Agregar' : 'Guardar',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round option that shows a ring when selected.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final String? tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final option = InkResponse(
      onTap: onTap,
      radius: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? context.palette.amethyst : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
    final tooltip = this.tooltip;
    return tooltip == null ? option : Tooltip(message: tooltip, child: option);
  }
}
