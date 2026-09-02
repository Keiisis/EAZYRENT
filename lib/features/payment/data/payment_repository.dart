import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../domain/entities/payment.dart';

/// Le paiement, côté client — c'est-à-dire presque rien, et c'est voulu.
///
/// TOUT CE FICHIER TIENT DANS DEUX APPELS : « crée » et « vérifie ». Il ne
/// connaît aucune clé, ne construit aucune URL de fournisseur, ne calcule
/// aucun montant, et ne décide jamais qu'un paiement a réussi.
///
/// Les six leçons tirées de RETOUR GAGNANT TEMPLATE, et où elles vivent :
///
///   1. La transaction est créée CÔTÉ SERVEUR avant d'ouvrir quoi que ce
///      soit → `create-payment`. Ici on ne fait que la demander.
///   2. La vérification IGNORE ce que dit le client → `verify-payment` relit
///      le fournisseur et la base. On ne lui envoie qu'une référence.
///   3. Les clés secrètes sont lues en base, côté serveur → aucune n'apparaît
///      dans ce fichier ni dans `AppConfig` (CONSTITUTION P11).
///   4. XOF est zero-decimal → la conversion est faite par le serveur, une
///      seule fois, au même endroit pour les quatre fournisseurs.
///   5. FedaPay attend un payload plat → détail d'implémentation serveur, que
///      le client n'a pas à connaître.
///   6. Le widget ne doit pas démonter l'arbre → on n'utilise AUCUN SDK de
///      fournisseur : une page hébergée, ouverte dans une vue web par-dessus
///      l'application.
abstract interface class PaymentRepository {
  /// Demande au serveur de créer une transaction. Rend l'URL à ouvrir.
  Future<Either<Failure, PaymentIntent>> create({
    required PaymentProvider provider,
    required int amountFcfa,
    required int credits,
    String? listingId,
  });

  /// Demande au serveur si le paiement a abouti. Appelable en boucle : c'est
  /// le seul moyen fiable quand le retour du fournisseur se perd.
  Future<Either<Failure, PaymentResult>> verify(String reference);
}

class SupabasePaymentRepository implements PaymentRepository {
  const SupabasePaymentRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<Either<Failure, PaymentIntent>> create({
    required PaymentProvider provider,
    required int amountFcfa,
    required int credits,
    String? listingId,
  }) async {
    if (_db.auth.currentUser == null) {
      return const Left(NotAuthenticatedFailure());
    }
    // Un montant nul ou négatif ne part JAMAIS au serveur : c'est un défaut
    // d'appel, et le laisser passer produirait une transaction fantôme dans
    // la comptabilité.
    if (amountFcfa <= 0 || credits <= 0) {
      return const Left(
        ValidationFailure('Montant invalide.', debug: 'amount<=0'),
      );
    }

    try {
      final res = await _db.functions.invoke(
        'create-payment',
        body: {
          'provider': provider.name,
          // On envoie le montant en FRANCS, entier. Aucune multiplication
          // côté client : c'est le serveur qui sait ce que chaque fournisseur
          // attend (leçon 4).
          'amount_fcfa': amountFcfa,
          'credits': credits,
          // Élément null-aware : la clé disparaît si la valeur est nulle.
          // Un `listing_id: null` envoyé au serveur voudrait dire « aucun
          // bien », ce qui n'est pas la même chose que « je n'en parle pas ».
          'listing_id': ?listingId,
        },
      );

      if (res.status != 200) {
        return Left(ServerFailure(debug: 'create-payment ${res.status}'));
      }

      final data = res.data as Map<String, dynamic>;
      return Right(
        PaymentIntent(
          reference: data['reference'] as String,
          provider: provider,
          amountFcfa: amountFcfa,
          checkoutUrl: data['checkout_url'] as String,
        ),
      );
    } on FunctionException catch (e) {
      return Left(ServerFailure(debug: 'edge create: ${e.reasonPhrase}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> verify(String reference) async {
    try {
      // On n'envoie QUE la référence. Ni le montant, ni le fournisseur, ni
      // un quelconque « status: paid » : tout ce que le client affirmerait
      // ici serait une faille (leçon 2).
      final res = await _db.functions.invoke(
        'verify-payment',
        body: {'reference': reference},
      );

      if (res.status != 200) {
        return Left(ServerFailure(debug: 'verify-payment ${res.status}'));
      }

      final data = res.data as Map<String, dynamic>;
      return Right(
        PaymentResult(
          reference: reference,
          status: switch (data['status'] as String?) {
            'paid' => PaymentStatus.paid,
            'failed' => PaymentStatus.failed,
            'cancelled' => PaymentStatus.cancelled,
            _ => PaymentStatus.pending,
          },
          amountFcfa: (data['amount_fcfa'] as num?)?.toInt() ?? 0,
          creditsAdded: (data['credits_added'] as num?)?.toInt() ?? 0,
          message: data['message'] as String?,
        ),
      );
    } on FunctionException catch (e) {
      return Left(ServerFailure(debug: 'edge verify: ${e.reasonPhrase}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }
}
