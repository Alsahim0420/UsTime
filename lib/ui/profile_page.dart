import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/space.dart';
import '../state/account_controller.dart';
import '../theme.dart';
import 'avatar.dart';
import 'page_scaffold.dart';
import 'settings_page.dart';
import 'space_dialogs.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, required this.account});

  final User user;
  final AccountController account;

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsPage(account: account),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final active = account.activeSpace;
        return SubPage(
          title: 'Perfil',
          action: IconButton(
            tooltip: 'Ajustes',
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          children: [
            SectionCard(
              child: Column(
                children: [
                  Avatar(
                    photoUrl: user.photoURL,
                    name: user.displayName,
                    size: 88,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.displayName ?? 'Sin nombre',
                    textAlign: TextAlign.center,
                    style: displayStyle(size: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.muted),
                  ),
                ],
              ),
            ),
            const SectionLabel('Listas compartidas'),
            for (final space in account.spaces)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SpaceCard(
                  space: space,
                  active: space.id == active?.id,
                  onSelect: () => account.selectSpace(space),
                ),
              ),
            if (account.spaces.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
                child: Text(
                  'Todavía no tienes listas. Crea una o únete con un código.',
                  style: TextStyle(color: palette.muted),
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => showCreateSpaceDialog(context, account),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crear lista'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showJoinSpaceDialog(context, account),
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Unirme con código'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: palette.line),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.space,
    required this.active,
    required this.onSelect,
  });

  final Space space;
  final bool active;
  final VoidCallback onSelect;

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: space.code));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(width: 320, content: Text('Código copiado')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final people = space.members.length;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: active ? palette.amethyst : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: palette.shadow(),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: active ? null : onSelect,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        space.name,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (active)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: palette.soft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'En uso',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.amethyst,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  people == 1 ? 'Solo tú por ahora' : '$people personas',
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Código para invitar',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.muted,
                            ),
                          ),
                          SelectableText(
                            formatSpaceCode(space.code),
                            style: TextStyle(
                              fontSize: 26,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w800,
                              color: palette.amethyst,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _copyCode(context),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
