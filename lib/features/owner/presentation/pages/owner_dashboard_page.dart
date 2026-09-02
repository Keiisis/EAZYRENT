import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../data/owner_repository.dart';
import '../bloc/owner_cubit.dart';
import 'my_listing_page.dart';
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
///
/// LES CHIFFRES VIENNENT DE LA BASE. Ils affichaient une démonstration
/// pendant que le serveur en connaissait d'autres — un tableau de bord faux
/// est pire qu'absent, parce qu'on décide avec.
class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OwnerCubit(getIt<OwnerRepository>())..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: BlocBuilder<OwnerCubit, OwnerState>(
              builder: (context, state) => switch (state) {
                OwnerLoading() => const _Skeleton(),
                OwnerEmpty() => const _NoListing(),
                OwnerError(:final failure) => _Error(
                  message: failure.userMessage,
                  onRetry: context.read<OwnerCubit>().load,
                ),
                OwnerReady() => _Ready(state: state),
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final cubit = context.read<OwnerCubit>();
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PublishListingScreen(),
            ),
          );
          await cubit.load();
        },
        backgroundColor: p.actionFill,
        foregroundColor: p.actionOnFill,
        icon: const Icon(Icons.add),
        label: const Text('Publier un bien'),
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state});

  final OwnerReady state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return RefreshIndicator(
      onRefresh: context.read<OwnerCubit>().load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 96),
        children: [
          Text('Mes biens', style: AppText.titleL.copyWith(color: p.inkStrong)),
          const SizedBox(height: Space.md),

          // Trois chiffres, sans décor. Un tableau de bord qui commence
          // par un graphique ne répond à aucune question.
          Row(
            children: [
              _Stat(value: '${state.listings.length}', label: 'mes biens'),
              _Stat(value: '${state.totalViews}', label: 'vues 7 jours'),
              _Stat(
                value: '${state.pendingRequests}',
                label: 'demandes',
                highlight: state.pendingRequests > 0,
                onTap: state.pendingRequests > 0
                    ? () async {
                        final cubit = context.read<OwnerCubit>();
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const VisitRequestsScreen(),
                          ),
                        );
                        await cubit.load();
                      }
                    : null,
              ),
            ],
          ),

          const SizedBox(height: Space.lg),
          for (final l in state.listings) _ListingRow(listing: l),
        ],
      ),
    );
  }
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

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.listing});

  final OwnerListing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      // P02 — le bien s'ouvre. Sans ça, un bailleur ne pouvait ni corriger un
      // prix, ni retirer un bien loué : un catalogue gonflé plutôt que vrai.
      child: InkWell(
        onTap: () async {
          final cubit = context.read<OwnerCubit>();
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MyListingScreen(listing: listing),
            ),
          );
          await cubit.load();
        },
        borderRadius: const BorderRadius.all(Radii.card),
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
                              errorWidget: (_, _, _) =>
                                  ColoredBox(color: p.surfaceSunken),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${MoneyFcfa.short(listing.rentFcfa)}/mois',
                          style: AppText.bodyM.copyWith(
                            color: p.inkMuted,
                            fontFeatures: Fonts.tabular,
                          ),
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
                            // Un bien retiré doit se voir d'un coup d'œil,
                            // sinon on croit qu'il est toujours en ligne.
                            if (!listing.isAvailable) ...[
                              const SizedBox(width: Space.sm),
                              Icon(
                                Icons.visibility_off,
                                size: 14,
                                color: p.warn,
                              ),
                              const SizedBox(width: Space.xxs),
                              Text(
                                'Retiré',
                                style: AppText.label.copyWith(color: p.warn),
                              ),
                            ],
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
              // prouvée. Demander 5 000 F à un propriétaire qui n'a encore
              // rien reçu ferait échouer l'offre ; la lui proposer devant des
              // vues réelles la rend évidente.
              //
              // ⚠️ Aucune statistique comparative ici (« 4× plus de
              // demandes ») tant qu'elle n'aura pas été mesurée.
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
                        '${listing.views} personnes ont vu ton bien cette '
                        'semaine.',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Aux dimensions réelles : quand les données arrivent, rien ne saute.
    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Container(height: 28, width: 160, color: p.surfaceSunken),
        const SizedBox(height: Space.lg),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: Container(height: 48, color: p.surfaceSunken),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.lg),
        for (var i = 0; i < 2; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Container(height: 104, color: p.surfaceSunken),
          ),
      ],
    );
  }
}

/// « Toujours une action. Jamais un cul-de-sac. » Un bailleur sans bien n'a
/// pas besoin d'un tableau vide : il a besoin du bouton qui l'en sort.
class _NoListing extends StatelessWidget {
  const _NoListing();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu n\'as encore aucun bien en ligne.',
            style: AppText.titleM.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Quatre champs suffisent : quartier, loyer, type, téléphone. '
            'La publication est gratuite et immédiate.',
            style: AppText.bodyL.copyWith(color: p.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppText.bodyL.copyWith(color: p.inkStrong)),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              minimumSize: Size(0, Touch.target(p.isHighContrast)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
