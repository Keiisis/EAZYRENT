import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';

/// S16 — Mes passes et crédits.
///
/// On vendait des crédits sans lieu pour les voir. Un crédit acheté qu'on ne
/// retrouve pas est un crédit perdu, et un remboursement demandé.
///
/// Deux règles tenues ici :
///   · CE QUI RESTE EST AFFICHÉ AVANT CE QU'ON PEUT ACHETER. L'écran sert
///     d'abord à rassurer, ensuite à vendre. L'inverse serait une boutique
///     déguisée en compte.
///   · LA DATE D'EXPIRATION EST ÉCRITE, même quand elle est lointaine. Un
///     crédit qui expire sans prévenir détruit plus de confiance que le
///     montant qu'il représente.
class PassesScreen extends StatelessWidget {
  const PassesScreen({this.remaining = 0, super.key});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Mes passes et crédits',
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
                Container(
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: const BorderRadius.all(Radii.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$remaining',
                        style: AppText.displayL.copyWith(
                          color: remaining > 0 ? p.success : p.inkStrong,
                          fontFeatures: Fonts.tabular,
                        ),
                      ),
                      Text(
                        remaining > 1
                            ? 'visites 360 disponibles'
                            : 'visite 360 disponible',
                        style: AppText.bodyL.copyWith(color: p.inkMuted),
                      ),
                      if (remaining > 0) ...[
                        const SizedBox(height: Space.xs),
                        Text(
                          'Valables jusqu\'au 31 décembre. Aucune expiration '
                          'avant cette date.',
                          style: AppText.bodyM.copyWith(color: p.inkMuted),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'RECHARGER',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),

                // Les mêmes trois offres que le paywall, dans le même ordre.
                // Un prix qui change de place entre deux écrans se lit comme
                // un prix qui change.
                const _Offer(count: 1, price: 1000, note: 'Une visite'),
                const _Offer(
                  count: 3,
                  price: 2500,
                  note: 'Trois visites · 833 F l\'unité',
                  best: true,
                ),
                const _Offer(
                  count: 10,
                  price: 7000,
                  note: 'Dix visites · 700 F l\'unité',
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'Un crédit est débité au moment où la visite s\'ouvre, pas '
                  'à l\'achat. Une visite interrompue par le réseau n\'est '
                  'jamais recomptée.',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({
    required this.count,
    required this.price,
    required this.note,
    this.best = false,
  });

  final int count;
  final int price;
  final String note;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: InkWell(
        onTap: () {},
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          constraints: BoxConstraints(
            minHeight: Touch.target(p.isHighContrast) + 8,
          ),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            border: Border.all(color: best ? p.action : p.lineHair, width: 1.5),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$count visite${count > 1 ? 's' : ''} 360',
                          style: AppText.bodyL.copyWith(
                            color: p.inkStrong,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (best) ...[
                          const SizedBox(width: Space.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.action,
                              borderRadius: const BorderRadius.all(Radii.pill),
                            ),
                            child: Text(
                              'Le plus pris',
                              style: AppText.caption.copyWith(
                                color: p.actionOnFill,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      note,
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
              // Le montant est sur la ligne, pas caché derrière un tap.
              Text(
                MoneyFcfa.short(price),
                style: AppText.titleM.copyWith(
                  color: p.inkStrong,
                  fontFeatures: Fonts.tabular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
