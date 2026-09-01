// La fraîcheur est LA promesse du produit. Une erreur de datation ici détruit
// la confiance que toute l'application existe pour bâtir.
//
// Ces tests naissent d'un vrai bug trouvé au premier lancement : une
// vérification de 23h48 s'affichait « aujourd'hui » alors qu'on était le
// lendemain matin. Le calcul comptait les heures écoulées, pas les jours.

import 'package:eazyrent/features/listing/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Freshness — jour calendaire, pas heures écoulées', () {
    final matin = DateTime(2026, 3, 12, 7, 48);

    test('LE BUG : 23h48 vu le lendemain matin est HIER, pas aujourd\'hui', () {
      final f = Freshness.from(DateTime(2026, 3, 11, 23, 48), now: matin);
      expect(f.label, contains('hier'));
      expect(f.label, isNot(contains("aujourd'hui")));
      expect(f.tone, FreshnessTone.ok);
    });

    test('même jour civil : « aujourd\'hui » avec l\'heure précise', () {
      final f = Freshness.from(DateTime(2026, 3, 12, 4, 48), now: matin);
      expect(f.label, "Vérifié aujourd'hui 04h48");
      expect(f.tone, FreshnessTone.ok);
    });

    test('minuit passé de peu reste « aujourd\'hui »', () {
      final f = Freshness.from(DateTime(2026, 3, 12, 0, 5), now: matin);
      expect(f.label, contains("aujourd'hui"));
    });

    test('4 jours : ton ambre, la dégradation est visible', () {
      final f = Freshness.from(DateTime(2026, 3, 8, 10), now: matin);
      expect(f.label, 'Vérifié il y a 4 jours');
      expect(f.tone, FreshnessTone.warn);
    });

    test('au-delà de 7 jours : on ne prétend plus que le bien est sûr', () {
      final f = Freshness.from(DateTime(2026, 2, 28, 10), now: matin);
      expect(f.label, contains('Non confirmé'));
      expect(f.tone, FreshnessTone.stale);
    });

    test('aucune vérification : on le dit, on ne l\'invente pas', () {
      final f = Freshness.from(null, now: matin);
      expect(f.label, 'Photos seulement');
      expect(f.tone, FreshnessTone.stale);
    });

    test('frontière 7/8 jours : le ton bascule au bon endroit', () {
      expect(
        Freshness.from(DateTime(2026, 3, 5, 10), now: matin).tone,
        FreshnessTone.warn, // 7 jours
      );
      expect(
        Freshness.from(DateTime(2026, 3, 4, 10), now: matin).tone,
        FreshnessTone.stale, // 8 jours
      );
    });
  });
}
