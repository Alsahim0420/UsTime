import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/firebase_bucket_repository.dart';
import '../data/spaces_repository.dart';
import '../models/space.dart';
import '../state/account_controller.dart';
import '../state/bucket_controller.dart';
import '../theme.dart';
import 'avatar.dart';
import 'home_page.dart';
import 'page_scaffold.dart';
import 'profile_page.dart';
import 'space_dialogs.dart';

/// Shows the sign-in screen until someone signs in with Google, then their
/// active shared list.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.themeMode});

  /// Updated with the signed-in user's theme setting.
  final ValueNotifier<ThemeMode> themeMode;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Backdrop(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        if (user == null) return const _SignInPage();
        return _Session(
          key: ValueKey(user.uid),
          user: user,
          themeMode: themeMode,
        );
      },
    );
  }
}

/// Owns the account state for the signed-in user.
class _Session extends StatefulWidget {
  const _Session({super.key, required this.user, required this.themeMode});

  final User user;
  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<_Session> createState() => _SessionState();
}

class _SessionState extends State<_Session> {
  late final _account = AccountController(widget.user.uid, SpacesRepository());

  @override
  void initState() {
    super.initState();
    _account
      ..addListener(_syncTheme)
      ..start();
  }

  void _syncTheme() => widget.themeMode.value = _account.themeMode;

  @override
  void dispose() {
    _account.dispose();
    // The next person on this device starts with the system theme. Deferred
    // because the app can't rebuild while this widget is being removed.
    final themeMode = widget.themeMode;
    Future.microtask(() => themeMode.value = ThemeMode.system);
    super.dispose();
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(user: widget.user, account: _account),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return ListenableBuilder(
      listenable: _account,
      builder: (context, _) {
        if (_account.error != null) return const _ErrorPage();
        if (_account.loading) {
          return const Backdrop(child: CircularProgressIndicator());
        }
        final space = _account.activeSpace;
        if (space == null) {
          return _WelcomePage(user: user, account: _account);
        }
        return _SpaceView(
          key: ValueKey(space.id),
          space: space,
          trailing: Tooltip(
            message: 'Perfil',
            child: InkResponse(
              onTap: _openProfile,
              radius: 26,
              child: Avatar(
                photoUrl: user.photoURL,
                name: user.displayName,
                size: 38,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shows the items of one shared list.
class _SpaceView extends StatefulWidget {
  const _SpaceView({super.key, required this.space, required this.trailing});

  final Space space;
  final Widget trailing;

  @override
  State<_SpaceView> createState() => _SpaceViewState();
}

class _SpaceViewState extends State<_SpaceView> {
  late final _controller = BucketController(
    FirebaseBucketRepository(widget.space.id),
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      controller: _controller,
      title: widget.space.name,
      trailing: widget.trailing,
    );
  }
}

/// First screen for someone who isn't in any list yet.
class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.user, required this.account});

  final User user;
  final AccountController account;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final firstName = user.displayName?.trim().split(' ').first ?? '';
    return Backdrop(
      child: _Panel(
        header: Avatar(
          photoUrl: user.photoURL,
          name: user.displayName,
          size: 72,
        ),
        children: [
          Text(
            firstName.isEmpty ? '¡Hola!' : '¡Hola, $firstName!',
            textAlign: TextAlign.center,
            style: displayStyle(size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea una lista para compartir con tu pareja o amigos, o únete '
            'a una con el código que te enviaron.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => showCreateSpaceDialog(context, account),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear una lista'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => showJoinSpaceDialog(context, account),
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Tengo un código'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: FirebaseAuth.instance.signOut,
            style: TextButton.styleFrom(foregroundColor: palette.muted),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _SignInPage extends StatefulWidget {
  const _SignInPage();

  @override
  State<_SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<_SignInPage> {
  bool _busy = false;
  String? _message;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _message = _describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _describe(FirebaseAuthException e) {
    return switch (e.code) {
      'popup-closed-by-user' || 'cancelled-popup-request' => null,
      'popup-blocked' =>
        'El navegador bloqueó la ventana de Google. Permite las ventanas '
            'emergentes e intenta de nuevo.',
      'operation-not-allowed' =>
        'Falta activar el acceso con Google en Firebase Authentication.',
      'unauthorized-domain' =>
        'Este dominio no está autorizado en Firebase Authentication.',
      _ => 'No se pudo iniciar sesión (${e.code}).',
    };
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    return Backdrop(
      child: _Panel(
        children: [
          Text('Us Time', style: displayStyle(size: 34)),
          const SizedBox(height: 8),
          Text(
            'Nuestra lista de cositas por hacer juntos',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.muted),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _busy ? null : _signIn,
            icon: const Icon(Icons.favorite_rounded, size: 18),
            label: const Text('Entrar con Google'),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage();

  @override
  Widget build(BuildContext context) {
    return Backdrop(
      child: _Panel(
        children: [
          Text(
            'No pudimos abrir tus listas',
            textAlign: TextAlign.center,
            style: displayStyle(size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            'Revisa tu conexión y vuelve a entrar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.muted),
          ),
          const SizedBox(height: 24),
          const FilledButton(onPressed: _signOut, child: Text('Cerrar sesión')),
        ],
      ),
    );
  }
}

void _signOut() => FirebaseAuth.instance.signOut();

class _Panel extends StatelessWidget {
  const _Panel({required this.children, this.header});

  /// Shown above the content; the app's heart badge by default.
  final Widget? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: palette.shadow(1.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header ??
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.hero,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
