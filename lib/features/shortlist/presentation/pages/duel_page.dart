import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/domain/entities/listing.dart';

/// S09 — Le Duel.
///
/// DEUX biens à la fois, jamais un tableau à cinq colonnes. Au-delà de deux
/// options simultanées, la décision se bloque (loi de Hick). Le duel force
/// une préférence à chaque tour, exactement comme on choisit dans la vraie
/// vie : par élimination, pas par tableur.
///
/// RÈGLE VISUELLE CENTRALE : les lignes où les deux biens DIFFÈRENT sont en
/// texte foncé et en gras ; les lignes identiques sont atténuées. On ne
/// compare que ce qui distingue.
class DuelScreen extends StatelessWidget {
  const DuelScreen({required this.a, required this.b, super.key});

  final Listing a;
  final Listing b;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Lequel tu gardes ?',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _Head(listing: a)),
                            const SizedBox(width: Space.sm),
                            Expanded(child: _Head(listing: b)),
                          ],
                        ),
                        const SizedBox(height: Space.md),

                        _CompareRow(
                          label: 'Entrée',
                          left: a.totalMoveInCostFcfa == null
                              ? '—'
                              : MoneyFcfa.short(a.totalMoveInCostFcfa!),
                          right: b.totalMoveInCostFcfa == null
                              ? '—'
                              : MoneyFcfa.short(b.totalMoveInCostFcfa!),
                        ),
                        _CompareRow(
                          label: 'Avance',
                          left: '${a.advanceMonths ?? 0} mois',
                          right: '${b.advanceMonths ?? 0} mois',
                        ),
                        _CompareRow(
                          label: 'Fraîcheur',
                          left: a.freshness.label,
                          right: b.freshness.label,
                        ),
                        _CompareRow(
                          label: 'Visite 360',
                          left: a.hasVerifiedTour ? 'Oui' : 'Non',
                          right: b.hasVerifiedTour ? 'Oui' : 'Non',
                        ),
                        _CompareRow(
                          label: 'Quartier',
                          left: a.locationLabel,
                          right: b.locationLabel,
                        ),
                      ],
                    ),
                  ),
                ),
                _Choices(a: a, b: b),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radii.card),
            child: listing.mainImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: listing.mainImageUrl!,
                    fit: BoxFit.cover,
                  )
                : ColoredBox(color: p.surfaceSunken),
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(
          MoneyFcfa.short(listing.monthlyRentFcfa),
          style: AppText.amount.copyWith(color: p.inkStrong),
        ),
        Text(
          listing.locationLabel,
          style: AppText.bodyM.copyWith(color: p.inkMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Le cœur du Duel : ce qui est identique s'efface, ce qui diffère ressort.
class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.left,
    required this.right,
  });

  final String label;
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final differs = left != right;

    final style = AppText.bodyM.copyWith(
      color: differs ? p.inkStrong : p.inkFaint,
      fontWeight: differs ? FontWeight.w600 : FontWeight.w400,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: p.inkMuted)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(left, style: style)),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(right, style: style)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.a, required this.b});

  final Listing a;
  final Listing b;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    void finish(String winnerLabel) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // « Ton finaliste » — la liste devient une décision.
          content: Text('Ton finaliste : le bien de $winnerLabel'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(color: p.surfaceRaised, boxShadow: p.shadowBar),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => finish(a.locationLabel),
                    child: const Text('Je garde A'),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => finish(b.locationLabel),
                    child: const Text('Je garde B'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xxs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Les deux'),
                ),
                Text('·', style: TextStyle(color: p.inkMuted)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aucun des deux'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
