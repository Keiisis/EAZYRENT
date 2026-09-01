// CONSTITUTION — aucune exception ne traverse la couche domaine.
// Tout remonte en `Either<Failure, T>` (fpdart).
//
// Chaque Failure porte un message DESTINÉ À L'UTILISATEUR, en français simple,
// qui dit quoi faire. Jamais un code technique à l'écran (UI_DESIGN_SYSTEM.md §7).
//
// `userMessage` est un getter abstrait, pas un paramètre de constructeur :
// le message appartient au TYPE d'échec, pas à son site d'appel. Deux endroits
// qui lèvent un NetworkFailure ne doivent pas pouvoir dire deux choses
// différentes à l'utilisateur.

import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({this.debug});

  /// Affichable tel quel. Doit dire QUOI FAIRE, pas ce qui s'est passé.
  String get userMessage;

  /// Pour les journaux et l'analytique uniquement. Jamais à l'écran.
  final String? debug;

  @override
  List<Object?> get props => [userMessage, debug];
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.debug});

  @override
  String get userMessage => 'Pas de connexion. Tu vois ce qui est déjà chargé.';
}

final class ServerFailure extends Failure {
  const ServerFailure({super.debug});

  @override
  String get userMessage => "On n'arrive pas à charger. Réessaie.";
}

final class CacheFailure extends Failure {
  const CacheFailure({super.debug});

  @override
  String get userMessage => 'Impossible de lire les données enregistrées.';
}

/// L'utilisateur n'a pas de pass valide pour ce bien.
/// Ce n'est pas une erreur : c'est le paywall qui fonctionne.
final class NoValidPassFailure extends Failure {
  const NoValidPassFailure({super.debug});

  @override
  String get userMessage => 'Débloque cette visite pour voir tout le logement.';
}

/// Échec Mobile Money — le cas NOMINAL sur ce marché, pas l'exception.
/// Le message dit d'abord que rien n'a été débité : c'est ce qui rassure.
final class PaymentFailure extends Failure {
  const PaymentFailure({
    required this.operator,
    this.canRetryWith,
    super.debug,
  });

  final String operator;

  /// Opérateur de repli à proposer d'office. Un échec non rattrapé fait
  /// perdre l'utilisateur définitivement (EPICS_STORIES.md E2.6).
  final String? canRetryWith;

  @override
  String get userMessage =>
      "Le paiement n'a pas abouti. Aucun montant n'a été débité.";

  @override
  List<Object?> get props => [userMessage, debug, operator, canRetryWith];
}

/// Le bien n'est plus disponible. Déclenche le remboursement automatique
/// en crédit, sans réclamation (E3.3).
final class ListingGoneFailure extends Failure {
  const ListingGoneFailure({super.debug});

  @override
  String get userMessage =>
      "Ce bien n'est plus libre. Ta visite t'a été rendue.";
}

final class ValidationFailure extends Failure {
  const ValidationFailure(this.userMessage, {super.debug});

  @override
  final String userMessage;
}

/// Le module escrow est bloqué par la conformité BCEAO (GATES.md G8).
/// Cette Failure existe pour que toute tentative d'appel échoue bruyamment
/// plutôt que silencieusement.
final class BlockedByComplianceFailure extends Failure {
  const BlockedByComplianceFailure()
    : super(debug: 'escrow bloqué : statut BCEAO non arrêté — GATES.md G8');

  @override
  String get userMessage => 'Cette fonctionnalité arrive bientôt.';
}

/// La visite n'a pas été payée. C'est un refus MÉTIER, pas une panne : il ne
/// dit jamais « erreur », il dit ce qu'il faut faire.
///
/// Il ne peut venir QUE du serveur (Edge Function, 402). Le client ne décide
/// jamais lui-même s'il a payé — c'est tout l'objet de CONSTITUTION P4.
final class TourNotPaidFailure extends Failure {
  const TourNotPaidFailure({super.debug});

  @override
  String get userMessage =>
      'Cette visite n\'est pas encore débloquée sur ton compte.';
}

/// Le bien est marqué « Visite Vérifiée » mais aucune scène n'est publiée.
/// C'est une incohérence de NOTRE côté, jamais de celui de l'utilisateur :
/// le message le dit, et le remboursement est automatique.
final class TourEmptyFailure extends Failure {
  const TourEmptyFailure({super.debug});

  @override
  String get userMessage =>
      'Les images de cette visite ne sont pas encore en ligne. '
      'Ta visite ne t\'a pas été décomptée.';
}
