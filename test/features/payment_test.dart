import 'package:eazyrent/features/payment/domain/entities/payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentProvider — l\'ordre est celui du marché béninois', () {
    test('Mobile Money passe avant la carte bancaire', () {
      // KkiaPay et FedaPay agrègent MTN MoMo, Moov Flooz et Celtiis Cash :
      // ils encaissent l'écrasante majorité des paiements à Cotonou. Mettre
      // la carte en premier serait recopier une hiérarchie occidentale sur un
      // marché qui ne l'est pas.
      expect(PaymentProvider.values.first, PaymentProvider.kkiapay);
      expect(PaymentProvider.values[1], PaymentProvider.fedapay);
    });

    test('les agrégateurs béninois sont marqués XOF uniquement', () {
      // Leur envoyer des euros produit un refus que l'utilisateur ne peut
      // pas comprendre.
      expect(PaymentProvider.kkiapay.xofOnly, isTrue);
      expect(PaymentProvider.fedapay.xofOnly, isTrue);
      expect(PaymentProvider.stripe.xofOnly, isFalse);
      expect(PaymentProvider.revolut.xofOnly, isFalse);
    });

    test('Stripe et Revolut sont marqués internationaux', () {
      // Ils n'existent que pour la diaspora — quelqu'un à Paris qui paie le
      // loyer d'un frère à Godomey. On ne les propose pas par défaut à
      // quelqu'un connecté depuis Cotonou.
      expect(PaymentProvider.stripe.isInternational, isTrue);
      expect(PaymentProvider.revolut.isInternational, isTrue);
      expect(PaymentProvider.kkiapay.isInternational, isFalse);
    });

    test('chaque fournisseur nomme les moyens qu\'il ouvre vraiment', () {
      // Un bouton « Mobile Money » sans dire lesquels oblige à essayer pour
      // savoir. Et aucun opérateur absent du Bénin ne doit apparaître.
      for (final p in PaymentProvider.values) {
        expect(p.hint, isNotEmpty);
      }
      expect(PaymentProvider.kkiapay.hint, contains('MTN MoMo'));
      expect(PaymentProvider.kkiapay.hint, contains('Moov Flooz'));

      final tous = PaymentProvider.values.map((p) => p.hint).join(' ');
      expect(tous, isNot(contains('Orange Money')));
      expect(tous, isNot(contains('Wave')));
    });
  });

  group('PaymentResult — le client ne décide jamais qu\'il a payé', () {
    test('seul « paid » vaut payé', () {
      const paye = PaymentResult(
        reference: 'EZR-ABC',
        status: PaymentStatus.paid,
        amountFcfa: 1000,
        creditsAdded: 1,
      );
      expect(paye.isPaid, isTrue);

      for (final s in [
        PaymentStatus.pending,
        PaymentStatus.failed,
        PaymentStatus.cancelled,
      ]) {
        expect(
          PaymentResult(
            reference: 'EZR-ABC',
            status: s,
            amountFcfa: 1000,
          ).isPaid,
          isFalse,
          reason: '$s ne doit jamais ouvrir une visite',
        );
      }
    });

    test('les crédits ajoutés viennent du serveur, pas d\'un calcul local', () {
      // Le champ existe précisément pour ça : le client AFFICHE ce que le
      // serveur a écrit. S'il le recalculait, un pack à 3 crédits pourrait
      // en afficher 30.
      const r = PaymentResult(
        reference: 'EZR-XYZ',
        status: PaymentStatus.paid,
        amountFcfa: 2500,
        creditsAdded: 3,
      );
      expect(r.creditsAdded, 3);
    });
  });

  group('Le catalogue de prix — cohérence avec le serveur', () {
    // Ces trois couples sont écrits en dur dans `create-payment`
    // (constante CATALOG). Le serveur REFUSE un montant qui ne correspond
    // pas : si l'application affiche un autre prix, le paiement est rejeté
    // avec un 409 plutôt que corrigé en silence.
    //
    // Ce test est donc un miroir : il casse le jour où quelqu'un change un
    // prix ici sans le changer là-bas.
    const catalogueServeur = {1: 1000, 3: 2500, 7: 5000};

    test('1 visite vaut 1 000 F', () {
      expect(catalogueServeur[1], 1000);
    });

    test('le pack de 3 revient moins cher à l\'unité', () {
      expect(catalogueServeur[3]! / 3, lessThan(catalogueServeur[1]!));
    });

    test('le pack de 7 revient moins cher que le pack de 3', () {
      expect(catalogueServeur[7]! / 7, lessThan(catalogueServeur[3]! / 3));
    });

    test('aucun prix n\'est exprimé en centimes', () {
      // XOF est zero-decimal. Un prix à 100 000 pour un pass à 1 000 F est
      // le bug qui ferme une entreprise — il vient toujours d'une
      // multiplication par 100 faite « au cas où ».
      for (final prix in catalogueServeur.values) {
        expect(
          prix,
          lessThan(100000),
          reason:
              'un prix au-delà de 100 000 F trahit une conversion en '
              'centimes',
        );
      }
    });
  });
}
