import 'package:equatable/equatable.dart';

/// Un lien d'une pièce vers une autre, posé DANS le panorama.
///
/// C'est ce qui distingue une visite d'une galerie de photos rondes : on passe
/// du salon à la chambre en touchant la porte qu'on voit, pas en revenant à
/// une liste. Sans point de passage, la personne perd le plan du logement au
/// bout de trois pièces — et le plan est précisément ce qu'elle est venue
/// chercher.
class TourHotspot extends Equatable {
  const TourHotspot({
    required this.targetSceneId,
    required this.label,
    required this.longitude,
    required this.latitude,
  });

  final String targetSceneId;

  /// « Chambre parentale », pas « Scène 3 ». On nomme la pièce.
  final String label;

  /// Position sur la sphère, en degrés. Longitude = rotation horizontale,
  /// latitude = hauteur. Ce sont les coordonnées du point de vue, pas des
  /// pixels : un même point reste au bon endroit quelle que soit la
  /// résolution du panorama.
  final double longitude;
  final double latitude;

  @override
  List<Object?> get props => [targetSceneId, longitude, latitude];
}

class TourScene extends Equatable {
  const TourScene({
    required this.id,
    required this.name,
    required this.panoramaUrl,
    this.initialYaw = 0,
    this.initialPitch = 0,
    this.hotspots = const [],
  });

  final String id;

  /// Vocabulaire de la maison : « Salon », « Chambre parentale », « Douche »,
  /// « Cour ». Jamais « Pièce 1 ».
  final String name;

  /// URL SIGNÉE, à durée de vie courte, obtenue par l'Edge Function.
  ///
  /// Elle ne vient JAMAIS d'une lecture directe de `virtual_tour_scenes` :
  /// une URL permanente rendue au client rend le paiement contournable en un
  /// copier-coller (CONSTITUTION P4).
  final String panoramaUrl;

  /// Orientation d'arrivée. Elle est choisie au tournage : on entre dans un
  /// salon face au canapé, pas face au mur derrière soi.
  final double initialYaw;
  final double initialPitch;

  final List<TourHotspot> hotspots;

  @override
  List<Object?> get props => [id, name, panoramaUrl];
}

/// L'accès complet à une visite, tel que l'Edge Function le rend.
class TourAccess extends Equatable {
  const TourAccess({
    required this.listingId,
    required this.scenes,
    required this.expiresAt,
    required this.capturedAt,
    this.agentName,
  });

  final String listingId;
  final List<TourScene> scenes;

  /// Les URL signées expirent. On garde la date pour pouvoir redemander un
  /// jeu d'URL au lieu d'afficher des images cassées au bout d'une heure.
  final DateTime expiresAt;

  /// La date du tournage, montrée dans la visite. C'est la promesse du
  /// produit : ce que tu vois a été filmé ce jour-là.
  final DateTime capturedAt;

  /// « Filmé par Rachid ». On fait confiance à une personne, pas à un tampon.
  final String? agentName;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [listingId, scenes.length, expiresAt];
}
