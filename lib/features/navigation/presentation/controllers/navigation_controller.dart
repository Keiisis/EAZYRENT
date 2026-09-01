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

  /// Deux temps distincts, et ils ne se ressemblent pas.
  ///
  /// APERÇU : on compare les modes, on ne bouge pas encore. Le GPS tourne
  /// juste assez pour savoir d'où partir.
  /// EN ROUTE : on suit. La distance affichée devient CE QUI RESTE, et elle
  /// décroît à chaque pas.
  ///
  /// Sans cette séparation, l'écran montrait la longueur TOTALE du trajet,
  /// figée : quelqu'un qui marchait voyait le même « 3,2 km » au départ et à
  /// l'arrivée, et en concluait — à raison — que rien ne le suivait.
  final started = false.obs;

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

  /// Mètres restants le long du TRACÉ, pas à vol d'oiseau. Sur un trajet
  /// urbain les deux diffèrent d'un facteur deux : annoncer « 400 m » à
  /// quelqu'un qui en a 900 à parcourir le fait tourner au mauvais endroit.
  final remainingMeters = RxnDouble();

  /// Reste à parcourir, converti en temps avec la vitesse MOYENNE du trajet
  /// calculé — pas une vitesse théorique par mode. Si Valhalla estime 3,2 km
  /// en 8 min, on garde ce rapport-là pour le reste.
  Duration? get remainingDuration {
    final r = remainingMeters.value;
    final p = plan.value;
    if (r == null || p == null || p.distanceMeters == 0) return null;
    final ratio = r / p.distanceMeters;
    return Duration(seconds: (p.duration.inSeconds * ratio).round());
  }

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

    final current = plan.value;
    if (current != null) {
      remainingMeters.value = _remainingAlong(current.geometry);
    }

    if (metersToDestination <= arrivalMeters) {
      arrived.value = true;
      // On coupe le GPS soi-même. Attendre que l'utilisateur ferme l'écran
      // reviendrait à lui facturer la batterie de son oubli.
      _sub?.cancel();
      _sub = null;
      return;
    }

    if (current == null || computing.value) return;
    // Hors du trajet, on ne recalcule QUE si le guidage a démarré : recalculer
    // pendant qu'on compare les modes ferait sauter les quatre durées à chaque
    // dérive du GPS.
    if (started.value && _deviationFrom(current.geometry) > offRouteMeters) {
      unawaited(compute(mode.value));
    }
  }

  /// Longueur du tracé restant à partir du point le plus proche de soi.
  ///
  /// On projette la position sur le point de géométrie le plus proche, puis
  /// on somme les segments jusqu'au bout. C'est ce que « il te reste 1,4 km »
  /// veut dire — et c'est ce qui doit décroître à l'écran.
  double _remainingAlong(List<LatLng> geometry) {
    final here = me.value;
    if (here == null || geometry.length < 2) return 0;

    var nearest = 0;
    var best = double.infinity;
    for (var i = 0; i < geometry.length; i++) {
      final d = _distance(here, geometry[i]);
      if (d < best) {
        best = d;
        nearest = i;
      }
    }

    var total = _distance(here, geometry[nearest]);
    for (var i = nearest; i < geometry.length - 1; i++) {
      total += _distance(geometry[i], geometry[i + 1]);
    }
    return total;
  }

  /// Le geste explicite. Rien ne suit personne avant qu'il ait été fait.
  void startGuiding() {
    started.value = true;
    following.value = true;
    final current = plan.value;
    if (current != null) {
      remainingMeters.value = _remainingAlong(current.geometry);
    }
  }

  void stopGuiding() {
    started.value = false;
    remainingMeters.value = null;
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
