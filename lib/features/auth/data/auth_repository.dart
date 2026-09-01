import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/failure.dart';
import '../domain/entities/account.dart';

abstract interface class AuthRepository {
  /// Envoie un code par E-MAIL. Aucun mot de passe.
  ///
  /// Le SMS aurait ete le bon canal sur ce marche — il est lu, l'e-mail
  /// beaucoup moins. C'est un arbitrage de budget, pas de conception : les
  /// passerelles SMS beninoises sont payantes des le premier envoi.
  /// A rebasculer vers le SMS des que le budget le permet ; seul ce fichier
  /// et deux ecrans changeront.
  Future<Either<Failure, Unit>> sendOtp(String email);

  Future<Either<Failure, Account>> verifyOtp({
    required String email,
    required String code,
    required String phoneE164,
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
  Future<Either<Failure, Unit>> sendOtp(String email) async {
    try {
      // shouldCreateUser: le compte se cree au premier code valide.
      await _db.auth.signInWithOtp(email: email, shouldCreateUser: true);
      return const Right(unit);
    } on sb.AuthException catch (e) {
      return Left(_map(e));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> verifyOtp({
    required String email,
    required String code,
    required String phoneE164,
    required UserRole intendedRole,
  }) async {
    try {
      final res = await _db.auth.verifyOTP(
        email: email,
        token: code,
        type: sb.OtpType.email,
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
          .select('id, role, full_name, phone_number, email, is_phone_verified')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await _db.from('profiles').insert({
          'id': user.id,
          'role': intendedRole.dbValue,
          'full_name': '',
          'phone_number': phoneE164,
          'email': email,
          // Le code a valide l'E-MAIL, pas le numero. Le dire honnetement :
          // un badge « telephone verifie » qui ne l'est pas serait un
          // mensonge affiche a l'autre partie d'une transaction.
          'is_phone_verified': false,
        });
        return Right(
          Account(
            id: user.id,
            role: intendedRole,
            phone: phoneE164,
            email: email,
          ),
        );
      }

      return Right(
        Account(
          id: user.id,
          role: UserRole.fromDb(existing['role'] as String?),
          phone: existing['phone_number'] as String? ?? phoneE164,
          email: existing['email'] as String? ?? email,
          fullName: existing['full_name'] as String?,
          isPhoneVerified: existing['is_phone_verified'] as bool? ?? false,
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
          .select('id, role, full_name, phone_number, email, is_phone_verified')
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return const Right(null);
      return Right(
        Account(
          id: user.id,
          role: UserRole.fromDb(row['role'] as String?),
          phone: row['phone_number'] as String? ?? '',
          email: row['email'] as String?,
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
      // Cause la plus probable en pratique : le SMTP par defaut de Supabase
      // est plafonne a quelques envois par heure. Brancher un SMTP dedie
      // (Brevo, Resend) avant les premiers vrais utilisateurs.
      return const ValidationFailure(
        'Trop de demandes de code. Patiente quelques minutes.',
      );
    }
    return ServerFailure(debug: e.message);
  }
}

abstract final class EmailCheck {
  static final _re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Validation volontairement permissive : rejeter une adresse valide est
  /// pire que d'en accepter une fausse, que le code invalidera de toute facon.
  static bool isValid(String v) => _re.hasMatch(v.trim());
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
