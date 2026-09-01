import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/moments/moment.dart';
import '../../../../core/progression/stage_resolver.dart';
import '../../../../core/progression/user_stage.dart';
import '../../../listing/domain/entities/listing.dart';

/// Ma liste — et, à travers elle, le PALIER de l'utilisateur.
///
/// Cette classe est le premier endroit où les trois modules d'UX se
/// rencontrent réellement : garder un bien fait progresser le palier
/// (règle 10), ce qui fait apparaître des onglets, et émet une micro-victoire
/// (règle 7).
///
/// Le stockage est en mémoire pour l'instant. Drift le remplacera (P8) sans
/// que cette classe change : c'est l'intérêt d'avoir posé les contrats avant.
class ShortlistState extends Equatable {
  const ShortlistState({
    this.saved = const [],
    this.completedTours = 0,
    this.purchasedPasses = 0,
  });

  final List<Listing> saved;
  final int completedTours;
  final int purchasedPasses;

  bool contains(String id) => saved.any((l) => l.id == id);

  /// Le Duel n'apparaît qu'à partir de deux biens : comparer suppose d'avoir
  /// de quoi comparer.
  bool get canDuel => saved.length >= 2;

  ProgressionFacts get facts => ProgressionFacts(
    completedTours: completedTours,
    savedListings: saved.length,
    purchasedPasses: purchasedPasses,
  );

  ShortlistState copyWith({
    List<Listing>? saved,
    int? completedTours,
    int? purchasedPasses,
  }) => ShortlistState(
    saved: saved ?? this.saved,
    completedTours: completedTours ?? this.completedTours,
    purchasedPasses: purchasedPasses ?? this.purchasedPasses,
  );

  @override
  List<Object?> get props => [saved, completedTours, purchasedPasses];
}

class ShortlistCubit extends Cubit<ShortlistState> {
  ShortlistCubit(this._moments, this._resolver) : super(const ShortlistState());

  final MomentBus _moments;
  final StageResolver _resolver;

  UserStage get stage => _resolver.resolve(state.facts);

  void toggle(Listing listing) {
    final already = state.contains(listing.id);
    final next = already
        ? state.saved.where((l) => l.id != listing.id).toList()
        : [...state.saved, listing];

    emit(state.copyWith(saved: next));

    if (!already) {
      // Micro-victoire A4 : la liste se remplit visiblement.
      _moments.emit(
        state.saved.length == 1 ? Moment.firstSaveMade : Moment.duelResolved,
        payload: {'listing_id': listing.id, 'saved_count': next.length},
      );
    }
  }

  void remove(String id) => emit(
    state.copyWith(saved: state.saved.where((l) => l.id != id).toList()),
  );

  /// Appelé quand un tour est terminé (≥ 80 % des pièces vues).
  /// C'est CE fait — pas l'inscription — qui fait passer P0 → P1.
  void markTourCompleted() {
    emit(state.copyWith(completedTours: state.completedTours + 1));
    _moments.emit(Moment.tourCompleted);
  }

  void markPassPurchased() =>
      emit(state.copyWith(purchasedPasses: state.purchasedPasses + 1));
}
