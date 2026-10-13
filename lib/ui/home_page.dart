import 'package:flutter/material.dart';

import '../models/bucket_item.dart';
import '../state/bucket_controller.dart';
import '../theme.dart';
import 'item_card.dart';
import 'item_editor.dart';

enum _Status {
  all('Todos'),
  pending('Pendientes'),
  done('Cumplidos');

  const _Status(this.label);
  final String label;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller, this.onSignOut});

  final BucketController controller;

  /// When set, a sign-out button is shown in the header.
  final VoidCallback? onSignOut;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  BucketCategory? _category;
  _Status _status = _Status.all;

  BucketController get _controller => widget.controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BucketItem> get _visibleItems {
    final query = _search.text.trim().toLowerCase();
    return _controller.items.where((item) {
      if (_category != null && item.category != _category) return false;
      if (_status == _Status.pending && item.done) return false;
      if (_status == _Status.done && !item.done) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.note.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openEditor([BucketItem? item]) async {
    final result = await showItemEditor(
      context,
      controller: _controller,
      item: item,
      initialCategory: _category,
    );
    if (result == EditorResult.deleteRequested && item != null) {
      await _delete(item);
    }
  }

  /// Runs a write and tells the user if it fails (offline, no permission).
  /// Returns whether it succeeded.
  Future<bool> _guard(Future<void> write) async {
    try {
      await write;
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              width: 420,
              content: Text(
                'No se pudo guardar el cambio. Revisa tu conexión.',
              ),
            ),
          );
      }
      return false;
    }
  }

  Future<void> _delete(BucketItem item) async {
    if (!await _guard(_controller.remove(item))) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    final snackBar = messenger.showSnackBar(
      SnackBar(
        width: 420,
        persist: false,
        content: Text('Eliminaste "${item.title}"'),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: const Color(0xFFF7B6D2),
          onPressed: () => _guard(_controller.save(item)),
        ),
      ),
    );
    final reason = await snackBar.closed;
    if (reason != SnackBarClosedReason.action) {
      await _controller.purgeImages(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        backgroundColor: AppColors.amethyst,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Agregar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.background),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildContent();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final items = _visibleItems;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the content in a centered column on wide screens.
        final side = ((constraints.maxWidth - 1120) / 2).clamp(16.0, 4000.0);
        final padding = EdgeInsets.symmetric(horizontal: side);

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: padding.copyWith(top: 28),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'US TIME',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amethyst,
                            ),
                          ),
                        ),
                        if (widget.onSignOut != null)
                          IconButton(
                            tooltip: 'Cerrar sesión',
                            onPressed: widget.onSignOut,
                            visualDensity: VisualDensity.compact,
                            color: AppColors.muted,
                            icon: const Icon(Icons.logout_rounded, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nuestra lista de cositas',
                      style: displayStyle(
                        size: constraints.maxWidth < 600 ? 30 : 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProgressCard(
                      done: _controller.doneCount,
                      total: _controller.total,
                    ),
                    const SizedBox(height: 20),
                    _buildFilters(constraints.maxWidth >= 720),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: padding,
                child: Row(
                  children: [
                    _CategoryChip(
                      label: 'Todo',
                      emoji: '✨',
                      count: _controller.total,
                      selected: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    for (final category in BucketCategory.values)
                      _CategoryChip(
                        label: category.label,
                        emoji: category.emoji,
                        count: _controller.countFor(category),
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                      ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  filtered: _controller.total > 0,
                  onAdd: _openEditor,
                ),
              )
            else
              SliverPadding(
                padding: padding.copyWith(top: 18, bottom: 110),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 128,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ItemCard(
                      key: ValueKey(item.id),
                      item: item,
                      imageFor: _controller.image,
                      onTap: () => _openEditor(item),
                      onToggleDone: () => _guard(_controller.toggleDone(item)),
                      onOpenLink: openLink,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(bool wide) {
    final search = TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Buscar un plan, un lugar…',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(_search.clear),
              ),
      ),
    );
    final status = SegmentedButton<_Status>(
      showSelectedIcon: false,
      segments: [
        for (final status in _Status.values)
          ButtonSegment(value: status, label: Text(status.label)),
      ],
      selected: {_status},
      onSelectionChanged: (value) => setState(() => _status = value.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        selectedBackgroundColor: AppColors.lavender,
        selectedForegroundColor: AppColors.amethyst,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );

    if (wide) {
      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 14),
          status,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [search, const SizedBox(height: 12), status],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    final pending = total - done;
    final message = total == 0
        ? 'Agreguen su primer plan juntos'
        : pending == 0
        ? '¡Lo cumplieron todo! Hora de soñar más'
        : pending == 1
        ? 'Solo falta 1 por vivir juntos'
        : 'Nos faltan $pending por vivir juntos';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.hero,
        borderRadius: BorderRadius.circular(28),
        boxShadow: softShadow(2.4),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 78,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done de $total cumplidos',
                  style: displayStyle(size: 24, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.amethyst : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppColors.amethyst : AppColors.line,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: foreground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onAdd});

  /// True when the list has items but the current filters hide them all.
  final bool filtered;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐼❤️🐻', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            filtered ? 'Nada por aquí' : 'Su lista está vacía',
            style: displayStyle(size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'Prueben con otra búsqueda o filtro.'
                : 'Agreguen el primer plan que quieran vivir juntos.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (!filtered) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar'),
            ),
          ],
        ],
      ),
    );
  }
}
