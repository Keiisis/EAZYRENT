import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../listing/domain/entities/property_type.dart';

/// Un bien vu par SON PROPRIÉTAIRE — pas par un chercheur.
///
/// Les champs diffèrent parce que les questions diffèrent. Un chercheur
/// demande « est-ce que ça me va ? » ; un bailleur demande « est-ce que ça
/// marche ? ». D'où les vues, les demandes et l'état de publication à la
/// place de la fraîcheur et du coût d'entrée.
class OwnerListing extends Equatable {
  const OwnerListing({
    required this.id,
    required this.title,
    required this.neighborhood,
    required this.rentFcfa,
    required this.isAvailable,
    required this.hasTour,
    required this.views,
    required this.pendingRequests,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String neighborhood;
  final int rentFcfa;
  final bool isAvailable;
  final bool hasTour;

  /// Vues sur 7 jours. C'est ce chiffre qui rend l'offre de tournage
  /// évidente — ou qui dit qu'il est trop tôt pour la faire.
  final int views;

  final int pendingRequests;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, isAvailable, views, pendingRequests];
}

class VisitRequest extends Equatable {
  const VisitRequest({
    required this.id,
    required this.listingId,
    required this.listingLabel,
    required this.tenantName,
    required this.requestedAt,
    required this.status,
    this.tenantHasSeenTour = false,
  });

  final String id;
  final String listingId;
  final String listingLabel;
  final String tenantName;
  final DateTime requestedAt;
  final String status;

  /// « A visité en 360° » change tout pour le bailleur : c'est quelqu'un qui
  /// a déjà vu le logement et qui vient quand même. Le déplacement n'est plus
  /// une découverte, c'est une confirmation.
  final bool tenantHasSeenTour;

  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [id, status];
}

abstract interface class OwnerRepository {
  Future<Either<Failure, List<OwnerListing>>> myListings();
  Future<Either<Failure, List<VisitRequest>>> visitRequests();
  Future<Either<Failure, void>> setAvailability(String listingId, bool online);
  Future<Either<Failure, void>> answerRequest(String id, bool accept);
}

class SupabaseOwnerRepository implements OwnerRepository {
  const SupabaseOwnerRepository(this._db);

  final SupabaseClient _db;

  String? get _me => _db.auth.currentUser?.id;

  @override
  Future<Either<Failure, List<OwnerListing>>> myListings() async {
    final me = _me;
    if (me == null) return const Left(NotAuthenticatedFailure());

    try {
      final rows = await _db
          .from('listings')
          .select(
            'id, property_type, neighborhood, city, price_amount, '
            'is_available, virtual_tour_360_url, main_image_url, view_count',
          )
          .eq('owner_id', me)
          .order('created_at', ascending: false);

      // Les demandes en attente, en UNE requête pour tous les biens plutôt
      // qu'une par bien : un bailleur avec dix annonces ferait dix
      // aller-retours sur une connexion à deux barres.
      final pending = await _pendingByListing(me);

      return Right([
        for (final r in rows)
          OwnerListing(
            id: r['id'] as String,
            title: PropertyTypes.labelOf(r['property_type'] as String?),
            neighborhood:
                r['neighborhood'] as String? ?? r['city'] as String? ?? '',
            rentFcfa: (r['price_amount'] as num?)?.round() ?? 0,
            isAvailable: r['is_available'] as bool? ?? true,
            hasTour: r['virtual_tour_360_url'] != null,
            imageUrl: r['main_image_url'] as String?,
            // `view_count` peut ne pas exister encore : un compteur absent
            // vaut zéro, il ne fait pas disparaître l'annonce.
            views: (r['view_count'] as num?)?.toInt() ?? 0,
            pendingRequests: pending[r['id'] as String] ?? 0,
          ),
      ]);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  Future<Map<String, int>> _pendingByListing(String me) async {
    try {
      final rows = await _db
          .from('visit_bookings')
          .select('listing_id')
          .eq('owner_id', me)
          .eq('status', 'pending');
      final out = <String, int>{};
      for (final r in rows) {
        final id = r['listing_id'] as String;
        out[id] = (out[id] ?? 0) + 1;
      }
      return out;
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<Either<Failure, List<VisitRequest>>> visitRequests() async {
    final me = _me;
    if (me == null) return const Left(NotAuthenticatedFailure());

    try {
      final rows = await _db
          .from('visit_bookings')
          .select('''
            id, listing_id, requested_datetime, status,
            tenant:profiles!visit_bookings_tenant_id_fkey(id, full_name),
            listing:listings(property_type, neighborhood, city)
          ''')
          .eq('owner_id', me)
          .order('requested_datetime', ascending: true);

      // Qui a déjà vu la visite 360 ? Un seul aller-retour, pas un par
      // demande.
      final tenantIds = <String>{
        for (final r in rows)
          if (r['tenant'] != null) (r['tenant'] as Map)['id'] as String,
      };
      final seen = await _tenantsWithTour(tenantIds);

      return Right([
        for (final r in rows)
          VisitRequest(
            id: r['id'] as String,
            listingId: r['listing_id'] as String,
            listingLabel: _label(r['listing'] as Map<String, dynamic>?),
            tenantName:
                (r['tenant'] as Map?)?['full_name'] as String? ?? 'Candidat',
            requestedAt: DateTime.parse(r['requested_datetime'] as String),
            status: r['status'] as String? ?? 'pending',
            tenantHasSeenTour: seen.contains(
              (r['tenant'] as Map?)?['id'] as String? ?? '',
            ),
          ),
      ]);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  Future<Set<String>> _tenantsWithTour(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    try {
      final rows = await _db
          .from('virtual_tour_access_passes')
          .select('tenant_id')
          .inFilter('tenant_id', ids.toList());
      return {for (final r in rows) r['tenant_id'] as String};
    } catch (_) {
      return const {};
    }
  }

  String _label(Map<String, dynamic>? l) => l == null
      ? 'Bien'
      : '${PropertyTypes.labelOf(l['property_type'] as String?)} · '
            '${l['neighborhood'] ?? l['city']}';

  @override
  Future<Either<Failure, void>> setAvailability(
    String listingId,
    bool online,
  ) async {
    final me = _me;
    if (me == null) return const Left(NotAuthenticatedFailure());
    try {
      // `eq('owner_id')` en plus de la RLS : deux serrures valent mieux
      // qu'une quand il s'agit de retirer le bien de quelqu'un d'autre.
      await _db
          .from('listings')
          .update({'is_available': online})
          .eq('id', listingId)
          .eq('owner_id', me);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> answerRequest(String id, bool accept) async {
    final me = _me;
    if (me == null) return const Left(NotAuthenticatedFailure());
    try {
      await _db
          .from('visit_bookings')
          .update({'status': accept ? 'confirmed' : 'cancelled'})
          .eq('id', id)
          .eq('owner_id', me);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }
}
