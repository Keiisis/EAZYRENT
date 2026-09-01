import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../datasources/listing_remote_datasource.dart';

/// Aucune exception ne traverse la couche domaine : tout devient un `Failure`
/// porteur d'un message qui dit QUOI FAIRE (CONSTITUTION, UI_DESIGN_SYSTEM §7).
class ListingRepositoryImpl implements ListingRepository {
  ListingRepositoryImpl(this._remote);

  final ListingRemoteDataSource _remote;

  /// Cache mémoire minimal, daté. Sera remplacé par Drift (P8) ; l'interface
  /// ne changera pas — c'est tout l'intérêt d'avoir posé le contrat d'abord.
  List<Listing>? _lastFeed;
  DateTime? _lastFeedAt;

  @override
  Future<Either<Failure, FeedPage>> getFeed(
    SearchQuery query, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final listings = await _remote.fetchFeed(
        query,
        limit: limit,
        offset: offset,
      );
      if (offset == 0) {
        _lastFeed = listings;
        _lastFeedAt = DateTime.now();
      }
      return Right(FeedPage(listings: listings, fromCache: false));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      // Hors-ligne : on rend le cache AVEC sa date, jamais un écran vide.
      if (_lastFeed != null) {
        return Right(
          FeedPage(
            listings: _lastFeed!,
            fromCache: true,
            cachedAt: _lastFeedAt,
          ),
        );
      }
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Listing>> getById(String id) async {
    try {
      return Right(await _remote.fetchById(id));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return const Left(ListingGoneFailure());
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }
}
