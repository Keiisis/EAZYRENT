// RÈGLE UX 10 — le seul endroit où le palier se décide.

import 'user_stage.dart';

abstract interface class StageResolver {
  UserStage resolve(ProgressionFacts facts);
}

class DefaultStageResolver implements StageResolver {
  const DefaultStageResolver();

  @override
  UserStage resolve(ProgressionFacts f) {
    // Les rôles pro sont un axe distinct du parcours chercheur : un bailleur
    // n'est pas « plus avancé » qu'un locataire, il fait autre chose.
    // La bascule de rôle est explicite (UX_CORE_SPEC.md §10.1).
    if (f.isAgency || f.publishedListings >= 3) return UserStage.p6Pro;
    if (f.publishedListings >= 1) return UserStage.p5Bailleur;

    if (f.hasActiveLease) return UserStage.p4Locataire;
    if (f.requestedVisits >= 1) return UserStage.p3Candidat;
    if (f.savedListings >= 2 || f.purchasedPasses >= 1) {
      return UserStage.p2Chasseur;
    }
    // P1 s'ouvre sur UN TOUR TERMINÉ ou UN PREMIER BIEN GARDÉ.
    //
    // Le premier lancement réel a montré le trou : garder un bien créait une
    // liste que rien ne permettait d'ouvrir, parce que l'onglet « Ma liste »
    // n'apparaissait qu'à deux biens. On offrait une action dont le résultat
    // restait invisible — le contraire d'une micro-victoire.
    //
    // Un palier ne doit jamais cacher ce que l'utilisateur vient de produire.
    if (f.completedTours >= 1 || f.savedListings >= 1) {
      return UserStage.p1Eveille;
    }

    return UserStage.p0Curieux;
  }
}
