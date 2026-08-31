// CONSTITUTION P12 — Ce qui n'est pas mesuré n'est pas terminé.
//
// Un événement par KPI du PRD §6.1. Union scellée : ajouter un KPI sans son
// événement ne compile pas.

sealed class AnalyticsEvent {
  const AnalyticsEvent();
  String get name;
  Map<String, Object?> get params => const {};
}

// ─── ★ MÉTRIQUE NORD ────────────────────────────────────────────────────────

/// Visites Vérifiées terminées par semaine. « Terminée » = ≥ 80 % des pièces.
final class TourCompleted extends AnalyticsEvent {
  const TourCompleted({
    required this.listingId,
    required this.roomsSeen,
    required this.roomsTotal,
    required this.wasFreePass,
  });

  final String listingId;
  final int roomsSeen;
  final int roomsTotal;
  final bool wasFreePass;

  @override
  String get name => 'tour_completed';
  @override
  Map<String, Object?> get params => {
    'listing_id': listingId,
    'rooms_seen': roomsSeen,
    'rooms_total': roomsTotal,
    'completion': roomsSeen / roomsTotal,
    'free_pass': wasFreePass,
  };
}

// ─── ENTONNOIR ──────────────────────────────────────────────────────────────

final class OnboardingFinished extends AnalyticsEvent {
  const OnboardingFinished({
    required this.neighborhoods,
    required this.budgetMax,
  });
  final List<String> neighborhoods;
  final int budgetMax;
  @override
  String get name => 'onboarding_finished';
  @override
  Map<String, Object?> get params => {
    'neighborhoods': neighborhoods,
    'budget_max': budgetMax,
  };
}

final class PreviewOpened extends AnalyticsEvent {
  const PreviewOpened({required this.listingId, required this.visibleDegrees});
  final String listingId;

  /// Le réglage qui pilote la conversion : il DOIT être dans l'événement,
  /// sinon on ne pourra jamais l'optimiser (E2.1).
  final double visibleDegrees;
  @override
  String get name => 'preview_opened';
  @override
  Map<String, Object?> get params => {
    'listing_id': listingId,
    'visible_degrees': visibleDegrees,
  };
}

final class PaywallShown extends AnalyticsEvent {
  const PaywallShown({required this.listingId, required this.offers});
  final String listingId;
  final List<String> offers;
  @override
  String get name => 'paywall_shown';
  @override
  Map<String, Object?> get params => {
    'listing_id': listingId,
    'offers': offers,
  };
}

final class PassPurchased extends AnalyticsEvent {
  const PassPurchased({
    required this.listingId,
    required this.amountFcfa,
    required this.source, // purchase | free_first_visit | weekly_gift | credit_pack
    required this.operator,
  });
  final String listingId;
  final int amountFcfa;
  final String source;
  final String operator;
  @override
  String get name => 'pass_purchased';
  @override
  Map<String, Object?> get params => {
    'listing_id': listingId,
    'amount_fcfa': amountFcfa,
    'source': source,
    'operator': operator,
  };
}

/// ⚠️ SEUIL D'ARRÊT.
/// Au-delà de 10 %, le produit ne tient plus sa seule promesse et aucun
/// budget marketing ne compensera cela (GROWTH_MONETISATION.md §7).
final class PassRefunded extends AnalyticsEvent {
  const PassRefunded({required this.listingId, required this.reason});
  final String listingId;
  final String reason; // listing_gone | quality | support
  @override
  String get name => 'pass_refunded';
  @override
  Map<String, Object?> get params => {
    'listing_id': listingId,
    'reason': reason,
  };
}

final class PaymentFailed extends AnalyticsEvent {
  const PaymentFailed({
    required this.operator,
    required this.reason,
    required this.retryOffered,
  });
  final String operator;
  final String reason; // balance | network | timeout | cancelled
  final bool retryOffered;
  @override
  String get name => 'payment_failed';
  @override
  Map<String, Object?> get params => {
    'operator': operator,
    'reason': reason,
    'retry_offered': retryOffered,
  };
}

// ─── DÉCISION ───────────────────────────────────────────────────────────────

final class ListingSaved extends AnalyticsEvent {
  const ListingSaved({required this.listingId, required this.savedCount});
  final String listingId;
  final int savedCount;
  @override
  String get name => 'listing_saved';
  @override
  Map<String, Object?> get params => {
    'listing_id': listingId,
    'saved_count': savedCount,
  };
}

final class DuelResolved extends AnalyticsEvent {
  const DuelResolved({required this.winnerId, required this.outcome});
  final String? winnerId;
  final String outcome; // a | b | both | neither
  @override
  String get name => 'duel_resolved';
  @override
  Map<String, Object?> get params => {
    'winner_id': winnerId,
    'outcome': outcome,
  };
}

final class VisitRequested extends AnalyticsEvent {
  const VisitRequested({required this.listingId, required this.hadTour});
  final String listingId;

  /// Mesure l'efficacité du filtrage : visite 360 → RDV physique ≥ 25 %.
  final bool hadTour;
  @override
  String get name => 'visit_requested';
  @override
  Map<String, Object?> get params => {
    'listing_id': listingId,
    'had_tour': hadTour,
  };
}

final class ShortlistShared extends AnalyticsEvent {
  const ShortlistShared({required this.itemCount, required this.channel});
  final int itemCount;
  final String channel; // whatsapp | copy | other
  @override
  String get name => 'shortlist_shared';
  @override
  Map<String, Object?> get params => {
    'item_count': itemCount,
    'channel': channel,
  };
}

// ─── FRAÎCHEUR ET NOTIFICATIONS ─────────────────────────────────────────────

final class AlertActivated extends AnalyticsEvent {
  const AlertActivated({required this.neighborhoods});
  final List<String> neighborhoods;
  @override
  String get name => 'alert_activated';
  @override
  Map<String, Object?> get params => {'neighborhoods': neighborhoods};
}

final class FreshnessReported extends AnalyticsEvent {
  const FreshnessReported({required this.listingId, required this.ageDays});
  final String listingId;
  final int ageDays;
  @override
  String get name => 'freshness_reported';
  @override
  Map<String, Object?> get params => {
    'listing_id': listingId,
    'age_days': ageDays,
  };
}

/// Instrumenter les notifications REFUSÉES est ce qui permet de savoir si la
/// politique est trop sévère ou trop laxiste. Sans cela, on ne pilote qu'à
/// l'aveugle ce qu'on a envoyé.
final class NotificationSuppressed extends AnalyticsEvent {
  const NotificationSuppressed({required this.typeId, required this.reason});
  final String typeId;
  final String reason;
  @override
  String get name => 'notification_suppressed';
  @override
  Map<String, Object?> get params => {'type_id': typeId, 'reason': reason};
}

// ─── CONTEXTE D'USAGE ───────────────────────────────────────────────────────

final class LiteModeToggled extends AnalyticsEvent {
  const LiteModeToggled({required this.enabled, required this.auto});
  final bool enabled;
  final bool auto;
  @override
  String get name => 'lite_mode_toggled';
  @override
  Map<String, Object?> get params => {'enabled': enabled, 'auto': auto};
}

final class SunlightModeToggled extends AnalyticsEvent {
  const SunlightModeToggled({required this.enabled, required this.accepted});
  final bool enabled;

  /// Proposé automatiquement mais REFUSÉ par l'utilisateur : information utile,
  /// le seuil du capteur est peut-être mal réglé.
  final bool accepted;
  @override
  String get name => 'sunlight_mode_toggled';
  @override
  Map<String, Object?> get params => {'enabled': enabled, 'accepted': accepted};
}
