import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/bucket_repository.dart';
import '../models/bucket_item.dart';
import '../state/bucket_controller.dart';
import '../theme.dart';
import 'stored_image.dart';

enum EditorResult { saved, deleteRequested }

Future<void> openLink(String link) async {
  final uri = Uri.tryParse(link);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Opens the create/edit dialog. Saving is handled here; deleting is left to
/// the caller so it can offer an undo.
Future<EditorResult?> showItemEditor(
  BuildContext context, {
  required BucketController controller,
  BucketItem? item,
  BucketCategory? initialCategory,
}) {
  return showDialog<EditorResult>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.35),
    builder: (context) => _ItemEditor(
      controller: controller,
      item: item,
      initialCategory: initialCategory ?? BucketCategory.restaurantes,
    ),
  );
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({
    required this.controller,
    required this.item,
    required this.initialCategory,
  });

  final BucketController controller;
  final BucketItem? item;
  final BucketCategory initialCategory;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final _title = TextEditingController(text: widget.item?.title);
  late final _note = TextEditingController(text: widget.item?.note);
  late final _location = TextEditingController(text: widget.item?.location);
  final _link = TextEditingController();

  late BucketCategory _category =
      widget.item?.category ?? widget.initialCategory;
  late bool _done = widget.item?.done ?? false;
  late DateTime? _doneAt = widget.item?.doneAt;
  late DateTime? _plannedAt = widget.item?.plannedAt;
  late final List<String> _links = [...?widget.item?.links];
  late final List<String> _imageIds = [...?widget.item?.imageIds];

  /// Images picked in this session, not yet written to storage.
  final Map<String, Uint8List> _newImages = {};
  final List<String> _removedImageIds = [];

  bool _titleMissing = false;
  bool _saving = false;
  bool _saveFailed = false;

  bool get _isNew => widget.item == null;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _location.dispose();
    _link.dispose();
    super.dispose();
  }

  void _addLink() {
    final link = normalizeLink(_link.text);
    if (link.isEmpty) return;
    setState(() {
      if (!_links.contains(link)) _links.add(link);
      _link.clear();
    });
  }

  /// Opens the calendar. [onlyPast] limits the choice to today or earlier.
  Future<DateTime?> _pickDate(DateTime? current, {bool onlyPast = false}) {
    final now = DateTime.now();
    final first = DateTime(2015);
    final last = onlyPast ? now : DateTime(now.year + 10, 12, 31);
    var initial = current ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
  }

  Future<void> _pickPlannedDate() async {
    final date = await _pickDate(_plannedAt);
    if (date != null && mounted) setState(() => _plannedAt = date);
  }

  Future<void> _pickDoneDate() async {
    final date = await _pickDate(_doneAt, onlyPast: true);
    if (date != null && mounted) setState(() => _doneAt = date);
  }

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (files.isEmpty) return;
    final picked = <String, Uint8List>{
      for (final file in files)
        widget.controller.newId(): await file.readAsBytes(),
    };
    if (!mounted) return;
    setState(() {
      _newImages.addAll(picked);
      _imageIds.addAll(picked.keys);
    });
  }

  void _removeImage(String id) {
    setState(() {
      _imageIds.remove(id);
      if (_newImages.remove(id) == null) _removedImageIds.add(id);
    });
  }

  Future<ImageData?> _image(String id) {
    final fresh = _newImages[id];
    return fresh != null
        ? Future.value(ImageData.bytes(fresh))
        : widget.controller.image(id);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleMissing = true);
      return;
    }
    _addLink();
    setState(() {
      _saving = true;
      _saveFailed = false;
    });

    final existing = widget.item;
    final base =
        existing ??
        BucketItem(
          id: widget.controller.newId(),
          category: _category,
          title: title,
          createdAt: DateTime.now(),
        );
    final item = base.copyWith(
      category: _category,
      title: title,
      note: _note.text.trim(),
      location: _location.text.trim(),
      links: _links,
      imageIds: _imageIds,
      done: _done,
      doneAt: _done ? (_doneAt ?? DateTime.now()) : null,
      clearDoneAt: !_done,
      plannedAt: _plannedAt,
      clearPlannedAt: _plannedAt == null,
    );

    try {
      await widget.controller.save(
        item,
        newImages: _newImages,
        removedImageIds: _removedImageIds,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
      return;
    }
    if (mounted) Navigator.of(context).pop(EditorResult.saved);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.blush,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isNew ? 'Nueva cosita' : 'Editar cosita',
                      style: displayStyle(size: 24),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in BucketCategory.values)
                          ChoiceChip(
                            label: Text('${category.emoji}  ${category.label}'),
                            selected: _category == category,
                            showCheckmark: false,
                            backgroundColor: Colors.white,
                            selectedColor: category.colorA,
                            side: BorderSide(
                              color: _category == category
                                  ? category.colorB
                                  : AppColors.line,
                            ),
                            shape: const StadiumBorder(),
                            onSelected: (_) =>
                                setState(() => _category = category),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _title,
                      autofocus: _isNew,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: '¿Qué queremos hacer?',
                        errorText: _titleMissing ? 'Ponle un nombre' : null,
                      ),
                      onChanged: (_) {
                        if (_titleMissing) {
                          setState(() => _titleMissing = false);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Nota',
                        hintText: 'Cuándo, con quién, qué pedir…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _location,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Lugar',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: 'Fecha del plan',
                      placeholder: 'Elegir fecha',
                      icon: Icons.event_rounded,
                      value: _plannedAt,
                      onTap: _pickPlannedDate,
                      onClear: () => setState(() => _plannedAt = null),
                    ),
                    const _SectionLabel('Links'),
                    for (final link in _links)
                      _LinkRow(
                        link: link,
                        onOpen: () => openLink(link),
                        onRemove: () => setState(() => _links.remove(link)),
                      ),
                    TextField(
                      controller: _link,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'Pega un link de Instagram, Maps…',
                        prefixIcon: const Icon(Icons.link_rounded),
                        suffixIcon: IconButton(
                          tooltip: 'Agregar link',
                          onPressed: _addLink,
                          icon: const Icon(Icons.add_circle_rounded),
                          color: AppColors.amethyst,
                        ),
                      ),
                      onSubmitted: (_) => _addLink(),
                    ),
                    const _SectionLabel('Fotos'),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final id in _imageIds)
                          _ImageTile(
                            image: _image(id),
                            onRemove: () => _removeImage(id),
                          ),
                        _AddImageTile(onTap: _pickImages),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.line),
                      ),
                      child: SwitchListTile(
                        value: _done,
                        onChanged: (value) => setState(() {
                          _done = value;
                          if (value) _doneAt ??= DateTime.now();
                        }),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          '¡Ya lo hicimos!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        secondary: Icon(
                          _done
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: AppColors.rose,
                        ),
                      ),
                    ),
                    if (_done) ...[
                      const SizedBox(height: 12),
                      _DateField(
                        label: '¿Cuándo lo hicimos?',
                        placeholder: 'Elegir fecha',
                        icon: Icons.celebration_outlined,
                        value: _doneAt,
                        onTap: _pickDoneDate,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 24, 20),
              child: Row(
                children: [
                  if (!_isNew)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context)
                              .pop(EditorResult.deleteRequested),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD0607A),
                      ),
                    ),
                  Expanded(
                    child: _saveFailed
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'No se pudo guardar. Revisa tu conexión.',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFFD0607A),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_isNew ? 'Agregar' : 'Guardar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String placeholder;
  final IconData icon;
  final DateTime? value;
  final VoidCallback onTap;

  /// When set, a button to remove the date is shown.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.only(left: 14, right: 6),
        onTap: onTap,
        leading: Icon(icon, color: AppColors.amethyst),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
        subtitle: Text(
          value == null ? placeholder : formatDate(value),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: value == null ? AppColors.muted : AppColors.ink,
          ),
        ),
        trailing: value != null && onClear != null
            ? IconButton(
                tooltip: 'Quitar fecha',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            : const Icon(Icons.edit_calendar_outlined, color: AppColors.muted),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.link,
    required this.onOpen,
    required this.onRemove,
  });

  final String link;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 14, right: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: onOpen,
          leading: const Icon(
            Icons.open_in_new_rounded,
            size: 18,
            color: AppColors.amethyst,
          ),
          title: Text(
            linkLabel(link),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            tooltip: 'Quitar link',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image, required this.onRemove});

  final Future<ImageData?> image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 92,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: () => showImageViewer(context, image),
              child: StoredImage(image: image),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: const SizedBox.square(
          dimension: 92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: AppColors.rose),
              SizedBox(height: 4),
              Text(
                'Galería',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
