import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';

/// Mes quittances.
///
/// La quittance est le seul objet du produit qui a une valeur EN DEHORS de
/// l'application : elle sert à ouvrir un compte, à obtenir un crédit, à
/// prouver une domiciliation. C'est pour cela qu'elle est téléchargeable ET
/// partageable, et que le bouton de partage est aussi visible que celui de
/// téléchargement — au Bénin, on envoie un document, on ne le classe pas.
///
/// Chaque quittance porte le nom du bailleur et l'adresse : une quittance
/// anonyme ne prouve rien à un guichet.
class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Démonstration tant que le module tenancy n'a pas sa couche data.
    const receipts = [
      _Receipt('Février 2026', 45000, '3 février', 'MTN MoMo'),
      _Receipt('Janvier 2026', 45000, '4 janvier', 'MTN MoMo'),
      _Receipt('Décembre 2025', 45000, '2 décembre', 'Moov Flooz'),
    ];

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Mes quittances',
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
                  'Chambre-salon · Fidjrossè\nBailleur : Mensah A.',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.md),
                for (final r in receipts) _ReceiptCard(receipt: r),
                const SizedBox(height: Space.lg),
                Text(
                  'Une quittance vaut preuve de paiement et de domiciliation. '
                  'Elle reste disponible même après la fin du bail.',
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

class _Receipt {
  const _Receipt(this.month, this.amount, this.paidOn, this.channel);
  final String month;
  final int amount;
  final String paidOn;
  final String channel;
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});

  final _Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = receipt;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
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
            children: [
              Icon(Icons.check_circle, size: 18, color: p.success),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(
                  'Loyer de ${r.month.toLowerCase()}',
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                MoneyFcfa.short(r.amount),
                style: AppText.bodyL.copyWith(
                  color: p.inkStrong,
                  fontWeight: FontWeight.w700,
                  fontFeatures: Fonts.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(
            'Payé le ${r.paidOn} · ${r.channel}',
            style: AppText.bodyM.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              // Partager AVANT télécharger : ici, un document se transmet.
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast)),
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Partager'),
                ),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast)),
                  ),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
