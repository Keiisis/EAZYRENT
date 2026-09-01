import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/failure.dart';
import '../domain/entities/account.dart';

abstract interface class AuthRepository {
  /// Envoie un code par SMS. Aucun mot de passe, aucun e-mail.
  Future<Either<Failure, Unit>> sendOtp(String phoneE164);

  Future<Either<Failure, Account>> verifyOtp({
    required String phoneE164,
    required String code,
    required UserRole intendedRole,
  });

  Future<Either<Failure, Unit>> acceptTerms(String accountId);

  Future<Either<Failure, Account?>> currentAccount();

  Future<Either<Failure, Unit>> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._db);

  final sb.SupabaseClient _db;

  @override
  Future<Either<Failure, Unit>> sendOtp(String phoneE164) async {
    try {
      await _db.auth.signInWithOtp(phone: phoneE164);
      return const Right(unit);
    } on sb.AuthException catch (e) {
      return Left(_map(e));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> verifyOtp({
    required String phoneE164,
    required String code,
    required UserRole intendedRole,
  }) async {
    try {
      final res = await _db.auth.verifyOTP(
        phone: phoneE164,
        token: code,
        type: sb.OtpType.sms,
      );
      final user = res.user;
      if (user == null) {
        return const Left(ValidationFailure('Code incorrect. Réessaie.'));
      }

      // Le profil est créé au premier passage seulement. Le rôle choisi à
      // l'entrée est écrit ici — et il n'est plus modifiable ensuite sans une
      // bascule explicite.
      final existing = await _db
          .from('profiles')
          .select('id, role, full_name, phone_number, is_phone_verified')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await _db.from('profiles').insert({
          'id': user.id,
          'role': intendedRole.dbValue,
          'full_name': '',
          'phone_number': phoneE164,
          'is_phone_verified': true,
        });
        return Right(
          Account(
            id: user.id,
            role: intendedRole,
            phone: phoneE164,
            isPhoneVerified: true,
          ),
        );
      }

      return Right(
        Account(
          id: user.id,
          role: UserRole.fromDb(existing['role'] as String?),
          phone: existing['phone_number'] as String? ?? phoneE164,
          fullName: existing['full_name'] as String?,
          isPhoneVerified: true,
          hasAcceptedTerms: true,
        ),
      );
    } on sb.AuthException catch (e) {
      return Left(_map(e));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptTerms(String accountId) async {
    try {
      await _db
          .from('profiles')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', accountId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(debug: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account?>> currentAccount() async {
    final user = _db.auth.currentUser;
    if (user == null) return const Right(null);
    try {
      final row = await _db
          .from('profiles')
          .select('id, role, full_name, phone_number, is_phone_verified')
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return const Right(null);
      return Right(
        Account(
          id: user.id,
          role: UserRole.fromDb(row['role'] as String?),
          phone: row['phone_number'] as String? ?? '',
          fullName: row['full_name'] as String?,
          isPhoneVerified: row['is_phone_verified'] as bool? ?? false,
          hasAcceptedTerms: true,
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _db.auth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(debug: e.toString()));
    }
  }

  /// Les messages sont en français simple et disent QUOI FAIRE.
  /// Jamais un code technique à l'écran.
  Failure _map(sb.AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('expired')) {
      return const ValidationFailure(
        'Ce code a expiré. Demandes-en un nouveau.',
      );
    }
    if (m.contains('invalid') || m.contains('token')) {
      return const ValidationFailure('Code incorrect. Vérifie les 6 chiffres.');
    }
    if (m.contains('rate') || m.contains('limit')) {
      return const ValidationFailure(
        'Trop de tentatives. Patiente une minute avant de réessayer.',
      );
    }
    return ServerFailure(debug: e.message);
  }
}

/// Format béninois. `+229` est fixe : on ne demande pas à quelqu'un de
/// Cotonou de choisir son indicatif dans une liste de 200 pays.
abstract final class PhoneBj {
  static const prefix = '+229';

  /// « 97 12 34 56 » pendant la saisie.
  static String pretty(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final out = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 2 == 0) out.write(' ');
      out.write(d[i]);
    }
    return out.toString();
  }

  static String toE164(String digits) =>
      '$prefix${digits.replaceAll(RegExp(r'\D'), '')}';

  /// Le Bénin est passé à 10 chiffres (préfixe 01). On accepte les deux
  /// longueurs en circulation plutôt que de rejeter un numéro valide.
  static bool isValid(String digits) {
    final n = digits.replaceAll(RegExp(r'\D'), '').length;
    return n == 8 || n == 10;
  }
}
