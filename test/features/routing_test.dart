import 'package:eazyrent/core/geo/travel_mode.dart';
import 'package:eazyrent/features/navigation/data/valhalla_routing_service.dart';
import 'package:eazyrent/features/navigation/domain/entities/route_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Polyline précision 6 — le piège qui ne lève aucune erreur', () {
    test('un tracé Valhalla retombe bien sur Cotonou', () {
      // Extrait réel d'une réponse `valhalla1.openstreetmap.de` pour le
      // trajet Ganhi → Fidjrossè, profil motorcycle.
      const shape = 'srocKyarrC_vAulB{c@f\\yd@~\\{c@f\\{c@f\\qJdH';

      final points = ValhallaRoutingService.decodePolyline6(shape);

      expect(points, isNotEmpty);
      final first = points.first;

      // Cotonou est autour de 6,36 N / 2,42 E. Décoder en précision 5 —
      // l'erreur naturelle, puisque Google et OSRM utilisent 5 — donnerait
      // 0,63 / 0,24, c'est-à-dire le golfe de Guinée, à 700 km au sud. Aucune
      // exception n'est levée : le tracé s'affiche simplement ailleurs.
      expect(first.latitude, closeTo(6.36, 0.15));
      expect(first.longitude, closeTo(2.42, 0.15));
    });

    test('le décodage est monotone, pas une poignée de points isolés', () {
      const shape = 'srocKyarrC_vAulB{c@f\\yd@~\\{c@f\\{c@f\\qJdH';
      final points = ValhallaRoutingService.decodePolyline6(shape);
      expect(points.length, greaterThan(3));

      // Deux points consécutifs d'un tracé urbain ne sautent pas de 5 km.
      const d = Distance();
      for (var i = 1; i < points.length; i++) {
        expect(
          d(points[i - 1], points[i]),
          lessThan(5000),
          reason: 'saut aberrant entre les points $i-1 et $i',
        );
      }
    });
  });

  group('Instructions — lisibles à voix haute en circulation', () {
    test('un nom de rue répété par Valhalla est replié', () {
      // Relevé tel quel sur l'appareil, trajet Cadjéhoun → Fidjrossè.
      expect(
        ValhallaRoutingService.tidyInstruction(
          "Conduisez vers l'est sur Rue 12.172/12.172.",
        ),
        "Conduisez vers l'est sur Rue 12.172.",
      );
    });

    test('un VRAI carrefour à deux noms reste intact', () {
      // La rétroréférence est ce qui fait la différence. Sans elle, la
      // première version de cette fonction repliait n'importe quelle barre
      // oblique et transformait un carrefour en une seule rue.
      const carrefour = 'Tournez à droite sur Rue Cotonou/Calavi.';
      expect(ValhallaRoutingService.tidyInstruction(carrefour), carrefour);
    });

    test("une instruction sans barre oblique n'est pas touchée", () {
      const simple = 'Continuez sur le Boulevard de la Marina.';
      expect(ValhallaRoutingService.tidyInstruction(simple), simple);
    });

    test('un doublon en fin de phrase, sans ponctuation, est replié aussi', () {
      expect(
        ValhallaRoutingService.tidyInstruction('Prenez la RNIE1/RNIE1'),
        'Prenez la RNIE1',
      );
    });

    test('un doublon contenant un espace est LAISSÉ tel quel', () {
      // Limite assumée : replier « RNIE 1/RNIE 1 » demanderait de deviner où
      // s'arrête un nom de voie. Mieux vaut une instruction un peu lourde
      // qu'une instruction fausse — on ne coupe jamais un nom de rue au
      // hasard pour faire joli.
      const avecEspace = 'Prenez la RNIE 1/RNIE 1';
      expect(ValhallaRoutingService.tidyInstruction(avecEspace), avecEspace);
    });
  });

  group('TravelMode — le zem est le mode principal, pas la voiture', () {
    test('le zem vient en premier dans l\'ordre d\'affichage', () {
      expect(TravelMode.values.first, TravelMode.zem);
    });

    test('chaque mode a un profil de coût Valhalla distinct', () {
      final costings = TravelMode.values.map((m) => m.costing).toSet();
      expect(costings.length, TravelMode.values.length);
      expect(TravelMode.zem.costing, 'motorcycle');
      expect(TravelMode.walk.costing, 'pedestrian');
      expect(TravelMode.bike.costing, 'bicycle');
      expect(TravelMode.car.costing, 'auto');
    });

    test('le zem est signalé comme partageant le calage de la voiture', () {
      // MESURÉ sur Ganhi → Fidjrossè : motorcycle et auto rendent tous deux
      // 13 min pour 6,33 km. Valhalla ne modélise pas le faufilage. Le
      // drapeau existe pour que l'écran le DISE, au lieu de laisser croire
      // à un calcul spécifique au zémidjan.
      expect(TravelMode.zem.sharesCarTiming, isTrue);
      expect(TravelMode.walk.sharesCarTiming, isFalse);
      expect(TravelMode.bike.sharesCarTiming, isFalse);
    });
  });

  group('RoutePlan — les libellés se lisent, ils ne se déchiffrent pas', () {
    RoutePlan plan({required int meters, required int seconds}) => RoutePlan(
      mode: TravelMode.zem,
      distanceMeters: meters,
      duration: Duration(seconds: seconds),
      geometry: const [],
      steps: const [],
    );

    test('sous le kilomètre, on compte en mètres', () {
      expect(plan(meters: 850, seconds: 300).distanceLabel, '850 m');
    });

    test('au-delà, en kilomètres avec UNE décimale et une virgule', () {
      expect(plan(meters: 6329, seconds: 780).distanceLabel, '6,3 km');
    });

    test('au-delà de l\'heure, personne ne compte en minutes', () {
      expect(plan(meters: 1, seconds: 3900).durationLabel, '1 h 05');
      expect(plan(meters: 1, seconds: 7200).durationLabel, '2 h');
      expect(plan(meters: 1, seconds: 780).durationLabel, '13 min');
    });

    test('un trajet de quelques secondes ne s\'affiche pas « 0 min »', () {
      expect(plan(meters: 20, seconds: 25).durationLabel, 'moins d\'1 min');
    });
  });
}
