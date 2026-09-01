import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/travel_mode.dart';

/// Une manœuvre du guidage. Le texte vient du moteur, EN FRANÇAIS — Valhalla
/// accepte `language: fr-FR` et rend « Tournez à droite sur la Rue 150 ».
/// Traduire nous-mêmes des codes de manœuvre produirait des phrases qui ne
/// nomment aucune rue, donc inutilisables en circulation.
class RouteStep extends Equatable {
  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.shapeIndex,
  });

  final String instruction;
  final int distanceMeters;

  /// Indice du point de la géométrie où commence la manœuvre. C'est ce qui
  /// permet de dire « dans 200 m, tournez » sans recalculer l'itinéraire.
  final int shapeIndex;

  @override
  List<Object?> get props => [instruction, distanceMeters, shapeIndex];
}

class RoutePlan extends Equatable {
  const RoutePlan({
    required this.mode,
    required this.distanceMeters,
    required this.duration,
    required this.geometry,
    required this.steps,
  });

  final TravelMode mode;
  final int distanceMeters;
  final Duration duration;

  /// La trace réelle, suivant les rues. Une ligne droite entre deux points
  /// mentirait sur la distance ET sur le chemin : à Cotonou, la lagune et les
  /// voies non bitumées font qu'un bien « à 800 m » se trouve à 3 km.
  final List<LatLng> geometry;

  final List<RouteStep> steps;

  /// « 13 min », « 1 h 05 ». Jamais « 65 min » : au-delà de l'heure, personne
  /// ne compte en minutes.
  String get durationLabel {
    final m = duration.inMinutes;
    if (m < 1) return 'moins d\'1 min';
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    // « 1 h 05 », pas « 1 h 5 » : les minutes se paddent, comme sur une
    // horloge. « 1 h 5 » se lit une demi-seconde de trop.
    return r == 0 ? '$h h' : '$h h ${r.toString().padLeft(2, '0')}';
  }

  /// « 850 m » sous le kilomètre, « 6,3 km » au-delà. Afficher « 6329 m »
  /// oblige à compter les chiffres.
  String get distanceLabel => distanceMeters < 1000
      ? '$distanceMeters m'
      : '${(distanceMeters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  @override
  List<Object?> get props => [mode, distanceMeters, duration];
}
