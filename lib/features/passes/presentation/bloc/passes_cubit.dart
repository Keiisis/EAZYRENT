import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../data/passes_repository.dart';

sealed class PassesState extends Equatable {
  const PassesState();
  @override
  List<Object?> get props => [];
}

final class PassesLoading extends PassesState {
  const PassesLoading();
}

final class PassesReady extends PassesState {
  const PassesReady({required this.wallet, required this.history});

  final CreditWallet wallet;
  final List<PaymentRecord> history;

  @override
  List<Object?> get props => [wallet, history];
}

final class PassesError extends PassesState {
  const PassesError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

/// Le solde et l'historique.
///
/// IL N'Y A PAS D'ÉTAT « VIDE » ICI, et c'est voulu : un solde de zéro est un
/// solde valide, qui s'affiche comme tel. Le fabriquer en état séparé ferait
/// disparaître les offres de recharge au moment précis où elles servent.
class PassesCubit extends Cubit<PassesState> {
  PassesCubit(this._repo) : super(const PassesLoading());

  final PassesRepository _repo;

  Future<void> load() async {
    final wallet = await _repo.wallet();

    await wallet.match((f) async => emit(PassesError(f)), (w) async {
      final history = await _repo.history();
      emit(
        PassesReady(
          wallet: w,
          // Un historique indisponible ne cache pas le solde : le chiffre
          // qui compte est celui des crédits restants.
          history: history.getOrElse((_) => const []),
        ),
      );
    });
  }
}
