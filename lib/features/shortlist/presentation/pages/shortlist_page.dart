import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../../core/widgets/molecules/listing_card.dart';
import '../../../listing/presentation/pages/listing_detail_page.dart';
import '../bloc/shortlist_cubit.dart';
import 'duel_page.dart';
import 'family_council_page.dart';

/// S08 — Ma liste.
///
/// Le compteur d'économies est EN BAS, pas en haut : c'est une récompense
/// qu'on découvre après avoir vu son travail, pas un score qu'on vient
/// consulter (UI_SCREENS_SPEC.md S08).
class ShortlistScreen extends StatelessWidget {
  const ShortlistScreen({this.declaredTripCostFcfa, super.key});

  /// Déclaré par l'utilisateur. Sans lui, aucun compteur : on n'invente pas
  /// de moyenne, et un compteur soupçonné d'être gonflé détruit la confiance
  /// qu'il est censé construire.
  final int? declaredTripCostFcfa;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return BlocBuilder<ShortlistCubit, ShortlistState>(
      builder: (context, state) {
        if (state.saved.isEmpty) return const _Empty();

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.md,
                      Space.sm,
                      Space.md,
                      Space.xs,
                    ),
                    child: Text(
                      'Ma liste · ${state.saved.length}',
                      style: AppText.titleL.copyWith(color: p.inkStrong),
                    ),
                  ),

                  // Le Duel n'apparaît qu'à partir de 2 biens gardés — et le
                  // Conseil de famille avec lui : on ne demande pas un avis
                  // sur un bien unique, on le demande sur un choix.
                  if (state.canDuel)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.md,
                        vertical: Space.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => DuelScreen(
                                    a: state.saved[0],
                                    b: state.saved[1],
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(
                                  0,
                                  Touch.target(p.isHighContrast),
                                ),
                              ),
                              icon: const Icon(Icons.compare_arrows),
                              label: const Text('Comparer'),
                            ),
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => FamilyCouncilScreen(
                                    items: [
                                      for (final l in state.saved)
                                        CouncilItem(
                                          title: l.propertyType,
                                          quartier: l.neighborhood ?? l.city,
                                          rent: l.monthlyRentFcfa,
                                          entryCost:
                                              l.totalMoveInCostFcfa ??
                                              l.monthlyRentFcfa,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(
                                  0,
                                  Touch.target(p.isHighContrast),
                                ),
                              ),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Demander un avis'),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: Space.md),
                      itemExtent: Sizes.listingCardHeight + Space.feedGap,
                      itemCount: state.saved.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: Space.feedGap),
                        child: ListingCard(
                          listing: state.saved[i],
                          isSaved: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ListingDetailScreen(listing: state.saved[i]),
                            ),
                          ),
                          onSave: () => context.read<ShortlistCubit>().remove(
                            state.saved[i].id,
                          ),
                        ),
                      ),
                    ),
                  ),

                  _Savings(
                    tours: state.completedTours,
                    passesPaid: state.purchasedPasses * 1000,
                    tripCost: declaredTripCostFcfa,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// « Toujours une action. Jamais un cul-de-sac. »
class _Empty extends StatelessWidget {
  const _Empty();

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
            'Garde un bien ici pour le comparer plus tard.',
            style: AppText.titleM.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Touche le cœur sur un logement qui te plaît.',
            style: AppText.bodyL.copyWith(color: p.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Le compteur d'économies. N'existe QUE si l'utilisateur a déclaré son coût
/// de déplacement, et seulement si le net est positif : rien à célébrer
/// quand on a dépensé plus qu'économisé, alors on se tait.
class _Savings extends StatelessWidget {
  const _Savings({
    required this.tours,
    required this.passesPaid,
    required this.tripCost,
  });

  final int tours;
  final int passesPaid;
  final int? tripCost;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (tripCost == null || tours == 0) return const SizedBox.shrink();

    final net = tours * tripCost! - passesPaid;
    if (net <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(Space.md),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: const BorderRadius.all(Radii.card),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, color: p.success, size: 20),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu as économisé ${MoneyFcfa.short(net)} ce mois-ci',
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$tours visites faites depuis chez toi',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
