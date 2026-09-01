import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';

/// D4 — Mes commissions.
///
/// Le dernier maillon du parcours démarcheur : apporter → suivre → encaisser
/// → retirer.
///
/// « Un apporteur payé en retard part, et il en parle. »
/// (GROWTH_MONETISATION.md §6). Cet écran existe pour que le retard ne soit
/// jamais une surprise : le délai de retrait est écrit, et le montant
/// disponible est distinct du montant en attente de validation.
///
/// Confondre les deux — afficher un total flatteur dont la moitié n'est pas
/// retirable — est le meilleur moyen de perdre celui qui alimente le stock.
class CommissionsScreen extends StatelessWidget {
  const CommissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Démonstration tant que le module broker n'a pas sa couche data.
    const available = 12000;
    const pending = 3000;

    const movements = [
      _Move('Bien loué · Chambre-salon Fidjrossè', 3000, '12 mars', _Kind.gain),
      _Move(
        'Bien publié · Chambre-salon Fidjrossè',
        1000,
        '8 mars',
        _Kind.gain,
      ),
      _Move('Bien publié · Studio Akpakpa', 1000, '5 mars', _Kind.gain),
      _Move('Retrait vers +229 97 12 34 56', 8000, '5 mars', _Kind.withdrawal),
    ];

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Mes commissions',
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
                // Le disponible d'abord, en grand. Le montant en attente est
                // secondaire et ne se confond jamais avec lui.
                Text(
                  MoneyFcfa.short(available),
                  style: AppText.displayL.copyWith(color: p.success),
                ),
                Text(
                  'disponibles maintenant',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xxs),
                Row(
                  children: [
                    Icon(Icons.hourglass_empty, size: 15, color: p.warn),
                    const SizedBox(width: Space.xxs),
                    Text(
                      '${MoneyFcfa.short(pending)} en attente de validation',
                      style: AppText.bodyM.copyWith(color: p.warn),
                    ),
                  ],
                ),

                const SizedBox(height: Space.lg),
                FilledButton.icon(
                  onPressed: available > 0 ? () {} : null,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: Text('Retirer ${MoneyFcfa.short(available)}'),
                ),
                const SizedBox(height: Space.xs),
                // Le délai est ÉCRIT. Un engagement de délai vaut mieux qu'un
                // silence, même quand le délai est de 24 h.
                Center(
                  child: Text(
                    'Les retraits partent sous 24 h, sur MTN MoMo ou Moov Flooz.',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: p.inkMuted),
                  ),
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'HISTORIQUE',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                for (final m in movements) _MoveRow(move: m),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Kind { gain, withdrawal }

class _Move {
  const _Move(this.label, this.amount, this.date, this.kind);
  final String label;
  final int amount;
  final String date;
  final _Kind kind;
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.move});

  final _Move move;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isGain = move.kind == _Kind.gain;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        children: [
          Icon(
            isGain ? Icons.add_circle_outline : Icons.arrow_outward,
            size: 18,
            color: isGain ? p.success : p.inkMuted,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  move.label,
                  style: AppText.bodyL.copyWith(color: p.inkStrong),
                ),
                Text(
                  move.date,
                  style: AppText.caption.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
          Text(
            '${isGain ? '+' : '−'}${MoneyFcfa.short(move.amount)}',
            style: AppText.bodyL.copyWith(
              color: isGain ? p.success : p.inkMuted,
              fontWeight: FontWeight.w700,
              fontFeatures: Fonts.tabular,
            ),
          ),
        ],
      ),
    );
  }
}
