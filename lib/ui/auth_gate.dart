import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/firebase_bucket_repository.dart';
import '../state/bucket_controller.dart';
import '../theme.dart';
import 'home_page.dart';

/// Shows the sign-in screen until someone signs in with Google, then the
/// shared list. Who is allowed in is decided by the Firebase security rules.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Backdrop(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        if (user == null) return const _SignInPage();
        return _Session(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

/// Owns the list controller for the signed-in user.
class _Session extends StatefulWidget {
  const _Session({super.key, required this.user});

  final User user;

  @override
  State<_Session> createState() => _SessionState();
}

class _SessionState extends State<_Session> {
  final _repository = FirebaseBucketRepository();
  late final _controller = BucketController(_repository);
  late final Future<void> _ready = _start();

  Future<void> _start() async {
    await _repository.seedIfNeeded();
    await _controller.load();
    final error = _controller.error;
    if (error != null) throw error;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _NoAccessPage(email: widget.user.email, error: snapshot.error);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _Backdrop(child: CircularProgressIndicator());
        }
        return HomePage(
          controller: _controller,
          onSignOut: FirebaseAuth.instance.signOut,
        );
      },
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
    return _Backdrop(
      child: _Panel(
        children: [
          Text('Us Time', style: displayStyle(size: 34)),
          const SizedBox(height: 8),
          const Text(
            'Nuestra lista de cositas por hacer juntos',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFFD0607A)),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoAccessPage extends StatelessWidget {
  const _NoAccessPage({required this.email, required this.error});

  final String? email;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final denied =
        error is FirebaseException && error.code == 'permission-denied';
    return _Backdrop(
      child: _Panel(
        children: [
          Text(
            denied ? 'Esta lista es privada' : 'No pudimos abrir la lista',
            textAlign: TextAlign.center,
            style: displayStyle(size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            denied
                ? 'La cuenta ${email ?? ''} no tiene acceso.'
                : 'Revisa tu conexión e intenta de nuevo.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: FirebaseAuth.instance.signOut,
            child: const Text('Usar otra cuenta'),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.background),
        child: Center(child: child),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: softShadow(1.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    );
  }
}
