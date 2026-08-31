// RÈGLE UX 10 — Découverte progressive.
//
// Le palier n'est JAMAIS un drapeau posé en base : il se calcule à partir de
// faits observables. Un drapeau se désynchronise, un calcul non.
//
// Interdit : `if (user.hasPaid && user.savedCount > 2)` dans un widget.
// Toute condition de ce type remonte ici. Voir CONSTITUTION.md P10.

import 'package:equatable/equatable.dart';

enum UserStage {
  /// Premier lancement. Feed, preview, une visite offerte. Rien d'autre.
  p0Curieux(0),

  /// Un tour complet terminé. Shortlist, compte OTP, alerte quartier.
  p1Eveille(1),

  /// 2 biens gardés ou 1 pass acheté. Duel, carte, messagerie, packs, parrainage.
  p2Chasseur(2),

  /// 1 RDV demandé. Dossier locataire, argent bloqué expliqué, calendrier.
  p3Candidat(3),

  /// Bail actif. L'onglet Moi devient un outil de gestion locative.
  p4Locataire(4),

  /// Bascule de rôle explicite. Publication, tournage, demandes reçues.
  p5Bailleur(5),

  /// 3 biens publiés ou compte agence. Multi-agents, comptabilité, exports.
  p6Pro(6);

  const UserStage(this.rank);
  final int rank;

  bool operator >=(UserStage other) => rank >= other.rank;
  bool operator >(UserStage other) => rank > other.rank;
}

/// Les faits — et rien d'autre — dont le palier se déduit.
/// Ajouter un champ ici est une décision produit, pas un détail technique.
class ProgressionFacts extends Equatable {
  const ProgressionFacts({
    this.completedTours = 0,
    this.savedListings = 0,
    this.purchasedPasses = 0,
    this.requestedVisits = 0,
    this.hasActiveLease = false,
    this.publishedListings = 0,
    this.isAgency = false,
    this.hasAccount = false,
  });

  final int completedTours; // ≥ 80 % des pièces vues
  final int savedListings;
  final int purchasedPasses;
  final int requestedVisits;
  final bool hasActiveLease;
  final int publishedListings;
  final bool isAgency;
  final bool hasAccount;

  @override
  List<Object?> get props => [
    completedTours,
    savedListings,
    purchasedPasses,
    requestedVisits,
    hasActiveLease,
    publishedListings,
    isAgency,
    hasAccount,
  ];
}
