// RÈGLE UX 7 — le compteur d'économies, mécanisme central de l'habitude.
//
// CONTRAINTE D'HONNÊTETÉ (UI/UX_CORE_SPEC.md §7.2) :
// le calcul repose sur le coût de déplacement DÉCLARÉ PAR L'UTILISATEUR
// lui-même, jamais sur une moyenne inventée. Un compteur soupçonné d'être
// gonflé détruit exactement la confiance qu'il est censé construire.
//
// L'API l'impose : sans `declaredTripCost`, il n'y a pas de compteur.

import 'package:equatable/equatable.dart';

class SavingsSnapshot extends Equatable {
  const SavingsSnapshot({
    required this.toursCompleted,
    required this.amountSavedFcfa,
    required this.tripCostFcfa,
  });

  final int toursCompleted;
  final int amountSavedFcfa;
  final int tripCostFcfa;

  @override
  List<Object?> get props => [toursCompleted, amountSavedFcfa, tripCostFcfa];
}

class SavingsCounter {
  const SavingsCounter();

  /// [declaredTripCostFcfa] — ce que l'utilisateur a répondu à la question
  /// « combien te coûte un aller-retour vers un quartier ? ». `null` tant
  /// qu'il n'a pas répondu.
  ///
  /// [passesPaidFcfa] — ce qu'il a réellement dépensé en pass. L'économie est
  /// NETTE : afficher un brut serait exactement le gonflement qu'on s'interdit.
  ///
  /// Retourne `null` si le coût n'a pas été déclaré : dans ce cas le compteur
  /// n'existe pas à l'écran. On n'affiche pas un zéro, on n'invente pas une
  /// moyenne.
  SavingsSnapshot? compute({
    required int toursCompleted,
    required int passesPaidFcfa,
    int? declaredTripCostFcfa,
  }) {
    if (declaredTripCostFcfa == null || declaredTripCostFcfa <= 0) return null;
    if (toursCompleted <= 0) return null;

    final gross = toursCompleted * declaredTripCostFcfa;
    final net = gross - passesPaidFcfa;
    if (net <= 0) return null; // rien à célébrer : on se tait.

    return SavingsSnapshot(
      toursCompleted: toursCompleted,
      amountSavedFcfa: net,
      tripCostFcfa: declaredTripCostFcfa,
    );
  }
}
