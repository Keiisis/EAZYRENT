import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../data/owner_repository.dart';

sealed class OwnerState extends Equatable {
  const OwnerState();
  @override
  List<Object?> get props => [];
}

final class OwnerLoading extends OwnerState {
  const OwnerLoading();
}

final class OwnerReady extends OwnerState {
  const OwnerReady({required this.listings, required this.requests});

  final List<OwnerListing> listings;
  final List<VisitRequest> requests;

  int get totalViews => listings.fold(0, (s, l) => s + l.views);
  int get pendingRequests => requests.where((r) => r.isPending).length;

  @override
  List<Object?> get props => [listings, requests];
}

/// Un bailleur sans bien n'est pas une erreur : c'est quelqu'un qui vient
/// d'arriver. L'état existe pour que l'écran propose « Publier un bien »
/// plutôt qu'une liste blanche.
final class OwnerEmpty extends OwnerState {
  const OwnerEmpty();
}

final class OwnerError extends OwnerState {
  const OwnerError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

/// L'état du bailleur : ses biens ET ses demandes, chargés ensemble.
///
/// LES DEUX VONT ENSEMBLE, et c'est délibéré. Le tableau de bord affiche
/// « 2 demandes » au-dessus de la liste des biens : deux chargements séparés
/// produiraient un écran où le compteur arrive avant ou après la liste, et
/// où l'un peut réussir pendant que l'autre échoue.
class OwnerCubit extends Cubit<OwnerState> {
  OwnerCubit(this._repo) : super(const OwnerLoading());

  final OwnerRepository _repo;

  Future<void> load() async {
    final listings = await _repo.myListings();

    await listings.match((f) async => emit(OwnerError(f)), (items) async {
      if (items.isEmpty) {
        emit(const OwnerEmpty());
        return;
      }
      final requests = await _repo.visitRequests();
      emit(
        OwnerReady(
          listings: items,
          // Une liste de demandes indisponible ne doit pas faire
          // disparaître les biens : on rend la liste vide et l'écran
          // reste utilisable.
          requests: requests.getOrElse((_) => const []),
        ),
      );
    });
  }

  /// Retirer ou remettre un bien en ligne.
  ///
  /// ON RECHARGE DEPUIS LA BASE après l'écriture, on ne modifie pas l'état
  /// local en pariant sur le succès. Un bien qu'on croit retiré et qui reste
  /// en ligne fait déplacer quelqu'un pour rien — c'est précisément ce que
  /// le produit vend d'éviter.
  Future<void> setAvailability(String listingId, {required bool online}) async {
    final result = await _repo.setAvailability(listingId, online);
    await result.match((f) async => emit(OwnerError(f)), (_) async => load());
  }

  Future<void> answer(String requestId, {required bool accept}) async {
    final result = await _repo.answerRequest(requestId, accept);
    await result.match((f) async => emit(OwnerError(f)), (_) async => load());
  }
}

sealed class EarningsState extends Equatable {
  const EarningsState();
  @override
  List<Object?> get props => [];
}

final class EarningsLoading extends EarningsState {
  const EarningsLoading();
}

final class EarningsReady extends EarningsState {
  const EarningsReady(this.earnings);
  final OwnerEarnings earnings;
  @override
  List<Object?> get props => [earnings];
}

final class EarningsError extends EarningsState {
  const EarningsError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

/// Les encaissements, séparés du tableau de bord.
///
/// UN CUBIT À PART, et pas un champ de plus dans `OwnerState` : la liste des
/// biens se recharge à chaque action du bailleur, alors que les loyers ne
/// bougent qu'une fois par mois. Les mélanger ferait relire la comptabilité
/// à chaque fois qu'on accepte un rendez-vous.
class EarningsCubit extends Cubit<EarningsState> {
  EarningsCubit(this._repo) : super(const EarningsLoading());

  final OwnerRepository _repo;

  Future<void> load() async {
    final result = await _repo.earnings();
    result.match((f) => emit(EarningsError(f)), (e) => emit(EarningsReady(e)));
  }
}
