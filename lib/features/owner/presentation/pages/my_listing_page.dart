import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/presentation/pages/report_listing_page.dart';
import '../../data/owner_repository.dart';
import '../bloc/owner_cubit.dart';
import 'request_tour_page.dart';
import 'visit_requests_page.dart';

/// P02 — Mon annonce, et la preuve de la demande.
///
/// Le tableau de bord liste les biens ; sans cet écran, un bailleur ne
/// pouvait pas ouvrir le sien — donc ni corriger un prix, ni le retirer
/// quand il est loué. Un bien loué qui reste en ligne détruit la fraîcheur du
/// parc, c'est-à-dire le produit.
///
/// LA PREUVE DE DEMANDE EST EN HAUT, avant les réglages. Un bailleur ouvre
/// son annonce pour savoir si elle marche, pas pour administrer un
/// formulaire.
///
/// « MARQUER COMME LOUÉ » ÉCRIT EN BASE. Auparavant l'écran se contentait de
/// changer sa propre couleur : le bailleur croyait son bien retiré, et les
/// chercheurs continuaient de se déplacer. Une action locale qui ne persiste
/// pas est pire qu'un bouton absent — elle fait croire que c'est fait.
class MyListingScreen extends StatelessWidget {
  const MyListingScreen({required this.listing, super.key});

  final OwnerListing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Le cubit vient du tableau de bord : l'écriture et le rechargement
    // passent par la même instance, donc la liste derrière est à jour au
    // retour, sans code de synchronisation.
    return BlocBuilder<OwnerCubit, OwnerState>(
      builder: (context, state) {
        // On relit le bien dans l'état COURANT : après « marquer comme loué »
        // et rechargement, c'est cette version-là qui est vraie, pas celle
        // reçue en paramètre.
        final l = switch (state) {
          OwnerReady(:final listings) => listings.firstWhere(
            (x) => x.id == listing.id,
            orElse: () => listing,
          ),
          _ => listing,
        };

        return Scaffold(
          backgroundColor: p.surfaceBase,
          appBar: AppBar(
            backgroundColor: p.surfaceBase,
            title: Text(
              'Mon annonce',
              style: AppText.titleM.copyWith(color: p.inkStrong),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.all(Space.md),
                  children: [
                    Text(
                      '${l.title} · ${l.neighborhood}',
                      style: AppText.titleL.copyWith(color: p.inkStrong),
                    ),
                    Text(
                      '${MoneyFcfa.short(l.rentFcfa)} par mois',
                      style: AppText.bodyL.copyWith(
                        color: p.inkMuted,
                        fontFeatures: Fonts.tabular,
                      ),
                    ),

                    const SizedBox(height: Space.md),
                    Row(
                      children: [
                        _Stat(
                          value: '${l.views}',
                          label: 'vues cette semaine',
                          tone: p.inkStrong,
                        ),
                        const SizedBox(width: Space.sm),
                        _Stat(
                          value: '${l.pendingRequests}',
                          label: l.pendingRequests > 1
                              ? 'demandes de visite'
                              : 'demande de visite',
                          tone: l.pendingRequests > 0 ? p.success : p.inkMuted,
                        ),
                      ],
                    ),

                    // L'offre de tournage n'arrive qu'ici, et qu'après la
                    // preuve.
                    if (!l.hasTour && l.views > 0) ...[
                      const SizedBox(height: Space.md),
                      Container(
                        padding: const EdgeInsets.all(Space.sm),
                        decoration: BoxDecoration(
                          color: p.surfaceSunken,
                          borderRadius: const BorderRadius.all(Radii.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l.views} personnes ont vu ton bien sans '
                              'pouvoir entrer.',
                              style: AppText.bodyL.copyWith(color: p.inkBase),
                            ),
                            const SizedBox(height: Space.xs),
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => RequestTourScreen(
                                    listingTitle: l.title,
                                    views: l.views,
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(
                                  0,
                                  Touch.target(p.isHighContrast),
                                ),
                                foregroundColor: p.action,
                                side: BorderSide(
                                  color: p.action,
                                  width: p.borderWidth,
                                ),
                              ),
                              child: const Text(
                                'Ajouter une Visite Vérifiée — 5 000 F',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: Space.lg),

                    // L'action qui tient la fraîcheur du parc, juste après la
                    // preuve — jamais reléguée en bas.
                    _Action(
                      icon: l.isAvailable
                          ? Icons.check_circle_outline
                          : Icons.visibility_off,
                      label: l.isAvailable
                          ? 'Marquer comme loué'
                          : 'Remettre en ligne',
                      subtitle: l.isAvailable
                          ? 'Le bien sort des résultats tout de suite.'
                          : 'Le bien redevient visible.',
                      onTap: () => context.read<OwnerCubit>().setAvailability(
                        l.id,
                        online: !l.isAvailable,
                      ),
                    ),
                    _Action(
                      icon: Icons.event_note_outlined,
                      label: 'Voir les demandes de visite',
                      subtitle: '${l.pendingRequests} en attente de réponse',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const VisitRequestsScreen(),
                        ),
                      ),
                    ),
                    _Action(
                      icon: Icons.edit_outlined,
                      label: 'Corriger le prix ou la description',
                      subtitle: 'Un prix affiché doit être le prix demandé.',
                      onTap: () {},
                    ),
                    _Action(
                      icon: Icons.photo_library_outlined,
                      label: 'Changer les photos',
                      onTap: () {},
                    ),
                    _Action(
                      icon: Icons.flag_outlined,
                      label: 'Signaler un problème sur ce bien',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReportListingScreen(
                            listingTitle: '${l.title} · ${l.neighborhood}',
                          ),
                        ),
                      ),
                    ),

                    if (!l.isAvailable) ...[
                      const SizedBox(height: Space.md),
                      Container(
                        padding: const EdgeInsets.all(Space.sm),
                        decoration: BoxDecoration(
                          color: p.surfaceSunken,
                          borderRadius: const BorderRadius.all(Radii.card),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_off,
                              size: 18,
                              color: p.inkMuted,
                            ),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: Text(
                                'Ce bien n\'apparaît plus dans les recherches. '
                                'Personne ne se déplacera pour rien.',
                                style: AppText.bodyM.copyWith(color: p.inkBase),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: Space.lg),
                    Text(
                      'Bail sous le régime de la loi n° 2018-12. Le préavis '
                      'est de un mois pour un bail à usage d\'habitation.',
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.tone});

  final String value;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          border: Border.all(color: p.lineHair, width: p.borderWidth),
          borderRadius: const BorderRadius.all(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppText.amount.copyWith(
                color: tone,
                fontFeatures: Fonts.tabular,
              ),
            ),
            Text(label, style: AppText.bodyM.copyWith(color: p.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: Touch.target(p.isHighContrast)),
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(
          children: [
            Icon(icon, size: 20, color: p.inkBase),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppText.bodyL.copyWith(color: p.inkStrong),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: p.inkFaint),
          ],
        ),
      ),
    );
  }
}
