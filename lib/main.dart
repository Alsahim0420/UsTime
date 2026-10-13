import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'theme.dart';
import 'ui/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    // Keep the session in this browser until the person signs out, even
    // after closing the tab or restarting the computer.
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  await _preloadFonts();
  runApp(const UsTimeApp());
}

/// Loads the fonts the app uses before the first frame, so text doesn't
/// flash in a fallback font. Gives up after a moment on a slow connection.
Future<void> _preloadFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.fraunces(fontWeight: FontWeight.w600),
      for (final weight in const [
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
      ])
        GoogleFonts.plusJakartaSans(fontWeight: weight),
    ]).timeout(const Duration(seconds: 4));
  } catch (_) {
    // The fonts keep loading in the background and swap in when ready.
  }
}

class UsTimeApp extends StatefulWidget {
  const UsTimeApp({super.key});

  @override
  State<UsTimeApp> createState() => _UsTimeAppState();
}

class _UsTimeAppState extends State<UsTimeApp> {
  /// Follows the signed-in user's setting; the system theme otherwise.
  final _themeMode = ValueNotifier(ThemeMode.system);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _themeMode,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'Us Time',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: themeMode,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: AuthGate(themeMode: _themeMode),
      ),
    );
  }
}
