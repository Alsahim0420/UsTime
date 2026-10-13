import 'package:flutter/material.dart';

import '../data/bucket_repository.dart';
import '../models/bucket_item.dart';
import '../theme.dart';
import 'avatar.dart';
import 'stored_image.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.imageFor,
    required this.onTap,
    required this.onToggleDone,
    required this.onOpenLink,
  });

  final BucketItem item;
  final Future<ImageData?> Function(String id) imageFor;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final meta = [
      if (item.location.isNotEmpty) item.location,
      if (item.note.isNotEmpty) item.note,
    ].join(' · ');

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: item.done ? 0.72 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: palette.shadow(),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _Thumb(item: item, imageFor: imageFor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: palette.muted,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.muted,
                            ),
                          ),
                        ],
                        if (_hasPills) ...[
                          const SizedBox(height: 7),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: _pills(palette)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CheckButton(done: item.done, onPressed: onToggleDone),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasPills =>
      item.done ||
      item.plannedAt != null ||
      item.links.isNotEmpty ||
      item.imageIds.length > 1;

  List<Widget> _pills(AppPalette palette) {
    final doneAt = item.doneAt;
    final doneBy = item.doneBy;
    final plannedAt = item.plannedAt;
    return [
      if (item.done)
        _Pill(
          icon: Icons.favorite_rounded,
          leading: doneBy == null
              ? null
              : Avatar(photoUrl: doneBy.photoUrl, name: doneBy.name, size: 16),
          tooltip: doneBy == null ? null : 'Lo cumplió ${doneBy.shortName}',
          label: doneAt == null ? 'Cumplido' : formatDate(doneAt),
          color: AppColors.done,
        ),
      if (!item.done && plannedAt != null)
        _Pill(
          icon: Icons.event_rounded,
          label: formatDate(plannedAt),
          color: AppColors.rose,
        ),
      if (item.links.isNotEmpty)
        _Pill(
          icon: Icons.link_rounded,
          label: item.links.length == 1
              ? linkLabel(item.links.first)
              : '${item.links.length} links',
          color: palette.amethyst,
          onTap: item.links.length == 1
              ? () => onOpenLink(item.links.first)
              : null,
        ),
      if (item.imageIds.length > 1)
        _Pill(
          icon: Icons.photo_library_outlined,
          label: '${item.imageIds.length}',
          color: AppColors.rose,
        ),
    ];
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item, required this.imageFor});

  final BucketItem item;
  final Future<ImageData?> Function(String id) imageFor;

  @override
  Widget build(BuildContext context) {
    final createdBy = item.createdBy;
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox.square(
        dimension: 76,
        child: item.imageIds.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(gradient: item.category.gradient),
                child: Center(
                  child: Icon(
                    item.category.icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              )
            : StoredImage(image: imageFor(item.imageIds.first)),
      ),
    );
    if (createdBy == null) return thumb;

    // Whoever added the plan, tucked into the corner of the picture.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        thumb,
        Positioned(
          right: -5,
          bottom: -5,
          child: Tooltip(
            message: 'Lo agregó ${createdBy.shortName}',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: context.palette.surface,
                shape: BoxShape.circle,
              ),
              child: Avatar(
                photoUrl: createdBy.photoUrl,
                name: createdBy.name,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.onPressed});

  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: done ? 'Marcar como pendiente' : '¡Ya lo hicimos!',
      child: InkResponse(
        onTap: onPressed,
        radius: 28,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done ? AppColors.hero : null,
              border: done
                  ? null
                  : Border.all(
                      color: palette.muted.withValues(alpha: 0.35),
                      width: 2,
                    ),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 20,
              color: done
                  ? Colors.white
                  : palette.muted.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    this.leading,
    this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  /// Replaces the icon, e.g. with a person's avatar.
  final Widget? leading;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pill = Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                leading ?? Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final tooltip = this.tooltip;
    return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
  }
}
