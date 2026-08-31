// Navigation déclarative. Les liens profonds sont le canal d'acquisition n°1
// (GROWTH_MONETISATION.md §4.3) : un routeur impératif rendrait le partage
// WhatsApp bancal.
//
// CONSTITUTION P2 — aucune route ne dépend d'une session au démarrage.
// `AuthState.anonymous` est un état de plein droit, pas une absence.

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../progression/user_stage.dart';

abstract final class Routes {
  static const onboarding = '/bienvenue';
  static const feed = '/';
  static const map = '/carte';

  /// Cible des liens WhatsApp : eazyrent.bj/b/{id}
  /// Ouvre la fiche DIRECTEMENT, sans compte (E1.5).
  static const listing = '/b/:id';
  static const tour = '/b/:id/visite';
  static const paywall = '/b/:id/debloquer';

  static const shortlist = '/ma-liste';
  static const duel = '/ma-liste/duel';
  static const messages = '/messages';
  static const me = '/moi';

  static String listingOf(String id) => '/b/$id';
}

/// Routes réservées à un palier. Une route non atteinte n'est pas affichée
/// en grisé : elle redirige vers le feed. Rien ne signale son existence.
const _minStage = <String, UserStage>{
  Routes.shortlist: UserStage.p1Eveille,
  Routes.duel: UserStage.p2Chasseur,
  Routes.messages: UserStage.p2Chasseur,
};

GoRouter buildRouter({
  required ValueListenable<UserStage> stage,
  required bool hasCompletedOnboarding,
  required Map<String, Widget Function(GoRouterState)> screens,
}) {
  return GoRouter(
    initialLocation: hasCompletedOnboarding ? Routes.feed : Routes.onboarding,
    refreshListenable: stage,
    redirect: (context, state) {
      final path = state.uri.path;

      // Un lien profond entrant court-circuite l'onboarding : quelqu'un qui
      // arrive par WhatsApp veut voir CE bien, pas répondre à trois questions.
      if (path.startsWith('/b/')) return null;

      if (!hasCompletedOnboarding && path != Routes.onboarding) {
        return Routes.onboarding;
      }

      final required = _minStage[path];
      if (required != null && !(stage.value >= required)) return Routes.feed;

      return null;
    },
    routes: [
      for (final entry in screens.entries)
        GoRoute(path: entry.key, builder: (_, s) => entry.value(s)),
    ],
  );
}
