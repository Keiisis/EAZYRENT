// CONSTITUTION P4 — Le paywall ne s'arbitre jamais côté client.
//
// Défaut bloquant de la v1.0 : `virtual_tour_scenes.panorama_url` était
// lisible via PostgREST sans RLS. Le premier utilisateur technique publiait
// les URL dans un groupe WhatsApp et le modèle économique s'effondrait en
// une semaine (AUDIT_COHERENCE_BENIN.md §4).
//
// Ce contrat est la seule porte d'accès aux panoramas. Il n'expose AUCUNE URL
// brute de scène complète : `TourAccess` ne transporte que des URL signées à
// durée courte, obtenues d'une Edge Function qui a vérifié le pass côté serveur.

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';

typedef ListingId = String;

/// Preview publique : basse résolution, floutée au-delà de 90°.
/// Bucket public SÉPARÉ. Elle est censée circuler : c'est l'appât.
class TourPreview {
  const TourPreview({
    required this.sceneName,
    required this.lowResUrl,
    required this.totalRooms,
    required this.visibleDegrees,
  });

  final String sceneName;
  final String lowResUrl;
  final int totalRooms;

  /// Paramétrable côté serveur et instrumenté : c'est le réglage qui pilote
  /// directement le taux de conversion (EPICS_STORIES.md E2.1).
  final double visibleDegrees;
}

class SignedScene {
  const SignedScene({
    required this.sceneId,
    required this.name,
    required this.signedUrl,
    required this.expiresAt,
  });

  final String sceneId;
  final String name;
  final String signedUrl;
  final DateTime expiresAt;
}

class TourAccess {
  const TourAccess({required this.scenes, required this.renewAt});

  final List<SignedScene> scenes;

  /// Les URL expirent en ≤ 15 min : la session les renouvelle.
  final DateTime renewAt;
}

abstract interface class TourRepository {
  Future<Either<Failure, TourPreview>> getPreview(ListingId id);

  /// Vérifie le pass CÔTÉ SERVEUR (`get-tour-access`) et retourne des URL
  /// signées. Aucune URL de scène complète n'existe côté client hors de ce flux.
  Future<Either<Failure, TourAccess>> getTourAccess(ListingId id);

  /// Télécharge un tour déjà payé. Cache chiffré, JAMAIS purgé
  /// automatiquement : on a payé, on possède (P8, effet de dotation).
  /// Le poids est affiché à l'appelant avant démarrage.
  Future<Either<Failure, Unit>> downloadForOffline(ListingId id);

  /// Poids estimé, à afficher AVANT tout téléchargement (P6).
  Future<Either<Failure, int>> estimatedBytes(ListingId id);

  /// Repli matériel : sous 20 fps pendant 3 s, l'application propose
  /// d'elle-même le mode photos fixes. Elle ne laisse jamais l'utilisateur
  /// face à un tour saccadé en se disant qu'il a mal payé.
  /// C'est aussi l'alternative accessible obligatoire (UI_DESIGN_SYSTEM.md §11).
  Future<Either<Failure, List<SignedScene>>> getStillFallback(ListingId id);
}
