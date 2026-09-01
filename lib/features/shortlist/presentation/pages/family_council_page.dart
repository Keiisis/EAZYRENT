import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';

/// S13 — Conseil de famille.
///
/// « La décision de logement est collective au Bénin (conjoint, parents, aîné
/// de la famille) — un produit qui l'ignore fait décider l'utilisateur hors
/// de l'app. » (UI_SCREENS_SPEC.md §S13, FEATURES_V2.md F5)
///
/// Deux effets simultanés, et le second n'est pas un bonus : chaque partage
/// expose l'application à une personne QUALIFIÉE — quelqu'un à qui on demande
/// son avis sur un logement est quelqu'un qui en cherche, en loue, ou en
/// possède.
///
/// Le destinataire ouvre une page web légère. AUCUNE INSTALLATION EXIGÉE :
/// demander une installation à un aîné de 60 ans pour qu'il donne son avis,
/// c'est perdre l'avis et le partage.
class FamilyCouncilScreen extends StatelessWidget {
  const FamilyCouncilScreen({required this.items, super.key});

  final List<CouncilItem> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enough = items.length >= 2;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Demander un avis',
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
                  enough
                      ? 'Qui décide avec toi ?'
                      : 'Garde au moins deux biens',
                  style: AppText.titleL.copyWith(color: p.inkStrong),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  enough
                      ? 'Envoie ces ${items.length} biens sur WhatsApp. La '
                            'personne vote en un geste, sans rien installer.'
                      : 'Un avis se demande sur un choix, pas sur un bien '
                            'unique. Garde-en un deuxième et reviens.',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),

                const SizedBox(height: Space.lg),
                for (final item in items) _ItemRow(item: item),

                if (enough) ...[
                  const SizedBox(height: Space.lg),
                  FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Partager sur WhatsApp'),
                  ),
                  const SizedBox(height: Space.xs),
                  OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast)),
                    ),
                    icon: const Icon(Icons.link),
                    label: const Text('Copier le lien'),
                  ),
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
                          'Ce que la personne verra',
                          style: AppText.bodyL.copyWith(
                            color: p.inkStrong,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Space.xxs),
                        Text(
                          'Les photos, le loyer, le coût d\'entrée et le '
                          'quartier de chaque bien. Ni ton numéro, ni ton '
                          'budget, ni tes autres recherches.',
                          style: AppText.bodyM.copyWith(color: p.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    'Le lien expire dans 7 jours. Les votes reviennent ici.',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: p.inkMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CouncilItem {
  const CouncilItem({
    required this.title,
    required this.quartier,
    required this.rent,
    required this.entryCost,
    this.votes = 0,
  });

  final String title;
  final String quartier;
  final int rent;
  final int entryCost;
  final int votes;
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final CouncilItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.xs),
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        border: Border.all(color: p.lineHair),
        borderRadius: const BorderRadius.all(Radii.card),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.surfaceSunken,
              borderRadius: const BorderRadius.all(Radii.chip),
            ),
            child: Icon(Icons.home_outlined, color: p.inkFaint),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.title} · ${item.quartier}',
                  style: AppText.bodyL.copyWith(color: p.inkStrong),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${MoneyFcfa.short(item.rent)}/mois · entrée '
                  '${MoneyFcfa.short(item.entryCost)}',
                  style: AppText.bodyM.copyWith(
                    color: p.inkMuted,
                    fontFeatures: Fonts.tabular,
                  ),
                ),
              ],
            ),
          ),
          if (item.votes > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.surfaceSunken,
                borderRadius: const BorderRadius.all(Radii.pill),
              ),
              child: Text(
                '${item.votes} ♥',
                style: AppText.label.copyWith(color: p.success),
              ),
            ),
        ],
      ),
    );
  }
}
