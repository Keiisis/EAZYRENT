import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/domain/entities/listing.dart';
import '../pages/payment_status_page.dart';

/// S07 — Le déblocage.
///
/// Cinq décisions y sont figées, toutes issues de GROWTH_MONETISATION.md §3
/// et de la psychologie de prix :
///   1. TROIS options exactement. Une quatrième échoue la revue (paradoxe du
///      choix). L'option médiane est la cible, l'option haute la rend évidente.
///   2. L'ancrage affiche le coût de déplacement DÉCLARÉ PAR L'UTILISATEUR,
///      jamais une moyenne inventée.
///   3. Les deux garanties sont posées AVANT le paiement — on évite l'abandon
///      au lieu de le réparer.
///   4. Le montant est DANS le bouton. « Continuer » sur un écran de paiement
///      est une trahison.
///   5. Ni Wave ni Orange : ils n'opèrent pas au Bénin.
class PaywallSheet extends StatefulWidget {
  const PaywallSheet({
    required this.listing,
    this.declaredTripCostFcfa,
    super.key,
  });

  final Listing listing;

  /// Déclaré par l'utilisateur à l'onboarding. `null` tant qu'il n'a pas
  /// répondu — dans ce cas la ligne d'ancrage n'existe pas. On n'invente pas.
  final int? declaredTripCostFcfa;

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

enum _Operator { mtn, moov, celtiis }

class _Offer {
  const _Offer(this.label, this.visits, this.priceFcfa, {this.badge});
  final String label;
  final int visits;
  final int priceFcfa;
  final String? badge;

  int get unitPrice => priceFcfa ~/ visits;
}

class _PaywallSheetState extends State<PaywallSheet> {
  static const _offers = [
    _Offer('1 visite', 1, 1000),
    _Offer('Pack Quartier · 3 visites', 3, 2500, badge: 'ÉCONOMIE'),
    _Offer('Pack Chasseur · 7 visites', 7, 5000),
  ];

  // La cible est l'option médiane : elle correspond au comportement réel,
  // on compare trois biens.
  int _selected = 1;
  _Operator? _operator;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final offer = _offers[_selected];

    return Container(
      decoration: BoxDecoration(
        color: p.surfaceOverlay,
        borderRadius: const BorderRadius.vertical(top: Radii.sheet),
        boxShadow: Elevation.sheet,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Grabber(color: p.lineStrong),
              const SizedBox(height: Space.md),

              Text(
                'Voir tout le logement',
                style: AppText.titleL.copyWith(color: p.inkStrong),
              ),
              const SizedBox(height: Space.xs),

              // Ancrage : uniquement si l'utilisateur a déclaré son coût.
              if (widget.declaredTripCostFcfa != null) ...[
                Text(
                  'Un aller-retour te coûte '
                  '~${MoneyFcfa.short(widget.declaredTripCostFcfa!)}.',
                  style: AppText.bodyL.copyWith(color: p.inkBase),
                ),
                Text(
                  'Cette visite : ${MoneyFcfa.short(1000)}.',
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Space.md),
              ],

              for (var i = 0; i < _offers.length; i++)
                _OfferTile(
                  offer: _offers[i],
                  selected: i == _selected,
                  onTap: () => setState(() => _selected = i),
                ),

              const SizedBox(height: Space.lg),
              Text(
                'Paye avec',
                style: AppText.label.copyWith(color: p.inkMuted),
              ),
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  for (final op in _Operator.values) ...[
                    Expanded(
                      child: _OperatorTile(
                        op: op,
                        selected: _operator == op,
                        onTap: () => setState(() => _operator = op),
                      ),
                    ),
                    if (op != _Operator.values.last)
                      const SizedBox(width: Space.xs),
                  ],
                ],
              ),

              const SizedBox(height: Space.md),
              // Les deux objections réelles, levées AVANT le paiement.
              _Guarantee(
                text:
                    "Si ce bien n'est plus libre, "
                    'on te rend ta visite automatiquement.',
              ),
              _Guarantee(text: 'Accès permanent, et consultable hors-ligne.'),

              const SizedBox(height: Space.lg),
              FilledButton(
                // Le paiement Mobile Money se termine AILLEURS que dans
                // l'application : dans une fenêtre système de l'opérateur,
                // qui parfois ne s'affiche pas. L'écran d'état existe pour
                // que personne ne reste devant un téléphone muet.
                onPressed: _operator == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PaymentStatusScreen(
                            amountFcfa: offer.priceFcfa,
                            operator: switch (_operator!) {
                              _Operator.mtn => MomoOperator.mtn,
                              _Operator.moov => MomoOperator.moov,
                              _Operator.celtiis => MomoOperator.celtiis,
                            },
                          ),
                        ),
                      ),
                style: FilledButton.styleFrom(
                  minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                ),
                // Le montant est DANS le bouton.
                child: Text('Payer ${MoneyFcfa.short(offer.priceFcfa)}'),
              ),
              if (_operator == null) ...[
                const SizedBox(height: Space.xs),
                // Un bouton désactivé affiche TOUJOURS sa raison.
                Text(
                  "Choisis d'abord ton opérateur",
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: p.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radii.pill),
      ),
    ),
  );
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final _Offer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          constraints: BoxConstraints(
            minHeight: Touch.target(p.isHighContrast) + 12,
          ),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? p.action : p.lineHair,
              width: selected ? 2 : 1,
            ),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? p.action : p.inkMuted,
                size: 20,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.label,
                      style: AppText.bodyL.copyWith(color: p.inkStrong),
                    ),
                    if (offer.visits > 1)
                      Text(
                        'soit ${MoneyFcfa.short(offer.unitPrice)} la visite',
                        style: AppText.caption.copyWith(color: p.inkMuted),
                      ),
                  ],
                ),
              ),
              if (offer.badge != null) ...[
                _Badge(text: offer.badge!, color: p.success),
                const SizedBox(width: Space.xs),
              ],
              Text(
                MoneyFcfa.short(offer.priceFcfa),
                style: AppText.bodyL.copyWith(
                  color: p.inkStrong,
                  fontWeight: FontWeight.w600,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: const BorderRadius.all(Radii.chip),
    ),
    child: Text(text, style: AppText.caption.copyWith(color: color)),
  );
}

class _OperatorTile extends StatelessWidget {
  const _OperatorTile({
    required this.op,
    required this.selected,
    required this.onTap,
  });

  final _Operator op;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = {
    _Operator.mtn: 'MTN\nMoMo',
    _Operator.moov: 'Moov\nFlooz',
    _Operator.celtiis: 'Celtiis\nCash',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radii.input),
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? p.action : p.lineHair,
            width: selected ? 2 : 1,
          ),
          borderRadius: const BorderRadius.all(Radii.input),
        ),
        child: Text(
          _labels[op]!,
          textAlign: TextAlign.center,
          style: AppText.label.copyWith(color: p.inkStrong),
        ),
      ),
    );
  }
}

class _Guarantee extends StatelessWidget {
  const _Guarantee({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 15, color: p.inkMuted),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(text, style: AppText.bodyM.copyWith(color: p.inkMuted)),
          ),
        ],
      ),
    );
  }
}
