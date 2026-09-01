// EAZYRENT · design tokens · v1.0
// Source de vérité unique. Aucune valeur brute (hex, sp, dp, ms) ne doit
// apparaître ailleurs dans lib/. Un widget qui contient un Color(0xFF...) est
// un bug : il rend impossible le mode Plein Soleil.
//
// Contrastes WCAG 2.1 mesurés, pas estimés. Voir UI_DESIGN_SYSTEM.md §2.1.

// FontFeature, Cubic et Color viennent de material.dart (ré-export de dart:ui
// via painting/animation) : pas d'import dart:ui, il créerait une ambiguïté.
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// COULEUR
// ---------------------------------------------------------------------------

/// Accents en deux variantes : `vivid` pour les fonds sombres et les
/// remplissages, `ink` pour le texte sur fond clair.
///
/// La charte v1.0 n'avait que les variantes vives : elles échouent toutes
/// en mode clair (émeraude 1,58:1, cyan 2,36:1, terracotta 3,16:1).
abstract final class Accents {
  // Action — terracotta
  static const actionVivid = Color(0xFFFF4D2E); // 5,79:1 sur obsidienne  ✅ AA
  static const actionFill = Color(0xFFD93A1F); // blanc dessus : 4,59:1   ✅ AA
  static const actionInk = Color(0xFFC4321A); // sur albâtre : 5,26:1     ✅ AA

  // Succès — émeraude
  static const successVivid = Color(0xFF00E599); // 11,55:1 sur obsidienne ✅ AAA
  static const successInk = Color(0xFF006B4A); // sur albâtre : 6,27:1     ✅ AA

  // Information / 360 — cyan spatial
  static const infoVivid = Color(0xFF00B4D8); // 7,77:1 sur obsidienne     ✅ AAA
  static const infoInk = Color(0xFF00708A); // sur albâtre : 5,45:1        ✅ AA

  // Avertissement
  static const warnVivid = Color(0xFFF2A93B);
  static const warnInk = Color(0xFF8A5A00);

  // Danger
  static const dangerVivid = Color(0xFFE5484D);
  static const dangerInk = Color(0xFFB3151A);
}

/// Palette complète d'un mode d'affichage.
/// Trois instances existent : [light], [dark], [sunlight].
@immutable
final class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceOverlay,
    required this.inkStrong,
    required this.inkBase,
    required this.inkMuted,
    required this.inkFaint,
    required this.lineHair,
    required this.lineStrong,
    required this.action,
    required this.actionOnFill,
    required this.actionFill,
    required this.success,
    required this.info,
    required this.warn,
    required this.danger,
    required this.isHighContrast,
  });

  final Color surfaceBase;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color surfaceOverlay;

  final Color inkStrong; // titres
  final Color inkBase; // corps
  final Color inkMuted; // secondaire — jamais sous 4,5:1
  final Color inkFaint; // désactivé et séparateurs UNIQUEMENT, jamais d'info

  final Color lineHair;
  final Color lineStrong;

  final Color action; // texte / icône d'action
  final Color actionFill; // fond d'un bouton plein
  final Color actionOnFill; // label posé sur actionFill
  final Color success;
  final Color info;
  final Color warn;
  final Color danger;

  /// Vrai en mode Plein Soleil : les composants montent d'un cran de taille
  /// et les zones tactiles passent de 48 à 56 dp.
  final bool isHighContrast;

  static const light = AppPalette(
    surfaceBase: Color(0xFFF8FAFC),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEEF2F7),
    surfaceOverlay: Color(0xFFFFFFFF),
    inkStrong: Color(0xFF0B0F19), // 18,30:1
    inkBase: Color(0xFF1E2635), // 13,9:1
    inkMuted: Color(0xFF55617A), // 5,9:1
    inkFaint: Color(0xFF8A94A8), // 3,1:1 — non textuel
    lineHair: Color(0xFFE2E8F0),
    lineStrong: Color(0xFFCBD5E1),
    action: Accents.actionInk,
    actionFill: Accents.actionFill,
    actionOnFill: Color(0xFFFFFFFF),
    success: Accents.successInk,
    info: Accents.infoInk,
    warn: Accents.warnInk,
    danger: Accents.dangerInk,
    isHighContrast: false,
  );

  static const dark = AppPalette(
    surfaceBase: Color(0xFF0B0F19),
    surfaceRaised: Color(0xFF141926),
    surfaceSunken: Color(0xFF080C14),
    surfaceOverlay: Color(0xFF1A2030),
    inkStrong: Color(0xFFF8FAFC), // 18,30:1
    inkBase: Color(0xFFD6DDE8), // 12,4:1
    inkMuted: Color(0xFF93A0B8), // 6,3:1
    inkFaint: Color(0xFF5E6A80),
    lineHair: Color(0xFF232B3B),
    lineStrong: Color(0xFF384357),
    action: Accents.actionVivid, // 5,79:1 — la signature reprend ses droits
    actionFill: Accents.actionVivid,
    actionOnFill: Color(0xFF0B0F19), // obsidienne sur terracotta : 5,79:1
    success: Accents.successVivid,
    info: Accents.infoVivid,
    warn: Accents.warnVivid,
    danger: Accents.dangerVivid,
    isHighContrast: false,
  );

  /// Plein Soleil — cible AAA. `inkMuted` fusionne avec `inkBase` : en plein
  /// jour, il n'y a plus de texte secondaire, seulement du texte lisible.
  static const sunlight = AppPalette(
    surfaceBase: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF1F5F9),
    surfaceOverlay: Color(0xFFFFFFFF),
    inkStrong: Color(0xFF000000),
    inkBase: Color(0xFF0B0F19),
    inkMuted: Color(0xFF0B0F19), // volontairement identique à inkBase
    inkFaint: Color(0xFF55617A),
    lineHair: Color(0xFFCBD5E1),
    lineStrong: Color(0xFF64748B),
    action: Color(0xFF9E2810), // ~8:1 sur blanc
    actionFill: Color(0xFF9E2810),
    actionOnFill: Color(0xFFFFFFFF),
    success: Color(0xFF00563B),
    info: Color(0xFF005569),
    warn: Color(0xFF6B4600),
    danger: Color(0xFF8E1015),
    isHighContrast: true,
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      other is AppPalette ? (t < 0.5 ? this : other) : this;
}

// ---------------------------------------------------------------------------
// TYPOGRAPHIE
// ---------------------------------------------------------------------------

abstract final class Fonts {
  static const display = 'PlusJakartaSans'; // 700, 800 uniquement
  static const body = 'Inter'; // 400, 500, 600 uniquement

  /// Obligatoire partout où un chiffre s'affiche. Sans chiffres tabulaires,
  /// une colonne de loyers danse à chaque rafraîchissement.
  static const tabular = <FontFeature>[FontFeature.tabularFigures()];
}

abstract final class AppText {
  static const displayL = TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 32,
    height: 38 / 32,
    letterSpacing: -0.5,
  );
  static const displayM = TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: -0.25,
  );
  static const titleL = TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 28 / 22,
  );
  static const titleM = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
  );

  /// Corps par défaut. Plancher de lecture : rien d'important en dessous.
  static const bodyL = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 24 / 16,
  );
  static const bodyM = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
  );
  static const label = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 16 / 13,
    letterSpacing: 0.2,
  );

  /// Horodatages et mentions. JAMAIS une information dont dépend une décision.
  static const caption = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
  );

  static const amount = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 28 / 24,
    fontFeatures: Fonts.tabular,
  );
  static const amountL = TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 32,
    height: 38 / 32,
    fontFeatures: Fonts.tabular,
  );
}

// ---------------------------------------------------------------------------
// ESPACE, FORME, CIBLE TACTILE
// ---------------------------------------------------------------------------

abstract final class Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0; // gouttière d'écran
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;

  static const gutter = md;
  static const feedGap = sm; // 12 dp entre cartes : densité > respiration
}

abstract final class Radii {
  static const chip = Radius.circular(8);
  static const input = Radius.circular(12);
  static const card = Radius.circular(16);
  static const sheet = Radius.circular(24);
  static const pill = Radius.circular(9999);
}

abstract final class Touch {
  static const min = 48.0; // Material 3 / WCAG 2.5.5
  static const minSunlight = 56.0;
  static const gap = 8.0; // écart minimal entre deux cibles

  static double target(bool highContrast) => highContrast ? minSunlight : min;
}

abstract final class Sizes {
  static const listingCardHeight = 128.0; // constante : permet itemExtent fixe

  /// 96, et non 112.
  ///
  /// MESURÉ sur un Galaxy A56 : 1080 px à 450 dpi = **384 dp de large**, pas
  /// les 412 supposés au dessin. Avec une vignette de 112, il ne restait que
  /// 180 dp de texte — et trois des quatre lignes de la carte étaient
  /// tronquées : « Fidjros… », « Vérifié aujourd'hui 05h… », « Entrée :
  /// 245 000 F · 3 m… ».
  ///
  /// Une ligne coupée ne tient pas sa promesse : le coût d'entrée est LE
  /// chiffre qui élimine 80 % des biens, et la fraîcheur est ce que le
  /// produit vend. La photo, elle, « sert à disqualifier vite, pas à
  /// décider » — c'est donc elle qui cède les 16 dp.
  static const listingThumbWidth = 96.0;
  static const focusRing = 2.0;
  static const focusOffset = 2.0;
}

// ---------------------------------------------------------------------------
// MOUVEMENT — trois primitives, pas une de plus
// ---------------------------------------------------------------------------

abstract final class Motion {
  static const fast = Duration(milliseconds: 90); // press
  static const base = Duration(milliseconds: 180); // progress-fill
  static const slow = Duration(milliseconds: 280); // zoom-immersif
  static const successHold = Duration(milliseconds: 1200);

  static const standard = Cubic(0.2, 0, 0, 1);
  static const emphasized = Cubic(0.05, 0.7, 0.1, 1);
  static const exit = Cubic(0.3, 0, 1, 1);

  static const pressScale = 0.97;

  /// Respecte MediaQuery.disableAnimations : zoom-immersif -> fondu 120 ms,
  /// progress-fill -> instantané, press -> haptique seule.
  static Duration reduced(BuildContext c, Duration d) =>
      MediaQuery.of(c).disableAnimations
      ? const Duration(milliseconds: 120)
      : d;
}

// ---------------------------------------------------------------------------
// PROFONDEUR — élévation tonale d'abord, ombre en dernier recours
// ---------------------------------------------------------------------------

abstract final class Elevation {
  /// Deux ombres floutées maximum par écran : la barre d'action collée en bas
  /// et la feuille modale. Aucun BackdropFilter : premier poste de perte de
  /// framerate sur Mali-G52.
  static const stickyBar = <BoxShadow>[
    BoxShadow(color: Color(0x1A0B0F19), blurRadius: 16, offset: Offset(0, -2)),
  ];
  static const sheet = <BoxShadow>[
    BoxShadow(color: Color(0x260B0F19), blurRadius: 24, offset: Offset(0, -4)),
  ];
  static const none = <BoxShadow>[];
}

// ---------------------------------------------------------------------------
// BUDGET DE PERFORMANCE — valeurs de test, pas des vœux
// ---------------------------------------------------------------------------

abstract final class PerfBudget {
  static const apkMaxBytes = 30 * 1024 * 1024;
  static const coldStartToFirstListing = Duration(milliseconds: 2500);
  static const feedScreenMaxBytes = 350 * 1024;
  static const panoramaSceneMaxBytes = 1536 * 1024;
  static const tourMinFps = 30; // pas 60 : promettre 60 sur Mali-G52 est faux
  static const runtimeMemoryMaxBytes = 220 * 1024 * 1024;

  static const thumbWidthNormal = 400;
  static const thumbWidthLite = 240; // mode Léger
}
