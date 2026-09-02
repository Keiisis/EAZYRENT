import 'package:eazyrent/core/theme/design_tokens.dart';
import 'package:eazyrent/core/theme/theme_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Luminance relative WCAG 2.1. Recopiée ici plutôt qu'importée : un test
/// qui utilise le code qu'il vérifie ne vérifie rien.
double _lum(Color c) {
  double chan(double v) {
    final s = v; // composantes déjà normalisées 0..1
    return s <= 0.03928 ? s / 12.92 : _pow((s + 0.055) / 1.055, 2.4);
  }

  return 0.2126 * chan(c.r) + 0.7152 * chan(c.g) + 0.0722 * chan(c.b);
}

// Exponentiation par séries : suffisant pour l'exposant 2,4 sur [0,1], et
// surtout INDÉPENDANT de `dart:math` — un test qui réutilise le code qu'il
// vérifie ne vérifie rien.
double _pow(double x, double e) => _exp(e * _ln(x));

double _ln(double x) {
  if (x <= 0) return -30;
  final y = (x - 1) / (x + 1);
  final y2 = y * y;
  var sum = 0.0;
  var term = y;
  for (var n = 1; n <= 25; n += 2) {
    sum += term / n;
    term *= y2;
  }
  return 2 * sum;
}

double _exp(double x) {
  var sum = 1.0;
  var term = 1.0;
  for (var n = 1; n < 30; n++) {
    term *= x / n;
    sum += term;
  }
  return sum;
}

double _contrast(Color a, Color b) {
  final la = _lum(a);
  final lb = _lum(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('Plein Soleil — il doit SE VOIR', () {
    // Le mode a été refait après un constat sur l'appareil : « on ne voit
    // aucune différence ». La première version passait le fond de #F8FAFC à
    // #FFFFFF et l'encre de #0B0F19 à #000000 : trois pour cent d'écart.
    //
    // Ce que ces tests verrouillent, c'est que la différence est STRUCTURELLE
    // — séparations et épaisseurs — et pas cosmétique.

    test('les bordures sont deux fois plus épaisses', () {
      expect(AppPalette.sunlight.borderWidth, 2);
      expect(AppPalette.light.borderWidth, 1);
      expect(AppPalette.dark.borderWidth, 1);
    });

    test('les ombres disparaissent', () {
      // Dehors une ombre floutée ne rend rien, et coûte un passage de rendu
      // sur un Mali-G52.
      expect(AppPalette.sunlight.shadowCard, isEmpty);
      expect(AppPalette.sunlight.shadowBar, isEmpty);
      expect(AppPalette.light.shadowCard, isNotEmpty);
    });

    test('la bordure fine devient une VRAIE bordure', () {
      // C'est le cœur du correctif : en plein soleil, un panneau blanc sur
      // fond blanc sans bordure visible disparaît, quelle que soit la
      // qualité du contraste du texte.
      final clair = _contrast(
        AppPalette.light.lineHair,
        AppPalette.light.surfaceRaised,
      );
      final soleil = _contrast(
        AppPalette.sunlight.lineHair,
        AppPalette.sunlight.surfaceRaised,
      );

      expect(
        soleil,
        greaterThan(3.0),
        reason: 'une bordure sous 3:1 ne se voit pas dehors',
      );
      expect(
        soleil,
        greaterThan(clair * 2),
        reason: 'le Plein Soleil doit franchement se distinguer du mode clair',
      );
    });

    test('les blocs et champs se détachent du fond', () {
      // `surfaceSunken` dessine les champs de saisie et les encadrés. En
      // mode clair il peut rester discret ; dehors il doit se voir.
      final soleil = _contrast(
        AppPalette.sunlight.surfaceSunken,
        AppPalette.sunlight.surfaceBase,
      );
      final clair = _contrast(
        AppPalette.light.surfaceSunken,
        AppPalette.light.surfaceBase,
      );
      expect(soleil, greaterThan(clair));
    });

    test('les cibles tactiles passent de 48 à 56 dp', () {
      expect(Touch.target(AppPalette.sunlight.isHighContrast), 56);
      expect(Touch.target(AppPalette.light.isHighContrast), 48);
    });

    test('le texte reste au niveau AAA', () {
      expect(
        _contrast(AppPalette.sunlight.inkBase, AppPalette.sunlight.surfaceBase),
        greaterThan(7.0),
      );
    });
  });

  group('Mode sombre — il existe et il est atteignable', () {
    test('le sombre inverse réellement le rapport clair/foncé', () {
      // Le mode existait dans la palette depuis le début, et n'était choisi
      // par personne : `AppTheme.dark()` était construit, jamais atteint.
      expect(
        _lum(AppPalette.dark.surfaceBase),
        lessThan(_lum(AppPalette.light.surfaceBase)),
      );
      expect(
        _lum(AppPalette.dark.inkStrong),
        greaterThan(_lum(AppPalette.light.inkStrong)),
      );
    });

    test('le texte du mode sombre tient le AA', () {
      expect(
        _contrast(AppPalette.dark.inkBase, AppPalette.dark.surfaceBase),
        greaterThan(4.5),
      );
      expect(
        _contrast(AppPalette.dark.inkMuted, AppPalette.dark.surfaceBase),
        greaterThan(4.5),
      );
    });
  });

  group('ThemeController — quatre choix, un seul actif', () {
    test('le défaut suit le téléphone', () {
      expect(ThemeController().mode, AppThemeMode.system);
    });

    test('« system » se résout selon la luminosité de la plateforme', () {
      final c = ThemeController();
      expect(c.resolved(Brightness.dark), AppThemeMode.dark);
      expect(c.resolved(Brightness.light), AppThemeMode.light);
    });

    test('le Plein Soleil l\'emporte sur le réglage du téléphone', () {
      // Il a été choisi à la main, pour une raison que le capteur ne connaît
      // pas : on est dehors.
      final c = ThemeController()..mode = AppThemeMode.sunlight;
      expect(c.resolved(Brightness.dark), AppThemeMode.sunlight);
      expect(c.resolved(Brightness.light), AppThemeMode.sunlight);
    });

    test('couper le Plein Soleil revient au réglage du téléphone', () {
      // Et NON au mode clair : quelqu'un qui rentre à l'ombre le soir veut
      // retrouver son sombre habituel, pas un écran blanc en pleine figure.
      final c = ThemeController()..toggleSunlight(true);
      expect(c.mode, AppThemeMode.sunlight);
      c.toggleSunlight(false);
      expect(c.mode, AppThemeMode.system);
    });

    test('choisir l\'Ultra HD coupe le Mode Léger', () {
      // Les deux réglages se contrediraient, et c'est l'utilisateur qui vient
      // de trancher.
      final c = ThemeController();
      expect(c.liteData, isTrue);
      c.tourQuality = TourQuality.ultra;
      expect(c.liteData, isFalse);
    });

    test('le capteur allume le Plein Soleil mais ne l\'éteint jamais', () {
      final c = ThemeController()..onAmbientLight(12000);
      expect(c.mode, AppThemeMode.sunlight);

      // Un nuage passe : la carte ne doit pas repâlir pendant qu'on la lit.
      c.onAmbientLight(200);
      expect(c.mode, AppThemeMode.sunlight);
    });

    test('la bascule automatique se désactive vraiment', () {
      final c = ThemeController()..autoSunlight = false;
      c.onAmbientLight(20000);
      expect(c.mode, AppThemeMode.system);
    });
  });
}
