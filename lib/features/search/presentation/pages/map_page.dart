import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/pages/listing_detail_page.dart';

/// S03 — Carte.
///
/// « Ce n'est pas un onglet, c'est une bascule » (UX_CORE_SPEC.md §5.2) :
/// l'icône 🗺 permute liste ⇄ carte sur les MÊMES résultats filtrés. Aucun
/// filtre ne se perd au passage — sinon la bascule devient une seconde
/// recherche, et personne ne l'utilise deux fois.
///
/// Les marqueurs sont des PASTILLES DE PRIX (`35k`), jamais des épingles :
/// l'information est le prix, pas la position. Une carte d'épingles oblige à
/// toucher chaque point pour savoir ce qu'il vaut.
///
/// ⚠️ ÉTAT RÉEL DE CET ÉCRAN. La tuile Google Maps n'est PAS branchée : elle
/// exige une clé d'API que le projet n'a pas encore (`MAPS_API_KEY`), et une
/// carte sans clé s'affiche en rectangle gris — c'est-à-dire comme une
/// application cassée. En attendant, l'écran rend le service que la carte
/// devait rendre : voir les prix par quartier d'un coup d'œil, sans faire
/// défiler la liste. Le regroupement par quartier est d'ailleurs ce que fait
/// la carte au dézoom.
class MapScreen extends StatefulWidget {
  const MapScreen({required this.listings, super.key});

  final List<Listing> listings;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedQuartier;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Regroupement par quartier — équivalent du clustering au dézoom, avec le
    // NOMBRE de biens, jamais un point anonyme.
    final byQuartier = <String, List<Listing>>{};
    for (final l in widget.listings) {
      // Un bien sans quartier renseigné retombe sur sa ville plutôt que de
      // disparaître : un bien qu'on ne voit nulle part est un bien perdu.
      byQuartier.putIfAbsent(l.neighborhood ?? l.city, () => []).add(l);
    }
    final quartiers = byQuartier.keys.toList()..sort();
    final selected =
        _selectedQuartier ?? (quartiers.isEmpty ? null : quartiers.first);
    final shown = selected == null
        ? const <Listing>[]
        : byQuartier[selected] ?? const <Listing>[];

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Par quartier',
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Les pastilles de prix. Un quartier = son prix d'entrée le
                // plus bas, parce que c'est ce qu'on cherche à savoir en
                // premier : « est-ce que ce quartier est pour moi ? »
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    children: [
                      for (final q in quartiers)
                        _QuartierPill(
                          quartier: q,
                          count: byQuartier[q]!.length,
                          fromRent: byQuartier[q]!
                              .map((l) => l.monthlyRentFcfa)
                              .reduce((a, b) => a < b ? a : b),
                          hasTour: byQuartier[q]!.any((l) => l.hasVerifiedTour),
                          selected: q == selected,
                          onTap: () => setState(() => _selectedQuartier = q),
                        ),
                    ],
                  ),
                ),

                Divider(color: p.lineHair, height: 1),

                Expanded(
                  child: shown.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun bien dans les résultats.',
                            style: AppText.bodyL.copyWith(color: p.inkMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(Space.md),
                          itemCount: shown.length,
                          itemBuilder: (_, i) => _CarouselCard(
                            listing: shown[i],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ListingDetailScreen(listing: shown[i]),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuartierPill extends StatelessWidget {
  const _QuartierPill({
    required this.quartier,
    required this.count,
    required this.fromRent,
    required this.hasTour,
    required this.selected,
    required this.onTap,
  });

  final String quartier;
  final int count;
  final int fromRent;
  final bool hasTour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(right: Space.xs, top: Space.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          constraints: BoxConstraints(
            minHeight: Touch.target(p.isHighContrast),
            minWidth: 104,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? p.actionFill : p.surfaceRaised,
            border: Border.all(color: selected ? p.actionFill : p.lineHair),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    quartier,
                    style: AppText.bodyL.copyWith(
                      color: selected ? p.actionOnFill : p.inkStrong,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Le badge 360, en cyan, comme sur la pastille de la carte.
                  if (hasTour) ...[
                    const SizedBox(width: Space.xxs),
                    Icon(
                      Icons.threesixty,
                      size: 15,
                      color: selected ? p.actionOnFill : p.info,
                    ),
                  ],
                ],
              ),
              Text(
                'dès ${MoneyFcfa.short(fromRent)}',
                style: AppText.label.copyWith(
                  color: selected ? p.actionOnFill : p.inkMuted,
                  fontFeatures: Fonts.tabular,
                ),
              ),
              Text(
                '$count bien${count > 1 ? 's' : ''}',
                style: AppText.caption.copyWith(
                  color: selected ? p.actionOnFill : p.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radii.card),
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.feedGap),
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          border: Border.all(color: p.lineHair),
          borderRadius: const BorderRadius.all(Radii.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MoneyFcfa.short(listing.monthlyRentFcfa),
                    style: AppText.titleM.copyWith(
                      color: p.inkStrong,
                      fontFeatures: Fonts.tabular,
                    ),
                  ),
                  Text(
                    '${listing.propertyType} · '
                    '${listing.neighborhood ?? listing.city}',
                    style: AppText.bodyM.copyWith(color: p.inkMuted),
                  ),
                  // Le coût d'entrée reste affiché même inconnu : le taire
                  // laisserait croire qu'il n'y en a pas.
                  Text(
                    listing.totalMoveInCostFcfa == null
                        ? 'Entrée à confirmer'
                        : 'Entrée '
                              '${MoneyFcfa.short(listing.totalMoveInCostFcfa!)}',
                    style: AppText.bodyM.copyWith(
                      color: p.inkBase,
                      fontFeatures: Fonts.tabular,
                    ),
                  ),
                ],
              ),
            ),
            if (listing.hasVerifiedTour)
              Icon(Icons.threesixty, color: p.info, size: 22),
          ],
        ),
      ),
    );
  }
}
