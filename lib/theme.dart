import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors that are the same in the light and dark themes.
abstract final class AppColors {
  static const rose = Color(0xFFE58FB1);
  static const done = Color(0xFF7CC6A4);
  static const danger = Color(0xFFD0607A);

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3A6C8), Color(0xFFB893E6), Color(0xFF9A86E0)],
  );
}

/// Colors that change with the theme. Read them with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.ink,
    required this.muted,
    required this.amethyst,
    required this.surface,
    required this.canvas,
    required this.soft,
    required this.line,
    required this.shadowColor,
    required this.background,
  });

  /// Main text.
  final Color ink;

  /// Secondary text and icons.
  final Color muted;

  /// Accent for actions and selected states.
  final Color amethyst;

  /// Cards and input fields.
  final Color surface;

  /// Dialog and page base, slightly tinted.
  final Color canvas;

  /// Subtle fill for selected or grouped content.
  final Color soft;

  /// Borders and dividers.
  final Color line;

  final Color shadowColor;

  /// Page backdrop.
  final LinearGradient background;

  static const light = AppPalette(
    ink: Color(0xFF3B2F4F),
    muted: Color(0xFF8C819E),
    amethyst: Color(0xFF8E6BBF),
    surface: Colors.white,
    canvas: Color(0xFFFDF3F7),
    soft: Color(0xFFF1ECFF),
    line: Color(0xFFEDE4F5),
    shadowColor: Color(0x1A8E6BBF),
    background: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFDF3F7), Color(0xFFF1ECFF)],
    ),
  );

  static const dark = AppPalette(
    ink: Color(0xFFF3ECFA),
    muted: Color(0xFFA99DBD),
    amethyst: Color(0xFFB79CED),
    surface: Color(0xFF2A2138),
    canvas: Color(0xFF211A2D),
    soft: Color(0xFF362A4D),
    line: Color(0xFF3D3150),
    shadowColor: Color(0x40000000),
    background: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1D1627), Color(0xFF251B36)],
    ),
  );

  List<BoxShadow> shadow([double strength = 1]) => [
    BoxShadow(
      color: shadowColor.withValues(
        alpha: (shadowColor.a * strength).clamp(0.0, 1.0),
      ),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      amethyst: Color.lerp(amethyst, other.amethyst, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      line: Color.lerp(line, other.line, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      background: LinearGradient.lerp(background, other.background, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Serif style for titles. Without [color] it follows the theme's text color.
TextStyle displayStyle({double size = 32, Color? color}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.1,
      color: color,
    );

ThemeData buildTheme(Brightness brightness) {
  final palette = brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF8E6BBF),
    brightness: brightness,
    primary: palette.amethyst,
    secondary: AppColors.rose,
    surface: palette.surface,
    onSurface: palette.ink,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final radius = BorderRadius.circular(16);

  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    extensions: [palette],
    scaffoldBackgroundColor: palette.canvas,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: palette.ink, displayColor: palette.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: TextStyle(color: palette.muted),
      labelStyle: TextStyle(color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(palette.line),
      enabledBorder: border(palette.line),
      focusedBorder: border(palette.amethyst, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF3B2F4F),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
  );
}
