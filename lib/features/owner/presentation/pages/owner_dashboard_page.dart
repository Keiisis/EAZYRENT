import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import 'publish_listing_page.dart';
import 'request_tour_page.dart';
import 'visit_requests_page.dart';

/// C1 — Tableau de bord bailleur.
///
/// Un propriétaire ne cherche pas : il surveille. L'écran répond donc à trois
/// questions dans cet ordre, et à rien d'autre :
///   1. Combien de biens ai-je ?
///   2. Est-ce qu'on les regarde ?
///   3. Est-ce qu'on me demande quelque chose ?
///
/// Pas de feed, pas de recherche : ce sont les outils du chercheur.
class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Données de démonstration tant que le module owner n'a pas sa couche
    // data. Nommées comme telles : rien ici ne doit passer pour du réel.
    const demo = [
      _OwnerListing(
        title: 'Chambre-salon',
        neighborhood: 'Fidjrossè',
        rent: 35000,
        views: 23,
        requests: 2,
        hasTour: true,
        imageUrl:
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
      ),
      _OwnerListing(
        title: 'Studio',
        neighborhood: 'Godomey',
        rent: 25000,
        views: 4,
        requests: 0,
        hasTour: false,
        imageUrl: null,
      ),
    ];

    final totalViews = demo.fold<int>(0, (s, l) => s + l.views);
    final totalRequests = demo.fold<int>(0, (s, l) => s + l.requests);

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                96,
              ),
              children: [
                Text(
                  'Mes biens',
                  style: AppText.titleL.copyWith(color: p.inkStrong),
                ),
                const SizedBox(height: Space.md),

                // Trois chiffres, sans décor. Un tableau de bord qui commence
                // par un graphique ne répond à aucune question.
                Row(
                  children: [
                    _Stat(value: '${demo.length}', label: 'mes biens'),
                    _Stat(value: '$totalViews', label: 'vues 7 jours'),
                    _Stat(
                      value: '$totalRequests',
                      label: 'demandes',
                      highlight: totalRequests > 0,
                      onTap: totalRequests > 0
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const VisitRequestsScreen(),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: Space.lg),
                for (final l in demo) _ListingRow(listing: l),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PublishListingScreen()),
        ),
        backgroundColor: p.actionFill,
        foregroundColor: p.actionOnFill,
        icon: const Icon(Icons.add),
        label: const Text('Publier un bien'),
      ),
    );
  }
}

class _OwnerListing {
  const _OwnerListing({
    required this.title,
    required this.neighborhood,
    required this.rent,
    required this.views,
    required this.requests,
    required this.hasTour,
    required this.imageUrl,
  });

  final String title;
  final String neighborhood;
  final int rent;
  final int views;
  final int requests;
  final bool hasTour;
  final String? imageUrl;
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.highlight = false,
    this.onTap,
  });

  final String value;
  final String label;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppText.displayM.copyWith(
                // Une demande en attente est la seule chose qui mérite la
                // couleur d'action sur cet écran.
                color: highlight ? p.action : p.inkStrong,
              ),
            ),
            Text(label, style: AppText.bodyM.copyWith(color: p.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.listing});

  final _OwnerListing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          border: Border.all(color: p.lineHair),
          borderRadius: const BorderRadius.all(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radii.input),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: listing.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: listing.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                            color: p.surfaceSunken,
                            child: Center(
                              child: Text(
                                'Sans\nphoto',
                                textAlign: TextAlign.center,
                                style: AppText.caption.copyWith(
                                  color: p.inkMuted,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${listing.title} · ${listing.neighborhood}',
                        style: AppText.bodyL.copyWith(color: p.inkStrong),
                      ),
                      Text(
                        '${MoneyFcfa.short(listing.rent)} /mois',
                        style: AppText.bodyM.copyWith(color: p.inkMuted),
                      ),
                      const SizedBox(height: Space.xxs),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: p.inkMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${listing.views} vues',
                            style: AppText.label.copyWith(color: p.inkMuted),
                          ),
                          const SizedBox(width: Space.sm),
                          if (listing.requests > 0) ...[
                            Icon(
                              Icons.event_available_outlined,
                              size: 14,
                              color: p.action,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${listing.requests} demandes',
                              style: AppText.label.copyWith(color: p.action),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: Space.xxs),
                      Row(
                        children: [
                          Icon(
                            listing.hasTour
                                ? Icons.check_circle
                                : Icons.photo_outlined,
                            size: 14,
                            color: listing.hasTour ? p.success : p.inkMuted,
                          ),
                          const SizedBox(width: Space.xxs),
                          Text(
                            listing.hasTour
                                ? 'Visite 360 active'
                                : 'Photos seulement',
                            style: AppText.label.copyWith(
                              color: listing.hasTour ? p.success : p.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // C2 — LA PREUVE DE DEMANDE.
            //
            // L'offre de tournage n'arrive QU'APRÈS que la demande soit
            // prouvée. Demander 5 000 F à un propriétaire qui n'a encore rien
            // reçu ferait échouer l'offre ; la lui proposer devant 23 vues
            // réelles la rend évidente.
            //
            // ⚠️ Aucune statistique comparative ici (« 4× plus de demandes »)
            // tant qu'elle n'aura pas été mesurée sur de vrais biens.
            if (!listing.hasTour && listing.views > 0) ...[
              const SizedBox(height: Space.sm),
              Container(
                padding: const EdgeInsets.all(Space.sm),
                decoration: BoxDecoration(
                  color: p.surfaceSunken,
                  borderRadius: const BorderRadius.all(Radii.input),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${listing.views} personnes ont vu ton bien cette semaine.',
                      style: AppText.bodyM.copyWith(color: p.inkBase),
                    ),
                    const SizedBox(height: Space.xs),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RequestTourScreen(
                            listingTitle: listing.title,
                            views: listing.views,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(0, Touch.target(p.isHighContrast)),
                        foregroundColor: p.action,
                        side: BorderSide(color: p.action),
                      ),
                      child: const Text(
                        'Ajouter une Visite Vérifiée — 5 000 F',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
