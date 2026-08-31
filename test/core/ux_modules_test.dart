// Les trois modules qui portent les règles UX 7, 8 et 10.
// S'ils cassent, le produit perd ses mécanismes sans qu'aucun écran ne plante :
// c'est exactement le genre de régression qu'un test doit attraper.

import 'package:eazyrent/core/moments/savings_counter.dart';
import 'package:eazyrent/core/notifications/notification_policy.dart';
import 'package:eazyrent/core/progression/stage_resolver.dart';
import 'package:eazyrent/core/progression/user_stage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Candidate extends NotificationCandidate {
  const _Candidate({
    this.typeId = 'neighborhood_alert',
    this.kind = NotificationKind.content,
    this.carriesNewFact = true,
    this.isPersonal = true,
    this.actionableIn = Duration.zero,
  });

  @override
  final String typeId;
  @override
  final NotificationKind kind;
  @override
  final bool carriesNewFact;
  @override
  final bool isPersonal;
  @override
  final Duration actionableIn;

  @override
  List<Object?> get props => [typeId, kind, carriesNewFact, isPersonal];
}

void main() {
  group('RÈGLE 10 — StageResolver', () {
    const r = DefaultStageResolver();

    test('un compte sans tour terminé reste P0, même inscrit', () {
      // P2 : c'est la valeur vécue qui fait progresser, pas l'inscription.
      expect(
        r.resolve(const ProgressionFacts(hasAccount: true)),
        UserStage.p0Curieux,
      );
    });

    test('un tour terminé suffit à passer P1', () {
      expect(
        r.resolve(const ProgressionFacts(completedTours: 1)),
        UserStage.p1Eveille,
      );
    });

    test('2 biens gardés OU 1 pass acheté ouvrent P2', () {
      expect(
        r.resolve(const ProgressionFacts(completedTours: 1, savedListings: 2)),
        UserStage.p2Chasseur,
      );
      expect(
        r.resolve(
          const ProgressionFacts(completedTours: 1, purchasedPasses: 1),
        ),
        UserStage.p2Chasseur,
      );
    });

    test('publier bascule sur l\'axe bailleur, pas sur l\'axe chercheur', () {
      // Un bailleur n'est pas « plus avancé » qu'un locataire : il fait
      // autre chose. La bascule de rôle est explicite.
      expect(
        r.resolve(const ProgressionFacts(publishedListings: 1)),
        UserStage.p5Bailleur,
      );
      expect(
        r.resolve(const ProgressionFacts(isAgency: true)),
        UserStage.p6Pro,
      );
    });
  });

  group('RÈGLE 8 — NotificationPolicy', () {
    const p = DefaultNotificationPolicy();
    const empty = NotificationLedger(contentSentToday: 0, openRateByType: {});
    final midday = DateTime(2026, 3, 12, 14);

    test('Q1 — sans fait nouveau, refus motivé', () {
      final d = p.evaluate(
        const _Candidate(carriesNewFact: false),
        empty,
        midday,
      );
      expect(d, isA<Suppress>());
      expect((d as Suppress).reason, SuppressionReason.noNewFact);
    });

    test('Q2 — non personnel, refus motivé', () {
      final d = p.evaluate(const _Candidate(isPersonal: false), empty, midday);
      expect((d as Suppress).reason, SuppressionReason.notPersonal);
    });

    test('Q3 — non actionable maintenant, différé et non supprimé', () {
      final d = p.evaluate(
        const _Candidate(actionableIn: Duration(hours: 6)),
        empty,
        midday,
      );
      expect(d, isA<Defer>());
    });

    test('plafond de 2 contenus par jour', () {
      const full = NotificationLedger(contentSentToday: 2, openRateByType: {});
      final d = p.evaluate(const _Candidate(), full, midday);
      expect((d as Suppress).reason, SuppressionReason.dailyBudgetSpent);
    });

    test('silence 21h-7h pour le contenu, différé au matin', () {
      final night = DateTime(2026, 3, 12, 22);
      final d = p.evaluate(const _Candidate(), empty, night);
      expect(d, isA<Defer>());
      expect((d as Defer).until.hour, 7);
      expect(d.until.day, 13); // reporté au lendemain matin, pas à ce matin
    });

    test('le transactionnel échappe au plafond ET part sur WhatsApp', () {
      const full = NotificationLedger(contentSentToday: 5, openRateByType: {});
      final d = p.evaluate(
        const _Candidate(
          typeId: 'rent_due',
          kind: NotificationKind.transactional,
        ),
        full,
        midday,
      );
      expect(d, isA<Send>());
      expect((d as Send).channel, NotificationChannel.whatsapp);
    });

    test('réduction automatique sous 15 % d\'ouverture sur 14 jours', () {
      const weak = NotificationLedger(
        contentSentToday: 0,
        openRateByType: {'neighborhood_alert': 0.09},
      );
      final d = p.evaluate(const _Candidate(), weak, midday);
      expect((d as Suppress).reason, SuppressionReason.lowEngagementThrottle);
    });
  });

  group('RÈGLE 7 — SavingsCounter', () {
    const c = SavingsCounter();

    test('sans coût déclaré par l\'utilisateur, AUCUN compteur', () {
      // On n'invente pas une moyenne. Le compteur n'existe pas.
      expect(c.compute(toursCompleted: 5, passesPaidFcfa: 3000), isNull);
    });

    test('l\'économie affichée est NETTE des pass payés', () {
      final s = c.compute(
        toursCompleted: 5,
        passesPaidFcfa: 3000,
        declaredTripCostFcfa: 2000,
      );
      expect(s!.amountSavedFcfa, 7000); // 5 × 2000 − 3000
    });

    test('rien à célébrer quand le net est négatif : on se tait', () {
      expect(
        c.compute(
          toursCompleted: 1,
          passesPaidFcfa: 3000,
          declaredTripCostFcfa: 500,
        ),
        isNull,
      );
    });
  });
}
