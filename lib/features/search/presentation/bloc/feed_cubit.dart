import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/domain/repositories/listing_repository.dart';

/// Les 5 états d'écran de UI_DESIGN_SYSTEM §8, rendus impossibles à oublier :
/// une union scellée force le `switch` exhaustif côté widget.
sealed class FeedState extends Equatable {
  const FeedState();
  @override
  List<Object?> get props => [];
}

final class FeedLoading extends FeedState {
  const FeedLoading();
}

final class FeedReady extends FeedState {
  const FeedReady({
    required this.listings,
    required this.query,
    this.fromCache = false,
    this.cachedAt,
    this.newSinceYesterday = 0,
  });

  final List<Listing> listings;
  final SearchQuery query;

  /// P8 — le cache s'affiche AVEC sa date, jamais en silence.
  final bool fromCache;
  final DateTime? cachedAt;

  /// Micro-victoire A1 : « 4 nouveaux depuis hier ». N'apparaît que s'il y a
  /// réellement du nouveau — un bandeau permanent devient invisible en 3 jours.
  final int newSinceYesterday;

  @override
  List<Object?> get props => [listings, query, fromCache, newSinceYesterday];
}

/// Jamais un cul-de-sac : l'état vide porte TOUJOURS deux issues.
final class FeedEmpty extends FeedState {
  const FeedEmpty({required this.query, this.widerNeighborhoodCount});

  final SearchQuery query;

  /// « Élargir à Godomey (12 biens) » — la proposition doit être chiffrée,
  /// sinon ce n'est pas une issue, c'est une suggestion.
  final int? widerNeighborhoodCount;

  @override
  List<Object?> get props => [query, widerNeighborhoodCount];
}

final class FeedError extends FeedState {
  const FeedError(this.failure, {this.staleListings = const []});

  final Failure failure;

  /// On garde ce qu'on avait plutôt que de tout effacer.
  final List<Listing> staleListings;

  @override
  List<Object?> get props => [failure, staleListings];
}

class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._repository) : super(const FeedLoading());

  final ListingRepository _repository;
  SearchQuery _query = const SearchQuery();

  SearchQuery get query => _query;

  Future<void> load(SearchQuery query) async {
    _query = query;
    emit(const FeedLoading());
    await _fetch();
  }

  /// Rechargement silencieux : on ne repasse pas par le squelette si on a
  /// déjà du contenu à l'écran.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    final result = await _repository.getFeed(_query);

    result.match(
      (failure) => emit(
        FeedError(
          failure,
          staleListings: switch (state) {
            FeedReady(:final listings) => listings,
            _ => const [],
          },
        ),
      ),
      (page) {
        if (page.listings.isEmpty) {
          emit(FeedEmpty(query: _query));
          return;
        }
        emit(
          FeedReady(
            listings: page.listings,
            query: _query,
            fromCache: page.fromCache,
            cachedAt: page.cachedAt,
          ),
        );
      },
    );
  }
}
