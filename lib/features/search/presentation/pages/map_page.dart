import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/pages/listing_detail_page.dart';
import '../controllers/map_controller.dart';

/// S03 — Carte.
///
/// « Ce n'est pas un onglet, c'est une bascule » (UX_CORE_SPEC.md §5.2) :
/// la carte reçoit LES MÊMES résultats filtrés que la liste, jamais une
/// nouvelle requête. Sinon la bascule devient une seconde recherche, et
/// personne ne l'utilise deux fois.
///
/// LES MARQUEURS SONT DES PASTILLES DE PRIX (`35 000 F`), jamais des épingles.
/// L'information est le prix, pas la position. Une carte d'épingles oblige à
/// toucher chaque point pour savoir ce qu'il vaut — c'est-à-dire à faire
/// vingt gestes pour obtenir ce qu'une liste donne en un regard.
///
/// AUCUNE CLÉ GOOGLE ICI. `flutter_map` tire ses tuiles de n'importe quel
/// serveur : OpenStreetMap sans jeton, Mapbox si `MAPBOX_TOKEN` existe. Une
/// configuration absente dégrade le rendu, elle ne casse jamais l'écran.
class MapScreen extends StatefulWidget {
  const MapScreen({required this.listings, super.key});

  final List<Listing> listings;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final MapCtrl _ctrl;
  late final AnimatedMapController _map;
  late final PageController _carousel;

  @override
  void initState() {
    super.initState();
    // Instance NOMMÉE : deux ouvertures de la carte ne doivent pas se
    // partager une sélection. Le tag isole, `Get.delete` nettoie.
    _ctrl = Get.put(
      MapCtrl(listings: widget.listings),
      tag: hashCode.toString(),
    );
    _map = AnimatedMapController(
      vsync: this,
      duration: Motion.slow,
      curve: Curves.easeOutCubic,
    );
    _carousel = PageController(viewportFraction: 0.86);

    if (_ctrl.mappable.isNotEmpty) {
      _ctrl.select(_ctrl.mappable.first.id);
    }
  }

  @override
  void dispose() {
    _map.dispose();
    _carousel.dispose();
    Get.delete<MapCtrl>(tag: hashCode.toString());
    super.dispose();
  }

  /// Synchronisation MARQUEUR → CARROUSEL.
  void _onMarkerTap(int index) {
    _ctrl.select(_ctrl.mappable[index].id);
    _carousel.animateToPage(
      index,
      duration: Motion.slow,
      curve: Curves.easeOutCubic,
    );
    _map.animateTo(dest: _ctrl.positionOf(_ctrl.mappable[index]), zoom: 15);
  }

  /// Synchronisation CARROUSEL → CAMÉRA. Les deux sens, sinon l'un des deux
  /// gestes donne l'impression que l'écran ne répond pas.
  void _onPageChanged(int index) {
    _ctrl.select(_ctrl.mappable[index].id);
    _map.animateTo(dest: _ctrl.positionOf(_ctrl.mappable[index]));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = _ctrl.mappable;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Sur la carte',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
        actions: [
          IconButton(
            tooltip: 'Revenir à la liste',
            icon: const Icon(Icons.view_list_outlined),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: items.isEmpty
          ? _NoCoordinates(total: widget.listings.length)
          : Stack(
              children: [
                FlutterMap(
                  mapController: _map.mapController,
                  options: MapOptions(
                    initialCenter: _ctrl.initialCenter,
                    initialZoom: 13,
                    minZoom: 10,
                    maxZoom: 18,
                    // Toucher le fond désélectionne : on ne piège personne
                    // dans une fiche ouverte.
                    onTap: (_, _) => _ctrl.select(null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapCtrl.tileUrl,
                      // Si Mapbox refuse (jeton expiré, quota, 401), la tuile
                      // est redemandée à OpenStreetMap au lieu de rester
                      // vide. Vérifié sur l'appareil : sans ce repli, un
                      // jeton invalide donne un rectangle gris muet.
                      fallbackUrl: MapCtrl.fallbackTileUrl,
                      userAgentPackageName: 'bj.eazyrent.eazyrent',
                      // Les tuiles conservées font la carte utilisable dans
                      // un taxi sans réseau — cas quotidien ici.
                      maxNativeZoom: 18,
                    ),

                    Obx(() {
                      final me = _ctrl.userPosition.value;
                      if (me == null) return const SizedBox.shrink();
                      return MarkerLayer(
                        markers: [
                          Marker(
                            point: me,
                            width: 22,
                            height: 22,
                            child: _MeDot(color: p.info),
                          ),
                        ],
                      );
                    }),

                    Obx(() {
                      final selectedId = _ctrl.selectedId.value;
                      return MarkerLayer(
                        markers: [
                          for (var i = 0; i < items.length; i++)
                            Marker(
                              point: _ctrl.positionOf(items[i]),
                              width: 116,
                              height: 44,
                              alignment: Alignment.topCenter,
                              child: _PricePill(
                                listing: items[i],
                                selected: items[i].id == selectedId,
                                onTap: () => _onMarkerTap(i),
                              ),
                            ),
                        ],
                      );
                    }),

                    // Attribution obligatoire (ODbL pour OSM, conditions
                    // Mapbox). Ce n'est pas un ornement.
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(MapCtrl.attribution),
                      ],
                    ),
                  ],
                ),

                // Le carrousel, synchronisé dans les deux sens.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 132,
                      child: PageView.builder(
                        controller: _carousel,
                        onPageChanged: _onPageChanged,
                        itemCount: items.length,
                        itemBuilder: (_, i) => _CarouselCard(
                          listing: items[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ListingDetailScreen(listing: items[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Les biens sans coordonnées ne disparaissent pas en silence.
                if (_ctrl.unmappedCount > 0)
                  Positioned(
                    left: Space.md,
                    right: Space.md,
                    top: Space.xs,
                    child: _Notice(
                      text:
                          '${_ctrl.unmappedCount} bien'
                          '${_ctrl.unmappedCount > 1 ? "s" : ""} sans adresse '
                          'précise — visible'
                          '${_ctrl.unmappedCount > 1 ? "s" : ""} dans la liste.',
                    ),
                  ),
              ],
            ),
      floatingActionButton: items.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 140),
              child: Obx(
                () => FloatingActionButton(
                  onPressed: _ctrl.locating.value
                      ? null
                      : () async {
                          await _ctrl.locateMe();
                          final me = _ctrl.userPosition.value;
                          if (me != null) {
                            await _map.animateTo(dest: me, zoom: 14);
                          }
                        },
                  backgroundColor: p.surfaceRaised,
                  foregroundColor: _ctrl.locationDenied.value
                      ? p.inkMuted
                      : p.action,
                  tooltip: _ctrl.locationDenied.value
                      ? 'Position indisponible'
                      : 'Me localiser',
                  child: _ctrl.locating.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: p.action,
                          ),
                        )
                      : const Icon(Icons.my_location),
                ),
              ),
            ),
    );
  }
}

/// La pastille de prix. Sélectionnée : elle grandit, prend le terracotta et
/// pointe le bien. C'est le SEUL « halo » autorisé de l'application, et sur
/// un seul élément à la fois (UI_SCREENS_SPEC.md S03).
class _PricePill extends StatelessWidget {
  const _PricePill({
    required this.listing,
    required this.selected,
    required this.onTap,
  });

  final Listing listing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: Motion.base,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? p.actionFill : p.surfaceRaised,
              borderRadius: const BorderRadius.all(Radii.pill),
              border: Border.all(
                color: selected ? p.actionFill : p.lineStrong,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: p.actionFill.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : Elevation.mapPin,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MoneyFcfa.short(listing.monthlyRentFcfa),
                  style: AppText.label.copyWith(
                    color: selected ? p.actionOnFill : p.inkStrong,
                    fontWeight: FontWeight.w700,
                    fontFeatures: Fonts.tabular,
                  ),
                ),
                // Le badge 360 en cyan, sur la pastille : c'est ce qui
                // distingue un bien qu'on peut visiter tout de suite.
                if (listing.hasVerifiedTour) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.threesixty,
                    size: 14,
                    color: selected ? p.actionOnFill : p.info,
                  ),
                ],
              ],
            ),
          ),
          // La pointe : sans elle, la pastille flotte au-dessus du lieu au
          // lieu de le désigner.
          CustomPaint(
            size: const Size(10, 6),
            painter: _PinTip(color: selected ? p.actionFill : p.surfaceRaised),
          ),
        ],
      ),
    );
  }
}

class _PinTip extends CustomPainter {
  const _PinTip({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinTip old) => old.color != color;
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

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.xs,
        vertical: Space.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: const BorderRadius.all(Radii.card),
            boxShadow: Elevation.mapPin,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Même ordre de lecture que la carte du feed : prix →
                    // type et quartier → fraîcheur → coût d'entrée.
                    Text(
                      MoneyFcfa.short(listing.monthlyRentFcfa),
                      style: AppText.amount.copyWith(color: p.inkStrong),
                      maxLines: 1,
                    ),
                    Text(
                      '${listing.propertyType} · ${listing.locationLabel}',
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      listing.freshness.label,
                      style: AppText.label.copyWith(
                        color: switch (listing.freshness.tone) {
                          FreshnessTone.ok => p.success,
                          FreshnessTone.warn => p.warn,
                          FreshnessTone.stale => p.inkMuted,
                        },
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      listing.totalMoveInCostFcfa == null
                          ? 'Entrée à confirmer'
                          : 'Entrée : '
                                '${MoneyFcfa.short(listing.totalMoveInCostFcfa!)}',
                      style: AppText.bodyM.copyWith(
                        color: p.inkStrong,
                        fontWeight: FontWeight.w600,
                        fontFeatures: Fonts.tabular,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: const BorderRadius.all(Radii.pill),
        boxShadow: Elevation.mapPin,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.label.copyWith(color: p.inkBase),
      ),
    );
  }
}

/// « Toujours une action. Jamais un cul-de-sac. » Une carte sans point à
/// montrer renvoie vers ce qui, lui, a des résultats.
class _NoCoordinates extends StatelessWidget {
  const _NoCoordinates({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              total == 0
                  ? 'Aucun bien à afficher.'
                  : 'Ces biens n\'ont pas d\'adresse précise.',
              style: AppText.titleM.copyWith(color: p.inkStrong),
            ),
            const SizedBox(height: Space.xs),
            Text(
              total == 0
                  ? 'Élargis un critère et reviens.'
                  : 'Beaucoup de biens sont déposés par téléphone, sans qu\'on '
                        'soit passé sur place. Ils restent visibles dans la '
                        'liste, avec leur quartier.',
              style: AppText.bodyL.copyWith(color: p.inkMuted),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
              ),
              child: Text(
                total == 0 ? 'Revenir' : 'Voir les $total biens en liste',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
