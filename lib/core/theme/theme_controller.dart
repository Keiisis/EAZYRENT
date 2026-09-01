import 'package:flutter/foundation.dart';

enum AppThemeMode { light, dark, sunlight }

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

  AppThemeMode _mode = AppThemeMode.light;
  bool _liteData = true;
  TourQuality _tourQuality = TourQuality.standard;
  bool _autoSunlight = true;

  AppThemeMode get mode => _mode;
  bool get liteData => _liteData;
  TourQuality get tourQuality => _tourQuality;
  bool get autoSunlight => _autoSunlight;

  bool get isSunlight => _mode == AppThemeMode.sunlight;

  set mode(AppThemeMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  /// Bascule manuelle depuis « Moi » ou les réglages. Elle repart toujours
  /// vers `light` et non vers `dark` : quelqu'un qui coupe le Plein Soleil
  /// est rentré à l'ombre, il n'a pas demandé le mode sombre.
  void toggleSunlight(bool on) =>
      mode = on ? AppThemeMode.sunlight : AppThemeMode.light;

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
