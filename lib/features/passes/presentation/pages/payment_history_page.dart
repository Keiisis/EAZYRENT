import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';

/// S24 — Historique de paiements et reçus.
///
/// « On prend de l'argent sans en donner la trace. »
/// (SCREEN_ROLE_MATRIX.md, écran manquant n°24)
///
/// Sur un marché où le paiement mobile laisse un SMS opérateur mais rien du
/// côté du marchand, la trace côté marchand est le produit. Chaque ligne
/// porte l'opérateur, le numéro tronqué et une référence — c'est ce qu'on
/// cite au support quand un débit passe et que le service ne s'ouvre pas.
class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Démonstration tant que le module passes n'a pas sa couche data.
    const payments = [
      _Payment(
        label: '3 visites 360',
        amount: 2500,
        operator: 'MTN MoMo',
        masked: '•• 34 56',
        date: '12 mars, 14h02',
        reference: 'EZR-8K42P',
        ok: true,
      ),
      _Payment(
        label: '1 visite 360',
        amount: 1000,
        operator: 'Moov Flooz',
        masked: '•• 78 90',
        date: '2 mars, 09h41',
        reference: 'EZR-7B19M',
        ok: true,
      ),
      _Payment(
        label: '1 visite 360',
        amount: 1000,
        operator: 'MTN MoMo',
        masked: '•• 34 56',
        date: '28 février, 20h15',
        reference: 'EZR-6X03D',
        ok: false,
      ),
    ];

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Historique de paiements',
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
                for (final pay in payments) _PaymentRow(payment: pay),
                const SizedBox(height: Space.lg),
                Text(
                  'Un paiement débité qui n\'a rien ouvert est remboursé sous '
                  '48 h. Cite la référence au support, elle suffit.',
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

class _Payment {
  const _Payment({
    required this.label,
    required this.amount,
    required this.operator,
    required this.masked,
    required this.date,
    required this.reference,
    required this.ok,
  });

  final String label;
  final int amount;
  final String operator;
  final String masked;
  final String date;
  final String reference;
  final bool ok;
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final _Payment payment;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pay = payment;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.xs),
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
            children: [
              Expanded(
                child: Text(
                  pay.label,
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                MoneyFcfa.short(pay.amount),
                style: AppText.bodyL.copyWith(
                  color: pay.ok ? p.inkStrong : p.inkMuted,
                  fontWeight: FontWeight.w700,
                  fontFeatures: Fonts.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(
            '${pay.operator} ${pay.masked} · ${pay.date}',
            style: AppText.bodyM.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.xxs),
          Row(
            children: [
              Icon(
                pay.ok ? Icons.check_circle : Icons.error_outline,
                size: 15,
                color: pay.ok ? p.success : p.danger,
              ),
              const SizedBox(width: Space.xxs),
              Text(
                pay.ok ? 'Payé' : 'Échoué — non débité',
                style: AppText.label.copyWith(
                  color: pay.ok ? p.success : p.danger,
                ),
              ),
              const Spacer(),
              // La référence est sélectionnable : elle sert à parler au
              // support, pas à décorer.
              SelectableText(
                pay.reference,
                style: AppText.caption.copyWith(
                  color: p.inkMuted,
                  fontFeatures: Fonts.tabular,
                ),
              ),
            ],
          ),
          if (pay.ok) ...[
            const SizedBox(height: Space.xs),
            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, Touch.target(p.isHighContrast)),
              ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Télécharger le reçu'),
            ),
          ],
        ],
      ),
    );
  }
}
