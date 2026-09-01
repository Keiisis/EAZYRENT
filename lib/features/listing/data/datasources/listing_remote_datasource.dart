import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/listing.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/repositories/listing_repository.dart';

/// Seul endroit de la feature qui parle à Supabase.
///
/// ⛔ Ne sélectionne JAMAIS `virtual_tour_scenes` ni `panorama_url`.
/// L'existence d'un tour se déduit d'un booléen agrégé ; les panoramas ne
/// s'obtiennent que par l'Edge Function `get-tour-access` (CONSTITUTION P4).
class ListingRemoteDataSource {
  const ListingRemoteDataSource(this._db);

  final SupabaseClient _db;

  static const _columns =
      'id, price_amount, property_type, neighborhood, city, '
      'advance_months, total_move_in_cost, main_image_url, is_available, '
      'is_featured, virtual_tour_360_url, latitude, longitude';

  Future<List<Listing>> fetchFeed(
    SearchQuery q, {
    required int limit,
    required int offset,
  }) async {
    var req = _db.from('listings').select(_columns).eq('is_available', true);

    if (q.neighborhoods.isNotEmpty) {
      req = req.inFilter('neighborhood', q.neighborhoods);
    }
    // Le filtre part en CODE de base, jamais en libellé français : la colonne
    // contient `apartment`, pas « Chambre-salon ».
    final typeCode = PropertyTypes.codeOf(q.propertyType);
    if (typeCode != null) req = req.eq('property_type', typeCode);
    if (q.minRentFcfa != null) req = req.gte('price_amount', q.minRentFcfa!);
    if (q.maxRentFcfa != null) req = req.lte('price_amount', q.maxRentFcfa!);
    if (q.maxMoveInCostFcfa != null) {
      req = req.lte('total_move_in_cost', q.maxMoveInCostFcfa!);
    }
    if (q.verifiedTourOnly) req = req.not('virtual_tour_360_url', 'is', null);

    // Fraîcheur de publication d'abord : les bons biens partent en 48 h.
    final rows = await req
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (rows.isEmpty) return const [];

    final checks = await _lastChecks(
      rows.map((r) => r['id'] as String).toList(),
    );

    return rows.map((r) => _toEntity(r, checks[r['id'] as String])).toList();
  }

  /// Dernière re-confirmation par bien. C'est ce qui matérialise la promesse
  /// du produit ; sans elle on vendrait la visite d'un bien peut-être parti.
  Future<Map<String, DateTime>> _lastChecks(List<String> ids) async {
    final rows = await _db
        .from('availability_checks')
        .select('listing_id, checked_at, is_still_available')
        .inFilter('listing_id', ids)
        .eq('is_still_available', true)
        .order('checked_at', ascending: false);

    final out = <String, DateTime>{};
    for (final r in rows) {
      final id = r['listing_id'] as String;
      out.putIfAbsent(id, () => DateTime.parse(r['checked_at'] as String));
    }
    return out;
  }

  Future<Listing> fetchById(String id) async {
    final row = await _db
        .from('listings')
        .select(_columns)
        .eq('id', id)
        .single();
    final checks = await _lastChecks([id]);
    return _toEntity(row, checks[id]);
  }

  Listing _toEntity(Map<String, dynamic> r, DateTime? checkedAt) {
    int? asInt(Object? v) => v == null ? null : (v as num).round();
    return Listing(
      id: r['id'] as String,
      monthlyRentFcfa: asInt(r['price_amount']) ?? 0,
      propertyType: PropertyTypes.labelOf(r['property_type'] as String?),
      neighborhood: r['neighborhood'] as String?,
      city: r['city'] as String? ?? 'Cotonou',
      advanceMonths: asInt(r['advance_months']),
      totalMoveInCostFcfa: asInt(r['total_move_in_cost']),
      mainImageUrl: r['main_image_url'] as String?,
      hasVerifiedTour: r['virtual_tour_360_url'] != null,
      isAvailable: r['is_available'] as bool? ?? true,
      isSponsored: r['is_featured'] as bool? ?? false,
      latitude: (r['latitude'] as num?)?.toDouble(),
      longitude: (r['longitude'] as num?)?.toDouble(),
      freshness: Freshness.from(checkedAt),
    );
  }
}
