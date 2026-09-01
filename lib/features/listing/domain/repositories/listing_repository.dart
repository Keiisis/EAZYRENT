import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../entities/listing.dart';

/// Les trois questions de l'onboarding, et rien de plus (UX_CORE_SPEC.md §9).
/// Une quatrième question ferait échouer la revue.
class SearchQuery extends Equatable {
  const SearchQuery({
    this.neighborhoods = const [],
    this.minRentFcfa,
    this.maxRentFcfa,
    this.propertyType,
    this.maxMoveInCostFcfa,
    this.verifiedTourOnly = false,
  });

  final List<String> neighborhoods;
  final int? minRentFcfa;
  final int? maxRentFcfa;
  final String? propertyType;

  /// F1 — « ce que je peux sortir aujourd'hui ». Filtre placé AU-DESSUS du
  /// loyer, parce que c'est lui qui décide.
  final int? maxMoveInCostFcfa;

  final bool verifiedTourOnly;

  @override
  List<Object?> get props => [
    neighborhoods,
    minRentFcfa,
    maxRentFcfa,
    propertyType,
    maxMoveInCostFcfa,
    verifiedTourOnly,
  ];
}

class FeedPage extends Equatable {
  const FeedPage({
    required this.listings,
    required this.fromCache,
    this.cachedAt,
  });

  final List<Listing> listings;

  /// P8 — hors-ligne n'est pas un cas dégradé. On affiche le cache AVEC sa
  /// date, jamais un écran vide.
  final bool fromCache;
  final DateTime? cachedAt;

  @override
  List<Object?> get props => [listings, fromCache, cachedAt];
}

abstract interface class ListingRepository {
  /// Tri par défaut : fraîcheur de publication, puis pertinence.
  /// Jamais par mise en avant payée sans le dire.
  Future<Either<Failure, FeedPage>> getFeed(
    SearchQuery query, {
    int limit = 20,
    int offset = 0,
  });

  Future<Either<Failure, Listing>> getById(String id);
}
