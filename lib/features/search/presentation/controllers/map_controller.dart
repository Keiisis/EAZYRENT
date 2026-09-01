import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../listing/domain/entities/listing.dart';

/// Le seul GetxController du projet.
///
/// DÉCISION ASSUMÉE : GetX est cantonné à la carte. Le reste de l'application
/// — feed, authentification, ma liste — reste sur `flutter_bloc` + `get_it`.
/// Deux systèmes cohabitent donc, mais sur des périmètres nets. La frontière
/// est celle-ci : rien hors de `features/search/.../map_*` n'importe `get`.
///
/// La carte est le seul écran qui justifie ce traitement : elle a un état
/// impératif et continu (caméra, sélection, position) que l'on pilote plutôt
/// qu'on ne le dérive, et `.obs` évite d'émettre un état complet à chaque
/// image d'animation de caméra.
class MapCtrl extends GetxController {
  MapCtrl({required this.listings});

  final List<Listing> listings;

  /// Cotonou, place de l'Étoile Rouge. Point de repli quand on n'a ni
  /// position ni bien géolocalisé — jamais (0, 0), qui projette l'utilisateur
  /// dans le golfe de Guinée.
  static const fallbackCenter = LatLng(6.3654, 2.4183);

  final selectedId = RxnString();
  final userPosition = Rxn<LatLng>();
  final userPlace = RxnString();
  final locating = false.obs;
  final locationDenied = false.obs;

  /// Seuls les biens qu'on peut RÉELLEMENT poser sur la carte.
  /// Les autres ne sont pas perdus : l'écran affiche leur nombre et propose
  /// de revenir à la liste, plutôt que de les faire disparaître en silence.
  late final List<Listing> mappable = listings
      .where((l) => l.hasCoordinates)
      .toList();

  late final int unmappedCount = listings.length - mappable.length;

  LatLng get initialCenter => mappable.isEmpty
      ? fallbackCenter
      : LatLng(mappable.first.latitude!, mappable.first.longitude!);

  Listing? get selected => selectedId.value == null
      ? null
      : mappable.firstWhereOrNull((l) => l.id == selectedId.value);

  LatLng positionOf(Listing l) => LatLng(l.latitude!, l.longitude!);

  void select(String? id) => selectedId.value = id;

  // ---------------------------------------------------------------------
  // TUILES
  // ---------------------------------------------------------------------

  /// Le jeton est LU, jamais exigé.
  ///
  /// Sans `.env`, sans clé, ou avec un jeton vide, la carte bascule sur
  /// OpenStreetMap — qui ne demande rien. Une configuration absente ne doit
  /// jamais empêcher quelqu'un de chercher un logement : c'est notre problème
  /// d'exploitation, pas le sien.
  static String get _mapboxToken {
    try {
      return dotenv.env['MAPBOX_TOKEN'] ?? '';
    } catch (_) {
      // dotenv non initialisé (fichier absent de l'APK). Cas normal, pas une
      // erreur : on retombe sur OSM.
      return '';
    }
  }

  /// Un jeton Mapbox public réel fait une centaine de caractères. Se contenter
  /// de `startsWith('pk.')` laissait passer le gabarit `pk.remplace_moi` du
  /// fichier d'exemple : l'application partait alors chercher des tuiles chez
  /// Mapbox, recevait des **401**, et affichait un rectangle gris sans le
  /// moindre message. Vérifié sur l'appareil.
  static bool get usesMapbox {
    final t = _mapboxToken;
    return t.startsWith('pk.') && t.length >= 60 && !t.contains('remplace');
  }

  static const osmTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static String get tileUrl => usesMapbox
      ? 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/'
            '{z}/{x}/{y}@2x?access_token=$_mapboxToken'
      : osmTiles;

  /// Repli tuile par tuile. Un jeton expiré, un quota dépassé ou une panne
  /// Mapbox ne doivent pas rendre la carte grise : elles la font simplement
  /// revenir à OpenStreetMap, qui ne demande rien. La dégradation est
  /// silencieuse pour l'utilisateur parce qu'elle ne lui coûte rien —
  /// contrairement à un écran vide, qu'il ne peut ni comprendre ni contourner.
  static String? get fallbackTileUrl => usesMapbox ? osmTiles : null;

  /// L'attribution n'est pas décorative : OpenStreetMap l'exige (ODbL), et
  /// Mapbox aussi. L'omettre est une violation de licence, pas un choix de
  /// mise en page.
  static String get attribution =>
      usesMapbox ? '© Mapbox · © OpenStreetMap' : '© OpenStreetMap';

  // ---------------------------------------------------------------------
  // POSITION
  // ---------------------------------------------------------------------

  /// Demandée UNIQUEMENT sur geste explicite, jamais au chargement.
  ///
  /// Un refus n'est pas une erreur et n'affiche pas de rouge : la carte
  /// continue de fonctionner, centrée sur les biens. On note simplement le
  /// refus pour ne pas redemander en boucle — Android ne redonne jamais une
  /// permission refusée deux fois.
  Future<void> locateMe() async {
    if (locating.value) return;
    locating.value = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        locationDenied.value = true;
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationDenied.value = true;
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          // Une précision au mètre coûte du temps et de la batterie pour
          // trier des biens à l'échelle du quartier. `medium` suffit, et
          // rend la main en quelques secondes sur un appareil d'entrée
          // de gamme.
          timeLimit: Duration(seconds: 12),
        ),
      );
      userPosition.value = LatLng(pos.latitude, pos.longitude);
      await _resolvePlaceName(pos.latitude, pos.longitude);
    } catch (_) {
      locationDenied.value = true;
    } finally {
      locating.value = false;
    }
  }

  /// Le nom du quartier, pas les coordonnées.
  ///
  /// « 6,3654 · 2,4183 » ne veut rien dire pour personne. « Fidjrossè » se
  /// vérifie d'un coup d'œil — et c'est le seul moyen pour l'utilisateur de
  /// constater que l'application a compris où il est.
  Future<void> _resolvePlaceName(double lat, double lng) async {
    try {
      // geocoding 5.x expose une CLASSE, plus les fonctions de premier niveau
      // de la 2.x. Et la locale est passée explicitement : sans elle, le
      // quartier remonte dans la langue du système, qui n'est pas toujours
      // le français sur un téléphone acheté d'occasion.
      final places = await Geocoding(
        locale: const Locale('fr', 'BJ'),
      ).placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return;
      final p = places.first;
      final parts = <String?>[p.subLocality, p.locality];
      final name = parts
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(', ');
      if (name.isNotEmpty) userPlace.value = name;
    } catch (_) {
      // Le géocodage inverse échoue souvent hors couverture. On garde la
      // position, on se passe du nom : la carte reste utilisable.
    }
  }
}
