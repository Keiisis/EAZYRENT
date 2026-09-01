import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../search/presentation/controllers/map_controller.dart';

/// Relevé de la position exacte d'un bien, par un bailleur, un démarcheur ou
/// un agent.
///
/// C'EST L'ÉCRAN QUI DÉCIDE SI « VISITE VÉRIFIÉE » VEUT DIRE QUELQUE CHOSE.
/// Un point posé au doigt depuis un bureau et un relevé GPS pris devant le
/// portail portent la même paire de coordonnées et n'ont pas la même valeur.
/// D'où trois règles tenues ici :
///
///   1. LA PRÉCISION EST AFFICHÉE EN MÈTRES, en continu. À ±150 m, on envoie
///      quelqu'un dans la rue d'à côté ; il faut qu'il le sache avant
///      d'enregistrer, pas après.
///   2. UN RELEVÉ TROP IMPRÉCIS EST REFUSÉ. Le bouton reste inactif au-delà
///      du seuil, avec la raison écrite. Accepter un mauvais point pour ne
///      pas frustrer le bailleur revient à casser le produit pour tout le
///      monde.
///   3. LA PROVENANCE EST ENREGISTRÉE (`location_source`). GPS sur place,
///      épingle déplacée à la main, ou adresse géocodée — les trois sont
///      permis, mais on ne les confondra jamais.
///
/// LA PHOTO DU PORTAIL n'est pas une photo de plus. C'est ce qui permet de
/// reconnaître l'entrée en arrivant, dans un quartier où les rues n'ont
/// souvent ni nom ni numéro. Elle est prise à la CAMÉRA, jamais choisie dans
/// la galerie : une photo de galerie peut venir de n'importe où et de
/// n'importe quand.
class CaptureLocationScreen extends StatefulWidget {
  const CaptureLocationScreen({this.initial, super.key});

  final LatLng? initial;

  @override
  State<CaptureLocationScreen> createState() => _CaptureLocationScreenState();
}

enum LocationSource { gpsOnsite, manualPin, geocoded }

class CapturedLocation {
  const CapturedLocation({
    required this.point,
    required this.accuracyMeters,
    required this.source,
    required this.placeLabel,
    this.gatePhoto,
  });

  final LatLng point;
  final double? accuracyMeters;
  final LocationSource source;
  final String? placeLabel;
  final File? gatePhoto;
}

class _CaptureLocationScreenState extends State<CaptureLocationScreen> {
  /// Au-delà, on refuse. 40 m, c'est déjà la largeur d'un pâté de maisons à
  /// Fidjrossè — c'est le maximum tolérable pour retrouver un portail.
  static const _maxAccuracy = 40.0;

  /// En dessous, le relevé est bon et on le dit. Entre les deux, il passe
  /// mais l'écran invite à attendre quelques secondes de plus.
  static const _goodAccuracy = 15.0;

  final _map = MapController();
  final _picker = ImagePicker();

  LatLng? _point;
  double? _accuracy;
  LocationSource _source = LocationSource.gpsOnsite;
  String? _place;
  File? _gatePhoto;
  bool _locating = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _point = widget.initial;
    if (widget.initial != null) _source = LocationSource.manualPin;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fix());
  }

  bool get _canSave =>
      _point != null &&
      (_source != LocationSource.gpsOnsite ||
          (_accuracy != null && _accuracy! <= _maxAccuracy));

  /// Relevé GPS. On prend la MEILLEURE des mesures reçues pendant quelques
  /// secondes plutôt que la première : la première position d'un GPS froid
  /// est presque toujours la pire, et c'est celle que la plupart des
  /// applications enregistrent.
  Future<void> _fix() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _message = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _message = 'Active la localisation du téléphone.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(
          () => _message =
              'Sans la position, tu peux placer l\'épingle à la main — '
              'le bien sera marqué comme non relevé sur place.',
        );
        return;
      }

      Position? best;
      final stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );
      final sub = stream.listen((p) {
        if (best == null || p.accuracy < best!.accuracy) best = p;
      });
      await Future<void>.delayed(const Duration(seconds: 6));
      await sub.cancel();

      if (best == null) {
        setState(() => _message = 'Position introuvable. Sors à découvert.');
        return;
      }

      final pos = best!;
      setState(() {
        _point = LatLng(pos.latitude, pos.longitude);
        _accuracy = pos.accuracy;
        _source = LocationSource.gpsOnsite;
      });
      _map.move(_point!, 18);
      await _resolvePlace();
    } catch (e) {
      setState(() => _message = 'Relevé impossible pour l\'instant.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _resolvePlace() async {
    final p = _point;
    if (p == null) return;
    try {
      final places = await Geocoding(
        locale: const Locale('fr', 'BJ'),
      ).placemarkFromCoordinates(p.latitude, p.longitude);
      if (places.isEmpty) return;
      final pl = places.first;
      final parts = <String?>[pl.subLocality, pl.locality];
      final name = parts
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(', ');
      if (mounted && name.isNotEmpty) setState(() => _place = name);
    } catch (_) {
      // Le géocodage inverse échoue souvent hors couverture. Le relevé reste
      // valable sans nom : ce sont les coordonnées qui comptent.
    }
  }

  Future<void> _shootGate() async {
    final shot = await _picker.pickImage(
      // CAMÉRA uniquement. Une photo de galerie peut venir de n'importe où.
      source: ImageSource.camera,
      // 1600 px suffit à reconnaître un portail et divise par cinq le poids
      // d'un envoi sur une connexion à 2 barres.
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (shot != null && mounted) setState(() => _gatePhoto = File(shot.path));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final acc = _accuracy;
    final tone = acc == null
        ? p.inkMuted
        : acc <= _goodAccuracy
        ? p.success
        : acc <= _maxAccuracy
        ? p.warn
        : p.danger;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Position du bien',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _point ?? MapCtrl.fallbackCenter,
                    initialZoom: _point == null ? 13 : 18,
                    // Déplacer l'épingle à la main est PERMIS — un bailleur
                    // connaît son portail mieux qu'un GPS sous les tôles.
                    // Mais la provenance bascule, et elle sera affichée.
                    onTap: (_, latlng) => setState(() {
                      _point = latlng;
                      _accuracy = null;
                      _source = LocationSource.manualPin;
                    }),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapCtrl.tileUrl,
                      fallbackUrl: MapCtrl.fallbackTileUrl,
                      userAgentPackageName: 'bj.eazyrent.eazyrent',
                    ),
                    if (_point != null) ...[
                      if (acc != null)
                        CircleLayer(
                          circles: [
                            // Le cercle de précision, à l'échelle réelle.
                            // Voir la zone plutôt qu'un nombre est ce qui
                            // fait comprendre « ±40 m ».
                            CircleMarker(
                              point: _point!,
                              radius: acc,
                              useRadiusInMeter: true,
                              color: tone.withValues(alpha: 0.15),
                              borderColor: tone.withValues(alpha: 0.5),
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _point!,
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.location_on,
                              size: 44,
                              color: p.actionFill,
                            ),
                          ),
                        ],
                      ),
                    ],
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(MapCtrl.attribution),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  left: Space.md,
                  right: Space.md,
                  top: Space.xs,
                  child: _AccuracyBanner(
                    accuracy: acc,
                    source: _source,
                    place: _place,
                    tone: tone,
                    maxAccuracy: _maxAccuracy,
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              boxShadow: Elevation.stickyBar,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_message != null) ...[
                      Text(
                        _message!,
                        style: AppText.bodyM.copyWith(color: p.inkMuted),
                      ),
                      const SizedBox(height: Space.xs),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _locating ? null : _fix,
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(
                                0,
                                Touch.target(p.isHighContrast),
                              ),
                            ),
                            icon: _locating
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: p.action,
                                    ),
                                  )
                                : const Icon(Icons.gps_fixed, size: 18),
                            label: Text(_locating ? 'Relevé…' : 'Relever ici'),
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shootGate,
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(
                                0,
                                Touch.target(p.isHighContrast),
                              ),
                              foregroundColor: _gatePhoto == null
                                  ? null
                                  : p.success,
                            ),
                            icon: Icon(
                              _gatePhoto == null
                                  ? Icons.photo_camera_outlined
                                  : Icons.check_circle,
                              size: 18,
                            ),
                            label: Text(
                              _gatePhoto == null
                                  ? 'Photo du portail'
                                  : 'Portail',
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_gatePhoto != null) ...[
                      const SizedBox(height: Space.sm),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radii.card),
                        child: Image.file(
                          _gatePhoto!,
                          height: 96,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: Space.xxs),
                      Text(
                        'Cette photo sert à reconnaître l\'entrée en arrivant. '
                        'Ici, beaucoup de rues n\'ont ni nom ni numéro.',
                        style: AppText.caption.copyWith(color: p.inkMuted),
                      ),
                    ],

                    const SizedBox(height: Space.sm),
                    FilledButton(
                      onPressed: _canSave
                          ? () => Navigator.of(context).pop(
                              CapturedLocation(
                                point: _point!,
                                accuracyMeters: _accuracy,
                                source: _source,
                                placeLabel: _place,
                                gatePhoto: _gatePhoto,
                              ),
                            )
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(
                          0,
                          Touch.target(p.isHighContrast) + 8,
                        ),
                      ),
                      child: Text(
                        _canSave
                            ? 'Enregistrer cette position'
                            : acc == null
                            ? 'Relève ou place l\'épingle'
                            : 'Trop imprécis — attends quelques secondes',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La précision, en continu, en clair, avec sa couleur. Le nombre seul ne dit
/// rien à personne ; le nombre avec « bon / passable / trop flou » se lit d'un
/// coup d'œil, y compris en plein soleil.
class _AccuracyBanner extends StatelessWidget {
  const _AccuracyBanner({
    required this.accuracy,
    required this.source,
    required this.place,
    required this.tone,
    required this.maxAccuracy,
  });

  final double? accuracy;
  final LocationSource source;
  final String? place;
  final Color tone;
  final double maxAccuracy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (title, body) = switch (source) {
      LocationSource.manualPin => (
        'Épingle placée à la main',
        'Le bien sera marqué comme non relevé sur place. Touche « Relever '
            'ici » si tu es devant le portail.',
      ),
      LocationSource.geocoded => (
        'Position déduite de l\'adresse',
        'Moins fiable qu\'un relevé sur place.',
      ),
      LocationSource.gpsOnsite =>
        accuracy == null
            ? ('Recherche du signal…', 'Reste immobile quelques secondes.')
            : (
                'Relevé sur place · ± ${accuracy!.round()} m',
                accuracy! <= maxAccuracy
                    ? (place ?? 'Position utilisable.')
                    : 'Trop flou pour retrouver un portail. Sors à découvert '
                          'et attends.',
              ),
    };

    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: const BorderRadius.all(Radii.card),
        boxShadow: Elevation.mapPin,
      ),
      child: Row(
        children: [
          Icon(
            source == LocationSource.gpsOnsite
                ? Icons.gps_fixed
                : Icons.push_pin_outlined,
            color: tone,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(body, style: AppText.bodyM.copyWith(color: p.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
