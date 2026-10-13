import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const ink = Color(0xFF3B2F4F);
  static const muted = Color(0xFF8C819E);
  static const amethyst = Color(0xFF8E6BBF);
  static const rose = Color(0xFFE58FB1);
  static const blush = Color(0xFFFDF3F7);
  static const lavender = Color(0xFFF1ECFF);
  static const line = Color(0xFFEDE4F5);
  static const done = Color(0xFF7CC6A4);

  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blush, lavender],
  );

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3A6C8), Color(0xFFB893E6), Color(0xFF9A86E0)],
  );
}

List<BoxShadow> softShadow([double strength = 1]) => [
  BoxShadow(
    color: AppColors.amethyst.withValues(alpha: 0.10 * strength),
    blurRadius: 28,
    offset: const Offset(0, 12),
  ),
];

TextStyle displayStyle({double size = 32, Color color = AppColors.ink}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.1,
      color: color,
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.amethyst,
    primary: AppColors.amethyst,
    secondary: AppColors.rose,
    surface: Colors.white,
    onSurface: AppColors.ink,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final radius = BorderRadius.circular(16);

  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.blush,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.amethyst, 1.5),
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
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
  );
}
