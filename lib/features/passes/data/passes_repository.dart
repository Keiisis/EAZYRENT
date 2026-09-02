import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';

/// Le solde de crédits, tel que la BASE le connaît.
///
/// UN COMPTEUR FAUX EST PIRE QU'ABSENT : il fait croire à un vol. C'est la
/// seule raison pour laquelle ce dépôt existe — l'écran affichait un chiffre
/// de démonstration pendant que le serveur en débitait un vrai.
class CreditWallet extends Equatable {
  const CreditWallet({
    required this.remaining,
    required this.nextExpiry,
    required this.unlockedListings,
  });

  /// Somme des crédits NON EXPIRÉS. Un crédit périmé compté dans le solde
  /// est exactement le genre d'écart qui amène quelqu'un au support.
  final int remaining;

  /// La date d'expiration la plus proche. On la dit toujours, même quand
  /// elle est lointaine : un crédit qui expire sans prévenir détruit plus de
  /// confiance que le montant qu'il représente.
  final DateTime? nextExpiry;

  /// Visites déjà débloquées. Elles restent ouvertes, définitivement — c'est
  /// ce qui rend le retour arrière sans danger (§5.3).
  final int unlockedListings;

  @override
  List<Object?> get props => [remaining, nextExpiry, unlockedListings];
}

class PaymentRecord extends Equatable {
  const PaymentRecord({
    required this.reference,
    required this.amountFcfa,
    required this.credits,
    required this.provider,
    required this.status,
    required this.createdAt,
  });

  final String reference;
  final int amountFcfa;
  final int credits;
  final String provider;
  final String status;
  final DateTime createdAt;

  bool get isPaid => status == 'paid';

  /// Le nom que l'utilisateur reconnaît, pas notre identifiant technique.
  String get providerLabel => switch (provider) {
    'kkiapay' => 'Mobile Money',
    'fedapay' => 'Mobile Money',
    'stripe' => 'Carte bancaire',
    'revolut' => 'Revolut',
    _ => provider,
  };

  @override
  List<Object?> get props => [reference, status];
}

abstract interface class PassesRepository {
  Future<Either<Failure, CreditWallet>> wallet();
  Future<Either<Failure, List<PaymentRecord>>> history();
}

class SupabasePassesRepository implements PassesRepository {
  const SupabasePassesRepository(this._db);

  final SupabaseClient _db;

  String? get _me => _db.auth.currentUser?.id;

  @override
  Future<Either<Failure, CreditWallet>> wallet() async {
    final me = _me;
    // Un anonyme n'a pas de solde, et ce n'est pas une erreur : il n'a
    // simplement rien acheté. On rend zéro plutôt qu'un message d'échec.
    if (me == null) {
      return const Right(
        CreditWallet(remaining: 0, nextExpiry: null, unlockedListings: 0),
      );
    }

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      // On EXCLUT les crédits expirés du solde. Les compter donnerait un
      // chiffre flatteur et faux — et l'écart apparaîtrait au pire moment,
      // devant un bien qu'on veut ouvrir.
      final credits = await _db
          .from('visit_credits')
          .select('credits_remaining, expires_at')
          .eq('profile_id', me)
          .gt('credits_remaining', 0)
          .or('expires_at.is.null,expires_at.gt.$now');

      var total = 0;
      DateTime? soonest;
      for (final r in credits) {
        total += (r['credits_remaining'] as num).toInt();
        final exp = r['expires_at'] as String?;
        if (exp == null) continue;
        final d = DateTime.parse(exp);
        if (soonest == null || d.isBefore(soonest)) soonest = d;
      }

      final passes = await _db
          .from('virtual_tour_access_passes')
          .select('id')
          .eq('tenant_id', me)
          .isFilter('revoked_at', null);

      return Right(
        CreditWallet(
          remaining: total,
          nextExpiry: soonest,
          unlockedListings: passes.length,
        ),
      );
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentRecord>>> history() async {
    final me = _me;
    if (me == null) return const Right([]);

    try {
      // `payment_intents` porte AUSSI les tentatives échouées, et c'est
      // voulu : quelqu'un qui a vu un débit passer doit retrouver la ligne
      // et sa référence, même quand le paiement n'a pas abouti. Ne montrer
      // que les succès reviendrait à nier ce qu'il a vécu.
      final rows = await _db
          .from('payment_intents')
          .select(
            'reference, amount_fcfa, credits, provider, status, '
            'created_at',
          )
          .eq('user_id', me)
          .order('created_at', ascending: false)
          .limit(50);

      return Right([
        for (final r in rows)
          PaymentRecord(
            reference: r['reference'] as String,
            amountFcfa: (r['amount_fcfa'] as num).toInt(),
            credits: (r['credits'] as num).toInt(),
            provider: r['provider'] as String,
            status: r['status'] as String,
            createdAt: DateTime.parse(r['created_at'] as String),
          ),
      ]);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }
}
