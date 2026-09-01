import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/molecules/listing_card.dart';
import '../../../auth/domain/entities/account.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/widgets/save_prompt_sheet.dart';
import '../../../listing/presentation/pages/listing_detail_page.dart';
import '../../../shortlist/presentation/bloc/shortlist_cubit.dart';
import '../bloc/feed_cubit.dart';

/// S02 — l'écran d'atterrissage permanent.
///
/// La contrainte principale est la DENSITÉ : 4 biens sur un écran de
/// 6,1 pouces. Tout le reste en découle — vignette à gauche plutôt que
/// bandeau, écart de 12 dp, hauteur de carte constante.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  /// Le produit est pensé pour une main sur un écran de 6,1 pouces. Au-delà,
  /// on ne s'étale pas : la ligne de lecture reste courte et le bouton favori
  /// reste à portée du pouce. Sans cette borne, sur tablette ou en paysage,
  /// le cœur de la carte se retrouve à 1 700 px de son bouton.
  static const double _maxContentWidth = 480;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: BlocBuilder<FeedCubit, FeedState>(
              builder: (context, state) => switch (state) {
                FeedLoading() => const _Skeleton(),
                FeedReady() => _Ready(state: state),
                FeedEmpty() => _Empty(state: state),
                FeedError() => _Error(state: state),
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: p.actionFill,
        foregroundColor: p.actionOnFill,
        icon: const Icon(Icons.notifications_none),
        // L'action à plus fort rendement de rétention de tout le produit.
        label: const Text('Alerte quartier'),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.xs,
        Space.md,
        Space.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.titleM.copyWith(color: p.inkStrong),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: 'Filtres',
            icon: Icon(Icons.tune, color: p.inkBase),
          ),
          // La carte est une BASCULE, pas un onglet (UX_CORE_SPEC §5.2).
          IconButton(
            onPressed: () {},
            tooltip: 'Voir sur la carte',
            icon: Icon(Icons.map_outlined, color: p.inkBase),
          ),
        ],
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state});

  final FeedReady state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = state.query;
    final label = q.neighborhoods.isEmpty
        ? 'Tous les quartiers'
        : q.neighborhoods.join(', ');

    return Column(
      children: [
        _SearchBar(label: label),

        if (state.fromCache)
          _Banner(
            icon: Icons.cloud_off,
            text: 'Pas de connexion. Tu vois ce qui est déjà chargé.',
            color: p.inkMuted,
          ),

        if (state.newSinceYesterday > 0)
          _Banner(
            icon: Icons.bolt,
            text: '${state.newSinceYesterday} nouveaux depuis hier',
            color: p.action,
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<FeedCubit>().refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, 96),
              // Hauteur constante : aucun saut au remplacement du squelette,
              // et le défilement n'a pas à mesurer chaque élément.
              itemExtent: Sizes.listingCardHeight + Space.feedGap,
              itemCount: state.listings.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: Space.feedGap),
                child: RepaintBoundary(
                  child: ListingCard(
                    listing: state.listings[i],
                    isSaved: context.watch<ShortlistCubit>().state.contains(
                      state.listings[i].id,
                    ),
                    onSave: () {
                      final shortlist = context.read<ShortlistCubit>();
                      shortlist.toggle(state.listings[i]);

                      // Le compte est demandé AU MOMENT où il veut garder
                      // quelque chose — il devient un service rendu, pas un
                      // péage (UX_CORE_SPEC §4.1). Jamais avant, jamais deux
                      // fois pour le même palier.
                      final auth = context.read<AuthCubit>();
                      final hasAccount = auth.state is Authenticated;
                      if (shortlist.shouldPromptSignUp(
                        hasAccount: hasAccount,
                      )) {
                        SavePromptSheet.show(
                          context,
                          savedCount: shortlist.state.saved.length,
                          onCreateAccount: auth.requestSignUp,
                        );
                      }
                    },
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ListingDetailScreen(
                          listing: state.listings[i],
                          agentName: 'Rachid',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Space.xxs),
        Expanded(
          child: Text(text, style: AppText.label.copyWith(color: color)),
        ),
      ],
    ),
  );
}

/// Squelette à la silhouette exacte de la carte finale. Un squelette qui a la
/// forme du contenu réduit la latence perçue ; un cercle centré ne le fait pas.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.builder(
      padding: const EdgeInsets.all(Space.md),
      itemExtent: Sizes.listingCardHeight + Space.feedGap,
      itemCount: 5,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: Space.feedGap),
        child: Row(
          children: [
            Container(
              width: Sizes.listingThumbWidth,
              height: Sizes.listingCardHeight,
              decoration: BoxDecoration(
                color: p.surfaceSunken,
                borderRadius: const BorderRadius.all(Radii.card),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Bar(width: 120, height: 22, color: p.surfaceSunken),
                  const SizedBox(height: Space.xs),
                  _Bar(width: 180, height: 14, color: p.surfaceSunken),
                  const SizedBox(height: Space.xxs),
                  _Bar(width: 150, height: 14, color: p.surfaceSunken),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.all(Radii.chip),
    ),
  );
}

/// « Toujours une action. Jamais "Aucun résultat" seul. » (§8)
class _Empty extends StatelessWidget {
  const _Empty({required this.state});

  final FeedEmpty state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final where = state.query.neighborhoods.isEmpty
        ? 'ces critères'
        : state.query.neighborhoods.join(', ');

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucun bien à $where pour le moment.',
            style: AppText.titleL.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.sm),
          Text(
            "Élargis ta recherche, ou fais-toi prévenir dès qu'un bien arrive.",
            style: AppText.bodyL.copyWith(color: p.inkBase),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () {},
            child: const Text('Élargir la recherche'),
          ),
          const SizedBox(height: Space.xs),
          TextButton(
            onPressed: () {},
            child: const Text('Créer une alerte quartier'),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.state});

  final FeedError state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Le message vient du Failure : français simple, jamais un code.
          Text(
            state.failure.userMessage,
            style: AppText.titleM.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () => context.read<FeedCubit>().refresh(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
