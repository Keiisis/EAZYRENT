import 'dart:async';

import 'package:eazyrent/core/errors/failure.dart';
import 'package:eazyrent/features/listing/domain/entities/listing.dart';
import 'package:eazyrent/features/listing/domain/entities/property_type.dart';
import 'package:eazyrent/features/listing/domain/repositories/listing_repository.dart';
import 'package:eazyrent/features/search/presentation/bloc/feed_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Dépôt qui répond DANS LE DÉSORDRE, comme le réseau réel : la requête large
/// (donc lente à revenir en dernier ici) rend tout, la requête filtrée rend
/// peu. C'est exactement la situation qui a produit le bug observé sur
/// l'appareil.
class _OutOfOrderRepository implements ListingRepository {
  final _pending = <SearchQuery, Completer<FeedPage>>{};

  @override
  Future<Either<Failure, FeedPage>> getFeed(
    SearchQuery query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final c = Completer<FeedPage>();
    _pending[query] = c;
    return Right(await c.future);
  }

  void respond(SearchQuery query, List<Listing> listings) =>
      _pending[query]!.complete(FeedPage(listings: listings, fromCache: false));

  @override
  Future<Either<Failure, Listing>> getById(String id) async =>
      throw UnimplementedError();
}

Listing _listing(String id, String quartier) => Listing(
  id: id,
  monthlyRentFcfa: 35000,
  propertyType: 'Chambre-salon',
  neighborhood: quartier,
  city: 'Cotonou',
  hasVerifiedTour: false,
  isAvailable: true,
  freshness: Freshness.from(null),
);

void main() {
  group('FeedCubit — une étiquette ne couvre jamais d\'autres résultats', () {
    test(
      'la réponse de la requête abandonnée est jetée, pas affichée',
      () async {
        final repo = _OutOfOrderRepository();
        final cubit = FeedCubit(repo);

        const large = SearchQuery();
        const cible = SearchQuery(neighborhoods: ['Fidjrossè']);

        // Deux chargements se chevauchent : celui du démarrage, puis celui
        // que l'onboarding déclenche.
        final first = cubit.load(large);
        final second = cubit.load(cible);

        // La requête filtrée revient d'abord.
        repo.respond(cible, [_listing('1', 'Fidjrossè')]);
        await second;

        // Puis la large, périmée, arrive en retard avec TOUT le parc.
        repo.respond(large, [
          _listing('1', 'Fidjrossè'),
          _listing('2', 'Godomey'),
          _listing('3', 'Agla'),
        ]);
        await first;

        final state = cubit.state;
        expect(state, isA<FeedReady>());
        state as FeedReady;

        // L'étiquette affichée et les biens affichés parlent du MÊME filtre.
        expect(state.query.neighborhoods, ['Fidjrossè']);
        expect(state.listings.length, 1);
        expect(
          state.listings.every((l) => l.neighborhood == 'Fidjrossè'),
          isTrue,
          reason:
              'Un bandeau « Fidjrossè » au-dessus de biens de Godomey est '
              'la seule chose que ce produit ne peut pas se permettre.',
        );
      },
    );
  });

  group('PropertyTypes — les libellés correspondent à la base', () {
    test('chaque libellé proposé a un code, et il fait l\'aller-retour', () {
      for (final label in PropertyTypes.labels) {
        final code = PropertyTypes.codeOf(label);
        expect(
          code,
          isNotNull,
          reason:
              '« $label » est proposé à l\'utilisateur mais n\'existe pas '
              'dans property_type_enum : le filtre ne rendrait jamais rien.',
        );
        expect(PropertyTypes.labelOf(code), label);
      }
    });

    test('les codes sont ceux de property_type_enum, pas des inventions', () {
      // Valeurs exactes de DATABASE_SCHEMA.sql ligne 17.
      const enSql = {'room', 'apartment', 'villa_house', 'land', 'commercial'};
      expect(PropertyTypes.labelToCode.values.toSet(), enSql);
    });

    test('un code inconnu ne se déguise pas en type existant', () {
      expect(PropertyTypes.labelOf('penthouse'), 'Logement');
      expect(PropertyTypes.codeOf('Studio'), isNull);
    });
  });
}
