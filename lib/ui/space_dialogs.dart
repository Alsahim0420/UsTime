import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/spaces_repository.dart';
import '../state/account_controller.dart';
import '../theme.dart';

/// Asks for a name and creates a new shared list.
Future<void> showCreateSpaceDialog(
  BuildContext context,
  AccountController account,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _SpaceDialog(
      title: 'Nueva lista',
      description:
          'Le crearemos un código de 6 dígitos para que invites a tu pareja '
          'o a tus amigos.',
      label: 'Nombre de la lista',
      hint: 'Nuestra lista',
      action: 'Crear',
      onSubmit: (value) async {
        if (value.isEmpty) return 'Ponle un nombre';
        await account.createSpace(value);
        return null;
      },
    ),
  );
}

/// Asks for a 6-digit code and joins that list.
Future<void> showJoinSpaceDialog(
  BuildContext context,
  AccountController account,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _SpaceDialog(
      title: 'Unirme a una lista',
      description: 'Escribe el código de 6 dígitos que te compartieron.',
      label: 'Código',
      hint: '000 000',
      action: 'Unirme',
      isCode: true,
      onSubmit: (value) async {
        final code = value.replaceAll(RegExp(r'\D'), '');
        if (code.length != 6) return 'El código tiene 6 dígitos';
        try {
          await account.joinSpace(code);
        } on SpaceNotFound {
          return 'No existe una lista con ese código';
        }
        return null;
      },
    ),
  );
}

class _SpaceDialog extends StatefulWidget {
  const _SpaceDialog({
    required this.title,
    required this.description,
    required this.label,
    required this.hint,
    required this.action,
    required this.onSubmit,
    this.isCode = false,
  });

  final String title;
  final String description;
  final String label;
  final String hint;
  final String action;
  final bool isCode;

  /// Returns an error message to show, or null when it worked.
  final Future<String?> Function(String value) onSubmit;

  @override
  State<_SpaceDialog> createState() => _SpaceDialogState();
}

class _SpaceDialogState extends State<_SpaceDialog> {
  final _field = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.onSubmit(_field.text.trim());
    } catch (_) {
      error = 'No se pudo completar. Revisa tu conexión.';
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Dialog(
      backgroundColor: palette.canvas,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: displayStyle(size: 24)),
              const SizedBox(height: 8),
              Text(widget.description, style: TextStyle(color: palette.muted)),
              const SizedBox(height: 20),
              TextField(
                controller: _field,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: widget.isCode ? TextInputType.number : null,
                inputFormatters: widget.isCode
                    ? [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                        LengthLimitingTextInputFormatter(7),
                      ]
                    : [LengthLimitingTextInputFormatter(40)],
                style: widget.isCode
                    ? const TextStyle(
                        fontSize: 22,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      )
                    : null,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(widget.action),
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
