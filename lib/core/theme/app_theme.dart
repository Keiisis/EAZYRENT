// Construit les 3 ThemeData depuis AppPalette. Aucune couleur n'est décidée
// ici : tout vient de design_tokens.dart (GATES.md G13).

import 'package:flutter/material.dart';

import 'design_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  /// Plein Soleil — cible AAA. Motivé par le climat et le matériel, pas par le
  /// handicap : il sert tout le monde (UI_DESIGN_SYSTEM.md §2.5).
  static ThemeData sunlight() => _build(AppPalette.sunlight, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final touch = Touch.target(p.isHighContrast);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.surfaceBase,
      extensions: <ThemeExtension<dynamic>>[p],

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.actionFill,
        onPrimary: p.actionOnFill,
        secondary: p.success,
        onSecondary: p.surfaceBase,
        error: p.danger,
        onError: p.surfaceRaised,
        surface: p.surfaceRaised,
        onSurface: p.inkBase,
      ),

      textTheme: TextTheme(
        displayLarge: AppText.displayL.copyWith(color: p.inkStrong),
        displayMedium: AppText.displayM.copyWith(color: p.inkStrong),
        titleLarge: AppText.titleL.copyWith(color: p.inkStrong),
        titleMedium: AppText.titleM.copyWith(color: p.inkStrong),
        bodyLarge: AppText.bodyL.copyWith(color: p.inkBase),
        bodyMedium: AppText.bodyM.copyWith(color: p.inkBase),
        labelLarge: AppText.label.copyWith(color: p.inkBase),
        bodySmall: AppText.caption.copyWith(color: p.inkMuted),
      ),

      // Élévation TONALE d'abord. Pas d'ombre par défaut, pas de
      // BackdropFilter : premier poste de perte de framerate sur Mali-G52.
      cardTheme: CardThemeData(
        color: p.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radii.card),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.actionFill,
          foregroundColor: p.actionOnFill,
          minimumSize: Size(touch, touch),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radii.pill),
          ),
          textStyle: AppText.label,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSunken,
        // Étiquette persistante, jamais un placeholder seul : un placeholder
        // qui disparaît à la saisie laisse l'utilisateur sans repère.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radii.input),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
      ),

      // Anneau de focus : contraste ≥ 3:1, APPARITION INSTANTANÉE.
      // Un anneau animé est un anneau qu'on rate.
      focusColor: p.action,

      splashFactory: NoSplash.splashFactory, // le retour est `press` + haptique
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()},
      ),
    );
  }
}

extension PaletteOf on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
