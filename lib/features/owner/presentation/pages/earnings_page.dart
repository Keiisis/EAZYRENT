import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';

/// C6 — Encaissements.
///
/// Le dernier maillon du parcours propriétaire : publier → être vu → recevoir
/// une demande → encaisser. Sans cet écran, le bailleur ne sait pas si son
/// loyer est arrivé, et il retourne aux espèces.
///
/// LA COMMISSION EST AFFICHÉE EN CLAIR, ligne par ligne. La cacher dans un
/// net global serait le meilleur moyen de perdre la confiance d'un bailleur
/// béninois — habitué à des intermédiaires dont il ne comprend jamais les
/// prélèvements. On montre le brut, le prélèvement, et le net.
class OwnerEarningsScreen extends StatelessWidget {
  const OwnerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Démonstration tant que le module owner n'a pas sa couche data.
    const received = 145000;
    const pending = 35000;
    const late = 0;

    const movements = [
      _Movement(
        'Loyer mars · Chambre-salon Fidjrossè',
        45000,
        _Kind.rent,
        '12 mars',
      ),
      _Movement('Commission EAZYRENT', -4500, _Kind.fee, '12 mars'),
      _Movement('Loyer mars · Studio Godomey', 25000, _Kind.rent, '1 mars'),
      _Movement('Commission EAZYRENT', -2500, _Kind.fee, '1 mars'),
    ];

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Encaissements',
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
                  MoneyFcfa.short(received),
                  style: AppText.displayL.copyWith(color: p.inkStrong),
                ),
                Text(
                  'reçus ce mois-ci',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),

                const SizedBox(height: Space.md),
                Row(
                  children: [
                    _Side(
                      label: 'En attente',
                      value: MoneyFcfa.short(pending),
                      color: p.warn,
                    ),
                    const SizedBox(width: Space.sm),
                    _Side(
                      label: 'Retard',
                      value: late == 0 ? 'Aucun' : MoneyFcfa.short(late),
                      color: late == 0 ? p.success : p.danger,
                    ),
                  ],
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'MOUVEMENTS',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                for (final m in movements) _MovementRow(movement: m),

                const SizedBox(height: Space.lg),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast)),
                  ),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Exporter mes états'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Kind { rent, fee }

class _Movement {
  const _Movement(this.label, this.amount, this.kind, this.date);
  final String label;
  final int amount;
  final _Kind kind;
  final String date;
}

class _Side extends StatelessWidget {
  const _Side({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: const BorderRadius.all(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.label.copyWith(color: p.inkMuted)),
            Text(
              value,
              style: AppText.bodyL.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: Fonts.tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final _Movement movement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isFee = movement.kind == _Kind.fee;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.label,
                  style: AppText.bodyL.copyWith(
                    // La commission est visible mais discrète : on ne la cache
                    // pas, on ne la met pas en avant non plus.
                    color: isFee ? p.inkMuted : p.inkStrong,
                  ),
                ),
                Text(
                  movement.date,
                  style: AppText.caption.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
          Text(
            '${movement.amount > 0 ? '' : '−'}'
            '${MoneyFcfa.short(movement.amount.abs())}',
            style: AppText.bodyL.copyWith(
              color: isFee ? p.inkMuted : p.success,
              fontWeight: FontWeight.w600,
              fontFeatures: Fonts.tabular,
            ),
          ),
          if (!isFee) ...[
            const SizedBox(width: Space.xs),
            Icon(Icons.check_circle, size: 16, color: p.success),
          ],
        ],
      ),
    );
  }
}
