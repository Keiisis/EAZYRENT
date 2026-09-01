import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../domain/entities/tour_scene.dart';

/// Le seul chemin d'accès aux panoramas.
///
/// CONSTITUTION P4 — LE PAYWALL N'EST JAMAIS ARBITRÉ CÔTÉ CLIENT.
///
/// Ce dépôt n'expose aucune méthode qui lise `virtual_tour_scenes`. Il appelle
/// une Edge Function, qui vérifie côté serveur que l'appelant a payé, et rend
/// des URL SIGNÉES à durée de vie courte. La différence n'est pas théorique :
///
///   · avec une URL permanente, il suffit d'un client HTTP et de l'identifiant
///     du bien pour aspirer tous les panoramas sans payer un franc ;
///   · avec une URL signée de 60 minutes, l'aspirateur doit d'abord passer
///     par le paiement, et ce qu'il obtient périme.
///
/// La RLS sur `virtual_tour_scenes` reste la deuxième serrure : même si ce
/// fichier était réécrit demain pour requêter la table directement, il ne
/// recevrait rien.
abstract interface class TourRepository {
  Future<Either<Failure, TourAccess>> openTour(String listingId);
}

class SupabaseTourRepository implements TourRepository {
  const SupabaseTourRepository(this._db);

  final SupabaseClient _db;

  /// Nom de la fonction déployée. Déclaré ici et nulle part ailleurs : c'est
  /// le seul point de contact avec le serveur pour tout le module.
  static const _function = 'get-tour-access';

  @override
  Future<Either<Failure, TourAccess>> openTour(String listingId) async {
    try {
      final res = await _db.functions.invoke(
        _function,
        body: {'listing_id': listingId},
      );

      // 402 — payé nulle part. C'est un refus MÉTIER, pas une panne : il
      // mérite un message qui dit quoi faire, et surtout pas « erreur ».
      if (res.status == 402) return const Left(TourNotPaidFailure());
      if (res.status == 404) return const Left(ListingGoneFailure());
      if (res.status != 200) {
        return Left(ServerFailure(debug: 'get-tour-access ${res.status}'));
      }

      final data = res.data as Map<String, dynamic>;
      final scenes = (data['scenes'] as List)
          .cast<Map<String, dynamic>>()
          .map(_toScene)
          .toList();

      if (scenes.isEmpty) return const Left(TourEmptyFailure());

      return Right(
        TourAccess(
          listingId: listingId,
          scenes: scenes,
          expiresAt: DateTime.parse(data['expires_at'] as String),
          capturedAt: DateTime.parse(data['captured_at'] as String),
          agentName: data['agent_name'] as String?,
        ),
      );
    } on FunctionException catch (e) {
      // L'Edge Function n'est pas déployée, ou elle a levé. On le DIT au lieu
      // d'afficher une visite vide : une visite payée qui ne s'ouvre pas est
      // le pire incident possible pour ce produit.
      return Left(ServerFailure(debug: 'edge: ${e.reasonPhrase}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  TourScene _toScene(Map<String, dynamic> r) => TourScene(
    id: r['id'] as String,
    name: r['scene_name'] as String? ?? 'Pièce',
    panoramaUrl: r['signed_url'] as String,
    initialYaw: ((r['initial_yaw'] as num?) ?? 0).toDouble(),
    initialPitch: ((r['initial_pitch'] as num?) ?? 0).toDouble(),
    hotspots: [
      for (final h in (r['hotspots'] as List? ?? const []))
        if (h is Map<String, dynamic>)
          TourHotspot(
            targetSceneId: h['target_scene_id'] as String,
            label: h['label'] as String? ?? 'Pièce suivante',
            longitude: ((h['longitude'] as num?) ?? 0).toDouble(),
            latitude: ((h['latitude'] as num?) ?? 0).toDouble(),
          ),
    ],
  );
}
