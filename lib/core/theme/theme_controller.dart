import 'package:flutter/widgets.dart';

/// Quatre choix, et le premier est le bon défaut.
///
/// `system` suit le réglage Android. C'est ce que fait tout le reste du
/// téléphone : imposer le mode clair à quelqu'un qui a mis son appareil en
/// sombre revient à lui éblouir les yeux à 22 h.
enum AppThemeMode { system, light, dark, sunlight }

/// Qualité des tours 360, et donc volume de données par pièce filmée.
enum TourQuality {
  /// ~1,2 Mo par pièce. Le défaut, et le seul défensable sur un forfait
  /// béninois : recommandé, pas subi.
  standard,

  /// ~6 Mo par pièce. Réservé au Wi-Fi — proposer de l'Ultra HD à quelqu'un
  /// en 3G revient à lui vendre une visite qu'il ne verra pas finir.
  ultra,
}

/// L'état d'affichage de l'application, à un seul endroit.
///
/// POURQUOI CE FICHIER EXISTE : le Mode Plein Soleil et le Mode Léger étaient
/// dessinés, spécifiés, et présents à l'écran sous forme d'interrupteurs qui
/// ne faisaient RIEN. Un interrupteur qui bouge sans rien changer coûte plus
/// cher qu'un interrupteur absent : il apprend à l'utilisateur que les
/// réglages de cette application sont décoratifs.
///
/// Un `ChangeNotifier` et non un Cubit ni un GetxController : l'affichage est
/// consommé par `MaterialApp` lui-même, au-dessus de tous les fournisseurs.
/// Y brancher un Bloc obligerait à envelopper l'application entière pour un
/// état de trois champs.
class ThemeController extends ChangeNotifier {
  ThemeController();

  AppThemeMode _mode = AppThemeMode.system;
  bool _liteData = true;
  TourQuality _tourQuality = TourQuality.standard;
  bool _autoSunlight = true;

  AppThemeMode get mode => _mode;
  bool get liteData => _liteData;
  TourQuality get tourQuality => _tourQuality;
  bool get autoSunlight => _autoSunlight;

  bool get isSunlight => _mode == AppThemeMode.sunlight;

  /// Le mode EFFECTIF, une fois `system` résolu.
  ///
  /// Le Plein Soleil l'emporte toujours : il a été choisi à la main, pour une
  /// raison que le capteur du téléphone ne connaît pas — on est dehors.
  AppThemeMode resolved(Brightness platform) => switch (_mode) {
    AppThemeMode.system =>
      platform == Brightness.dark ? AppThemeMode.dark : AppThemeMode.light,
    final m => m,
  };

  String get label => switch (_mode) {
    AppThemeMode.system => 'Comme le téléphone',
    AppThemeMode.light => 'Clair',
    AppThemeMode.dark => 'Sombre',
    AppThemeMode.sunlight => 'Plein Soleil',
  };

  set mode(AppThemeMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  /// Bascule manuelle depuis « Moi ». Couper le Plein Soleil REVIENT AU
  /// RÉGLAGE DU TÉLÉPHONE, et non au mode clair : quelqu'un qui rentre à
  /// l'ombre le soir veut retrouver son sombre habituel, pas un écran blanc.
  void toggleSunlight(bool on) =>
      mode = on ? AppThemeMode.sunlight : AppThemeMode.system;

  set liteData(bool value) {
    if (_liteData == value) return;
    _liteData = value;
    notifyListeners();
  }

  set tourQuality(TourQuality value) {
    if (_tourQuality == value) return;
    _tourQuality = value;
    // Choisir l'Ultra HD implique de renoncer au Mode Léger : les deux
    // réglages se contrediraient, et c'est l'utilisateur qui vient de
    // trancher.
    if (value == TourQuality.ultra) _liteData = false;
    notifyListeners();
  }

  set autoSunlight(bool value) {
    if (_autoSunlight == value) return;
    _autoSunlight = value;
    notifyListeners();
  }

  /// Appelé par le capteur de luminosité. Le seuil de 8 000 lux correspond à
  /// une rue de Cotonou à midi, pas à un bureau bien éclairé — c'est ce qui
  /// évite que le mode s'enclenche à l'intérieur.
  ///
  /// La bascule automatique ne fonctionne QUE dans un sens : elle allume le
  /// Plein Soleil, elle ne l'éteint jamais. Une carte qui redevient pâle
  /// pendant qu'on la lit dehors, parce qu'un nuage est passé, est pire que
  /// tout.
  static const sunlightLux = 8000.0;

  void onAmbientLight(double lux) {
    if (!_autoSunlight) return;
    if (lux >= sunlightLux && _mode != AppThemeMode.sunlight) {
      mode = AppThemeMode.sunlight;
    }
  }
}
