// RÈGLE UX 7 — Actions clés et micro-victoires.
//
// « Une habitude se construit par des victoires petites, immédiates et
// visibles. » (UX_CORE_SPEC.md §7)
//
// Sans bus unique, la logique de célébration se recopie dans huit écrans,
// devient incohérente au troisième sprint et disparaît au sixième.

import 'dart:async';

enum Moment {
  /// LA victoire centrale. « Tu as tout vu de ce logement sans bouger. »
  tourCompleted,

  firstSaveMade,

  /// « Ton finaliste. » — la liste devient une décision.
  duelResolved,

  alertActivated,

  /// F2 — le signalement récompensé : l'incident devient une réciprocité.
  reportRewarded,

  weeklyCreditGranted,

  /// F5 — « Ta sœur a voté pour le bien de Fidjrossè. »
  familyVoteReceived,

  /// Règle du pic-fin, côté locataire installé.
  rentReceiptIssued,
}

class MomentEvent {
  const MomentEvent(this.moment, {this.payload = const {}});
  final Moment moment;
  final Map<String, Object?> payload;
}

/// Émission unique, abonnement libre. Les widgets écoutent, ils ne décident pas.
class MomentBus {
  final _controller = StreamController<MomentEvent>.broadcast();

  Stream<MomentEvent> get stream => _controller.stream;
  Stream<MomentEvent> only(Moment m) =>
      _controller.stream.where((e) => e.moment == m);

  void emit(Moment m, {Map<String, Object?> payload = const {}}) =>
      _controller.add(MomentEvent(m, payload: payload));

  Future<void> dispose() => _controller.close();
}
