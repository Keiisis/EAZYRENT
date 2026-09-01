import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../data/auth_repository.dart';
import '../../domain/entities/account.dart';

/// Porte l'état d'authentification ET le motif d'échec courant.
/// Le motif est séparé de l'état : un code refusé ne fait pas régresser
/// l'utilisateur, il reste sur son écran avec une explication.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const Anonymous());

  final AuthRepository _repo;

  Failure? _lastFailure;
  bool _busy = false;

  Failure? get failure => _lastFailure;
  bool get busy => _busy;

  Future<void> restore() async {
    final r = await _repo.currentAccount();
    r.match((_) => emit(const Anonymous()), (acc) {
      emit(acc == null ? const Anonymous() : Authenticated(acc));
    });
  }

  Future<void> sendOtp(String digits, UserRole intendedRole) async {
    _lastFailure = null;
    _busy = true;
    emit(state);

    final phone = PhoneBj.toE164(digits);
    final r = await _repo.sendOtp(phone);

    _busy = false;
    r.match((f) {
      _lastFailure = f;
      emit(const Anonymous());
    }, (_) => emit(AwaitingOtp(phone: phone, intendedRole: intendedRole)));
  }

  Future<void> verify(String code) async {
    final s = state;
    if (s is! AwaitingOtp) return;

    _lastFailure = null;
    _busy = true;
    emit(s);

    final r = await _repo.verifyOtp(
      phoneE164: s.phone,
      code: code,
      intendedRole: s.intendedRole,
    );

    _busy = false;
    r.match(
      (f) {
        _lastFailure = f;
        // On reste sur l'écran de code : un échec ne renvoie jamais
        // l'utilisateur au début de son parcours.
        emit(AwaitingOtp(phone: s.phone, intendedRole: s.intendedRole));
      },
      (acc) =>
          emit(acc.hasAcceptedTerms ? Authenticated(acc) : NeedsConsent(acc)),
    );
  }

  Future<void> acceptTerms() async {
    final s = state;
    if (s is! NeedsConsent) return;
    await _repo.acceptTerms(s.account.id);
    emit(Authenticated(s.account));
  }

  /// Retour à l'état anonyme — qui reste un état de plein droit :
  /// le chercheur continue de naviguer, il perd seulement sa liste.
  Future<void> signOut() async {
    await _repo.signOut();
    emit(const Anonymous());
  }

  void cancelOtp() => emit(const Anonymous());
}
