import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/travel_mode.dart';
import '../../data/valhalla_routing_service.dart';
import '../../domain/entities/route_plan.dart';

/// Le guidage jusqu'au bien.
///
/// Trois choses gouvernent ce contrôleur, dans cet ordre :
///
///   1. LA BATTERIE. Un flux GPS ouvert et oublié vide un téléphone en une
///      heure — sur un appareil qu'on ne recharge pas toujours le soir, c'est
///      une désinstallation. Le flux se ferme à la sortie de l'écran, et se
///      coupe TOUT SEUL à l'arrivée.
///   2. LES DONNÉES. On ne recalcule pas l'itinéraire à chaque point GPS :
///      seulement quand l'utilisateur s'est réellement écarté du tracé.
///   3. LA VÉRITÉ. Les quatre durées viennent du moteur, pas d'une distance
///      divisée par une vitesse. Et la limite du moteur est dite à l'écran.
class NavigationCtrl extends GetxController {
  NavigationCtrl({
    required this.destination,
    required this.destinationLabel,
    ValhallaRoutingService? service,
  }) : _service = service ?? ValhallaRoutingService();

  final LatLng destination;
  final String destinationLabel;
  final ValhallaRoutingService _service;

  /// Au-delà, on considère que l'utilisateur a quitté le tracé et on
  /// recalcule. En dessous, l'écart relève de la dérive du GPS, pas d'un
  /// changement de chemin : recalculer à 20 m ferait recalculer en permanence
  /// sous les tôles et entre les immeubles.
  static const offRouteMeters = 60.0;

  /// À cette distance, on ne guide plus : on annonce l'arrivée. Continuer à
  /// dire « tournez à droite » devant le portail est ridicule, et consomme.
  static const arrivalMeters = 35.0;

  static const _distance = Distance();

  final mode = TravelMode.zem.obs;
  final plan = Rxn<RoutePlan>();
  final me = Rxn<LatLng>();
  final accuracyMeters = RxnDouble();
  final computing = false.obs;
  final arrived = false.obs;
  final error = RxnString();
  final following = true.obs;

  /// Les quatre durées, calculées une fois, pour comparer sans attendre.
  final alternatives = <TravelMode, RoutePlan>{}.obs;

  StreamSubscription<Position>? _sub;

  @override
  void onClose() {
    // G43 — le flux se ferme sur TOUS les chemins de sortie, y compris quand
    // l'utilisateur revient en arrière sans arriver.
    _sub?.cancel();
    _sub = null;
    super.onClose();
  }

  /// Distance à vol d'oiseau jusqu'à la destination. Sert UNIQUEMENT à
  /// détecter l'arrivée — jamais à afficher un temps de trajet.
  double get metersToDestination =>
      me.value == null ? double.infinity : _distance(me.value!, destination);

  Future<void> start() async {
    final ok = await _ensurePermission();
    if (!ok) {
      error.value =
          'Sans ta position, on ne peut pas te guider. Tu peux quand même '
          'voir le chemin depuis le quartier du bien.';
      return;
    }

    await _sub?.cancel();
    _sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            // Un point tous les 10 mètres : assez pour suivre un zem, dix
            // fois moins gourmand qu'un flux continu.
            distanceFilter: 10,
          ),
        ).listen(
          _onPosition,
          onError: (_) {
            error.value = 'Position perdue. Sors à découvert si tu peux.';
          },
        );

    final first = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    _onPosition(first);
    await computeAll();
  }

  void _onPosition(Position p) {
    me.value = LatLng(p.latitude, p.longitude);
    accuracyMeters.value = p.accuracy;

    if (metersToDestination <= arrivalMeters) {
      arrived.value = true;
      // On coupe le GPS soi-même. Attendre que l'utilisateur ferme l'écran
      // reviendrait à lui facturer la batterie de son oubli.
      _sub?.cancel();
      _sub = null;
      return;
    }

    final current = plan.value;
    if (current == null || computing.value) return;
    if (_deviationFrom(current.geometry) > offRouteMeters) {
      unawaited(compute(mode.value));
    }
  }

  /// Écart minimal entre la position et le tracé. On compare aux POINTS de la
  /// géométrie plutôt qu'aux segments : c'est légèrement pessimiste, donc au
  /// pire on recalcule un peu tôt — jamais trop tard.
  double _deviationFrom(List<LatLng> geometry) {
    final here = me.value;
    if (here == null || geometry.isEmpty) return 0;
    var best = double.infinity;
    for (final p in geometry) {
      final d = _distance(here, p);
      if (d < best) best = d;
    }
    return best;
  }

  Future<void> setMode(TravelMode m) async {
    mode.value = m;
    final known = alternatives[m];
    if (known != null) {
      plan.value = known;
      return;
    }
    await compute(m);
  }

  Future<void> compute(TravelMode m) async {
    final here = me.value;
    if (here == null) return;
    computing.value = true;
    error.value = null;

    final result = await _service.route(from: here, to: destination, mode: m);
    result.match((f) => error.value = f.userMessage, (r) {
      alternatives[m] = r;
      if (m == mode.value) plan.value = r;
    });
    computing.value = false;
  }

  /// Les quatre modes d'un coup, pour que la comparaison soit instantanée.
  ///
  /// Le mode courant part EN PREMIER et seul : l'utilisateur voit son
  /// itinéraire tout de suite, les trois autres arrivent derrière. Lancer les
  /// quatre en parallèle sur une connexion faible ferait attendre le principal
  /// derrière trois requêtes dont on n'a pas besoin dans la seconde.
  Future<void> computeAll() async {
    await compute(mode.value);
    for (final m in TravelMode.values) {
      if (m != mode.value) await compute(m);
    }
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }
}
