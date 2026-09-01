import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/travel_mode.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../search/presentation/controllers/map_controller.dart';
import '../controllers/navigation_controller.dart';

/// Guidage jusqu'au bien, avec suivi en temps réel.
///
/// L'écran répond à trois questions, dans cet ordre, et à rien d'autre :
///   1. Combien de temps, et par quel moyen ?
///   2. Où suis-je par rapport au chemin ?
///   3. Qu'est-ce que je fais maintenant ?
///
/// LE ZEM EST LE PREMIER MODE, pas la voiture. C'est ce qu'on prend à Cotonou
/// pour aller visiter un logement.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({
    required this.destination,
    required this.destinationLabel,
    super.key,
  });

  final LatLng destination;
  final String destinationLabel;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  late final NavigationCtrl _nav;
  late final AnimatedMapController _map;

  @override
  void initState() {
    super.initState();
    _nav = Get.put(
      NavigationCtrl(
        destination: widget.destination,
        destinationLabel: widget.destinationLabel,
      ),
      tag: hashCode.toString(),
    );
    _map = AnimatedMapController(
      vsync: this,
      duration: Motion.slow,
      curve: Curves.easeOutCubic,
    );

    // La caméra suit la position TANT QUE l'utilisateur n'a pas déplacé la
    // carte lui-même. Reprendre la main de force à chaque point GPS est le
    // défaut le plus agaçant des applications de navigation.
    ever<LatLng?>(_nav.me, (p) {
      if (p != null && _nav.following.value) _map.animateTo(dest: p, zoom: 16);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _nav.start());
  }

  @override
  void dispose() {
    _map.dispose();
    Get.delete<NavigationCtrl>(tag: hashCode.toString());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Y aller',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: Stack(
        children: [
          Obx(() {
            final route = _nav.plan.value;
            final me = _nav.me.value;

            return FlutterMap(
              mapController: _map.mapController,
              options: MapOptions(
                initialCenter: widget.destination,
                initialZoom: 15,
                // Toucher la carte coupe le suivi : l'utilisateur regarde
                // quelque chose, on ne le lui reprend pas.
                onPointerDown: (_, _) => _nav.following.value = false,
              ),
              children: [
                TileLayer(
                  urlTemplate: MapCtrl.tileUrl,
                  tileDimension: MapCtrl.tileDimension,
                  zoomOffset: MapCtrl.zoomOffset,
                  fallbackUrl: MapCtrl.fallbackTileUrl,
                  userAgentPackageName: 'bj.eazyrent.eazyrent',
                ),

                if (route != null)
                  PolylineLayer(
                    polylines: [
                      // Deux traits superposés : un large sombre dessous, le
                      // terracotta dessus. Sans le liseré, le tracé disparaît
                      // sur les routes jaunes d'OSM.
                      Polyline(
                        points: route.geometry,
                        strokeWidth: 9,
                        color: p.inkStrong.withValues(alpha: 0.35),
                      ),
                      Polyline(
                        points: route.geometry,
                        strokeWidth: 5,
                        color: p.actionFill,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.destination,
                      width: 40,
                      height: 40,
                      child: _Pin(color: p.actionFill),
                    ),
                    if (me != null)
                      Marker(
                        point: me,
                        width: 26,
                        height: 26,
                        child: _MeDot(color: p.info),
                      ),
                  ],
                ),

                RichAttributionWidget(
                  attributions: [TextSourceAttribution(MapCtrl.attribution)],
                ),
              ],
            );
          }),

          // Bandeau haut : la manœuvre en cours.
          Positioned(
            left: Space.md,
            right: Space.md,
            top: Space.xs,
            child: Obx(() {
              if (_nav.arrived.value) {
                return _Banner(
                  icon: Icons.flag,
                  color: p.success,
                  title: 'Tu es arrivé.',
                  body: widget.destinationLabel,
                );
              }
              final route = _nav.plan.value;
              final step = route?.steps.isNotEmpty == true
                  ? route!.steps.first
                  : null;
              if (step == null) return const SizedBox.shrink();
              return _Banner(
                icon: Icons.turn_slight_right,
                color: p.inkStrong,
                title: step.instruction,
                body: widget.destinationLabel,
              );
            }),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomPanel(nav: _nav),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 220),
        child: Obx(
          () => FloatingActionButton(
            onPressed: () {
              _nav.following.value = true;
              final me = _nav.me.value;
              if (me != null) _map.animateTo(dest: me, zoom: 16);
            },
            backgroundColor: p.surfaceRaised,
            foregroundColor: _nav.following.value ? p.action : p.inkMuted,
            tooltip: 'Recentrer sur moi',
            child: const Icon(Icons.my_location),
          ),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.nav});

  final NavigationCtrl nav;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: const BorderRadius.vertical(top: Radii.sheet),
        boxShadow: Elevation.stickyBar,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Les quatre modes, zem en premier. Chacun porte SA durée dès
              // qu'elle est connue : comparer sans changer d'écran est tout
              // l'intérêt.
              Obx(
                () => Row(
                  children: [
                    for (final m in TravelMode.values)
                      Expanded(
                        child: _ModeChip(
                          mode: m,
                          selected: nav.mode.value == m,
                          duration: nav.alternatives[m]?.durationLabel,
                          onTap: () => nav.setMode(m),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: Space.sm),

              Obx(() {
                final err = nav.error.value;
                if (err != null) {
                  return Text(
                    err,
                    style: AppText.bodyL.copyWith(color: p.danger),
                  );
                }

                final route = nav.plan.value;
                if (route == null) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: p.action,
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Text(
                        'Calcul du chemin…',
                        style: AppText.bodyL.copyWith(color: p.inkMuted),
                      ),
                    ],
                  );
                }

                // EN ROUTE : ce qui est gros à l'écran devient CE QUI RESTE.
                // C'est le seul chiffre qui bouge quand on avance, donc le
                // seul qui prouve à l'utilisateur qu'il est suivi.
                final live = nav.started.value;
                final rest = nav.remainingMeters.value;
                final restDur = nav.remainingDuration;

                final bigTime = live && restDur != null
                    ? _fmtDuration(restDur)
                    : route.durationLabel;
                final bigDist = live && rest != null
                    ? _fmtDistance(rest.round())
                    : route.distanceLabel;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          bigTime,
                          style: AppText.displayM.copyWith(color: p.inkStrong),
                        ),
                        const SizedBox(width: Space.xs),
                        Text(
                          live ? '$bigDist restants' : bigDist,
                          style: AppText.bodyL.copyWith(color: p.inkMuted),
                        ),
                        const Spacer(),
                        // LE GESTE, SUR LA MÊME LIGNE QUE LE CHIFFRE.
                        //
                        // Empilé dessous, il tombait sous le pli : vérifié sur
                        // l'appareil, « Démarrer » n'était tout simplement pas
                        // à l'écran. Un panneau de navigation ne se fait pas
                        // défiler — on le lit d'un coup d'œil, une main sur le
                        // guidon.
                        //
                        // Et rien ne suit personne avant ce geste : un suivi
                        // qui démarre tout seul consomme la batterie de
                        // quelqu'un qui comparait simplement deux modes.
                        if (!live)
                          FilledButton.icon(
                            onPressed: nav.startGuiding,
                            style: FilledButton.styleFrom(
                              minimumSize: Size(
                                0,
                                Touch.target(p.isHighContrast),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Space.md,
                              ),
                            ),
                            icon: const Icon(Icons.navigation, size: 18),
                            label: const Text('Démarrer'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: nav.stopGuiding,
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(
                                0,
                                Touch.target(p.isHighContrast),
                              ),
                              foregroundColor: p.inkMuted,
                            ),
                            icon: const Icon(
                              Icons.stop_circle_outlined,
                              size: 18,
                            ),
                            label: const Text('Arrêter'),
                          ),
                      ],
                    ),

                    const SizedBox(height: Space.xxs),
                    // G40 — la limite du chiffre est SUR l'écran, pas dans
                    // une aide que personne n'ouvre. Une fois en route, elle
                    // cède la place à la précision du GPS : c'est ce qui
                    // compte quand on cherche un portail, pas une mise en
                    // garde qu'on a déjà lue.
                    Obx(() {
                      final acc = nav.accuracyMeters.value;
                      if (live && acc != null) {
                        return Text(
                          'Position à ± ${acc.round()} m près.',
                          style: AppText.caption.copyWith(color: p.inkMuted),
                        );
                      }
                      return Text(
                        route.mode.sharesCarTiming
                            ? 'Temps sans embouteillage. Le calcul ne tient '
                                  'pas compte du faufilage d\'un zem.'
                            : 'Temps sans embouteillage.',
                        style: AppText.caption.copyWith(color: p.inkMuted),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final TravelMode mode;
  final bool selected;
  final String? duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(right: Space.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          constraints: BoxConstraints(
            minHeight: Touch.target(p.isHighContrast) + 8,
          ),
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          decoration: BoxDecoration(
            color: selected ? p.surfaceSunken : p.surfaceRaised,
            border: Border.all(color: selected ? p.action : p.lineHair),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(mode.icon, size: 20, color: selected ? p.action : p.inkBase),
              const SizedBox(height: 2),
              Text(
                // Tant que la durée n'est pas revenue, on montre le NOM du
                // mode plutôt qu'un tiret : un tiret se lit comme
                // « indisponible ».
                duration ?? mode.label,
                style: AppText.caption.copyWith(
                  color: selected ? p.inkStrong : p.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: const BorderRadius.all(Radii.card),
        boxShadow: Elevation.mapPin,
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
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
                Text(
                  body,
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.location_on, color: color, size: 40);
}

class _MeDot extends StatelessWidget {
  const _MeDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: Elevation.mapPin,
    ),
  );
}

/// Mêmes règles d'écriture que `RoutePlan`, appliquées au reste du trajet.
/// Dupliquées ici plutôt qu'exposées : ce sont des libellés d'écran, pas des
/// propriétés du domaine — le domaine décrit un itinéraire entier, pas ce
/// qu'il en reste à un instant donné.
String _fmtDuration(Duration d) {
  final m = d.inMinutes;
  if (m < 1) return "moins d'1 min";
  if (m < 60) return '$m min';
  final h = m ~/ 60;
  final r = m % 60;
  return r == 0 ? '$h h' : '$h h ${r.toString().padLeft(2, '0')}';
}

String _fmtDistance(int meters) => meters < 1000
    ? '$meters m'
    : '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
