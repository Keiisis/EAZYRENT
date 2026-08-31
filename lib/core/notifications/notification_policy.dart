// RÈGLE UX 8 — Notifications intelligentes.
//
// « Une notification ne s'envoie que si elle contient une information neuve
// que l'utilisateur ne pouvait pas connaître et qui appelle une action
// possible maintenant. » (UX_CORE_SPEC.md §8)
//
// Le test à trois questions est ici EXÉCUTABLE, pas une bonne intention.
// C'est le seul point d'émission de l'application (CONSTITUTION.md P9).

import 'package:equatable/equatable.dart';

enum NotificationKind {
  /// Soumis au plafond quotidien et aux heures de silence.
  content,

  /// Paiement, RDV, loyer, quittance. Échappe au plafond, jamais au bon sens.
  transactional,
}

enum NotificationChannel { push, whatsapp, sms }

enum SuppressionReason {
  noNewFact, // Q1
  notPersonal, // Q2
  notActionableNow, // Q3
  dailyBudgetSpent,
  quietHours,
  lowEngagementThrottle,
}

abstract class NotificationCandidate extends Equatable {
  const NotificationCandidate();

  String get typeId;
  NotificationKind get kind;

  /// Q1 — contient-elle un fait que l'utilisateur ne pouvait pas connaître ?
  bool get carriesNewFact;

  /// Q2 — ce fait est-il spécifique à CETTE personne ?
  bool get isPersonal;

  /// Q3 — peut-elle agir maintenant ? `Duration.zero` = tout de suite.
  Duration get actionableIn;
}

sealed class PolicyDecision {
  const PolicyDecision();
}

final class Send extends PolicyDecision {
  const Send(this.channel);
  final NotificationChannel channel;
}

final class Defer extends PolicyDecision {
  const Defer(this.until, this.reason);
  final DateTime until;
  final SuppressionReason reason;
}

/// Un refus est toujours MOTIVÉ et instrumenté (`NotificationSuppressed`).
/// Sans mesurer ce qu'on n'envoie pas, on ne sait pas si la politique est
/// trop sévère ou trop laxiste : on pilote à l'aveugle.
final class Suppress extends PolicyDecision {
  const Suppress(this.reason);
  final SuppressionReason reason;
}

/// Ce que la politique a besoin de savoir sur l'historique récent.
class NotificationLedger extends Equatable {
  const NotificationLedger({
    required this.contentSentToday,
    required this.openRateByType,
  });

  final int contentSentToday;

  /// Taux d'ouverture sur 14 jours glissants, par `typeId`.
  final Map<String, double> openRateByType;

  @override
  List<Object?> get props => [contentSentToday, openRateByType];
}

abstract interface class NotificationPolicy {
  PolicyDecision evaluate(
    NotificationCandidate c,
    NotificationLedger ledger,
    DateTime now,
  );
}

class DefaultNotificationPolicy implements NotificationPolicy {
  const DefaultNotificationPolicy();

  static const maxContentPerDay = 2;
  static const quietStartHour = 21;
  static const quietEndHour = 7;
  static const throttleBelowOpenRate = 0.15;
  static const actionableWindow = Duration(minutes: 10);

  @override
  PolicyDecision evaluate(
    NotificationCandidate c,
    NotificationLedger ledger,
    DateTime now,
  ) {
    // Les trois questions, dans l'ordre. Aucune ne se contourne.
    if (!c.carriesNewFact) return const Suppress(SuppressionReason.noNewFact);
    if (!c.isPersonal) return const Suppress(SuppressionReason.notPersonal);
    if (c.actionableIn > actionableWindow) {
      return Defer(now.add(c.actionableIn), SuppressionReason.notActionableNow);
    }

    final channel = _routeChannel(c);

    // Le transactionnel échappe au plafond : un rappel de loyer ou un échec
    // de paiement n'est pas du contenu.
    if (c.kind == NotificationKind.transactional) return Send(channel);

    if (_isQuietHour(now)) {
      return Defer(_nextMorning(now), SuppressionReason.quietHours);
    }
    if (ledger.contentSentToday >= maxContentPerDay) {
      return const Suppress(SuppressionReason.dailyBudgetSpent);
    }

    // Réduction automatique AVANT que l'utilisateur ne coupe tout.
    final rate = ledger.openRateByType[c.typeId];
    if (rate != null && rate < throttleBelowOpenRate) {
      return const Suppress(SuppressionReason.lowEngagementThrottle);
    }

    return Send(channel);
  }

  /// Push pour l'urgent et le contextuel. WhatsApp pour le transactionnel
  /// important, parce qu'il est lu ET archivé. SMS en repli hors data — ce qui
  /// arrive tous les jours au Bénin.
  NotificationChannel _routeChannel(NotificationCandidate c) =>
      c.kind == NotificationKind.transactional
      ? NotificationChannel.whatsapp
      : NotificationChannel.push;

  bool _isQuietHour(DateTime t) =>
      t.hour >= quietStartHour || t.hour < quietEndHour;

  DateTime _nextMorning(DateTime t) {
    final base = t.hour >= quietStartHour ? t.add(const Duration(days: 1)) : t;
    return DateTime(base.year, base.month, base.day, quietEndHour);
  }
}
