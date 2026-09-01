import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/geo/travel_mode.dart';
import '../domain/entities/route_plan.dart';

/// Calcul d'itinéraire réel, par Valhalla.
///
/// POURQUOI VALHALLA ET PAS MAPBOX DIRECTIONS NI OSRM :
///   · Mapbox Directions n'a AUCUN profil moto. Sur un marché où le zémidjan
///     est le mode dominant, c'est le mode principal qui manque.
///   · Le serveur public OSRM ne déploie qu'un profil à la fois par instance :
///     il faudrait trois adresses différentes, et toujours pas de moto.
///   · Valhalla expose `pedestrian`, `bicycle`, `motorcycle` et `auto` sur UN
///     seul point d'entrée, rend les instructions en français, et ne demande
///     aucune clé.
///
/// ⚠️ L'instance `valhalla1.openstreetmap.de` est un service communautaire
/// FOSSGIS, en usage raisonnable. Elle convient pour construire et pour les
/// premiers utilisateurs ; à l'échelle, il faudra héberger notre propre
/// instance. C'est une dette d'exploitation nommée, pas un oubli.
class ValhallaRoutingService {
  ValhallaRoutingService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static final _endpoint = Uri.parse(
    'https://valhalla1.openstreetmap.de/route',
  );

  /// Au-delà, on n'attend plus : mieux vaut dire « impossible de calculer »
  /// que de laisser tourner un rond sur une connexion à 2 barres.
  static const _timeout = Duration(seconds: 15);

  Future<Either<Failure, RoutePlan>> route({
    required LatLng from,
    required LatLng to,
    required TravelMode mode,
  }) async {
    try {
      final res = await _client
          .post(
            _endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'locations': [
                {'lat': from.latitude, 'lon': from.longitude},
                {'lat': to.latitude, 'lon': to.longitude},
              ],
              'costing': mode.costing,
              'directions_options': {
                'units': 'kilometers',
                // Les instructions arrivent rédigées en français. On ne
                // traduit rien nous-mêmes : une phrase générée localement ne
                // nomme aucune rue, donc n'aide personne en circulation.
                'language': 'fr-FR',
              },
            }),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        return Left(ServerFailure(debug: 'valhalla ${res.statusCode}'));
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final trip = body['trip'] as Map<String, dynamic>?;
      if (trip == null) return const Left(ServerFailure(debug: 'trip absent'));

      final leg = (trip['legs'] as List).first as Map<String, dynamic>;
      final summary = trip['summary'] as Map<String, dynamic>;

      return Right(
        RoutePlan(
          mode: mode,
          distanceMeters: ((summary['length'] as num) * 1000).round(),
          duration: Duration(seconds: (summary['time'] as num).round()),
          geometry: decodePolyline6(leg['shape'] as String),
          steps: [
            for (final raw in (leg['maneuvers'] as List? ?? const []))
              if (raw is Map<String, dynamic>)
                RouteStep(
                  instruction: tidyInstruction(
                    raw['instruction'] as String? ?? '',
                  ),
                  distanceMeters: (((raw['length'] as num?) ?? 0) * 1000)
                      .round(),
                  shapeIndex: (raw['begin_shape_index'] as num?)?.toInt() ?? 0,
                ),
          ],
        ),
      );
    } on FormatException catch (e) {
      return Left(ServerFailure(debug: 'réponse illisible: $e'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  /// Valhalla rend « Rue 12.172/12.172 » quand le nom et la référence d'une
  /// voie sont identiques dans OpenStreetMap — ce qui est le cas de presque
  /// toutes les rues numérotées de Cotonou. Lu à voix haute en circulation,
  /// « Rue douze cent soixante-douze slash douze cent soixante-douze » est
  /// inutilisable. On replie le doublon.
  ///
  /// Publique parce que TESTABLE : une expression régulière à rétroréférence
  /// est exactement le genre de code qui se casse en silence.
  static String tidyInstruction(String instruction) => instruction
      .replaceAllMapped(
        // `(\S+)/` — un segment, une barre, LE MÊME segment. C'est la
        // rétroréférence qui distingue « Rue 12.172/12.172 », qu'on replie,
        // de « Rue Cotonou/Calavi », qui nomme un vrai carrefour et qu'on
        // garde intact.
        RegExp(r'(\S+)/\1(?=[\s.,]|$)'),
        (m) => m.group(1)!,
      )
      .trim();

  /// Valhalla encode ses géométries en polyline PRÉCISION 6, là où Google et
  /// OSRM utilisent la précision 5. Décoder avec le mauvais facteur ne produit
  /// pas une erreur : ça produit un tracé dix fois trop petit, posé au large
  /// du golfe de Guinée. Le genre de bug qui se voit à l'écran et jamais dans
  /// les tests, d'où le facteur explicite et le test qui le verrouille.
  static List<LatLng> decodePolyline6(String encoded) {
    const factor = 1e6;
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / factor, lng / factor));
    }
    return points;
  }
}
