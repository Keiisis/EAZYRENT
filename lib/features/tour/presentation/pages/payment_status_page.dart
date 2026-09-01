import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';

/// Les deux états d'un paiement Mobile Money : l'attente, puis l'échec.
///
/// C'EST L'ÉCRAN LE PLUS CHER DU PRODUIT. Sur Mobile Money, le paiement se
/// termine AILLEURS que dans l'application : dans une fenêtre système de
/// l'opérateur, qui parfois ne s'affiche pas. Une application qui se contente
/// d'un rond qui tourne laisse la personne devant un téléphone muet, avec la
/// certitude d'avoir perdu 1 000 F.
///
/// Trois choses portent tout l'écran :
///
///   1. LE CODE DE SECOURS (`*880*6#`). C'est la réponse à « rien ne
///      s'affiche », qui est le cas le plus fréquent. Le cacher dans une aide
///      revient à ne pas l'avoir.
///   2. « RIEN N'EST DÉBITÉ TANT QUE TU N'AS PAS TAPÉ TON CODE SECRET. »
///      La peur ici n'est pas d'échouer, c'est d'être débité pour rien.
///   3. À L'ÉCHEC, ON DIT QUE RIEN N'A ÉTÉ PRIS, et on propose l'AUTRE
///      opérateur. Un échec MTN est très souvent un problème de réseau MTN,
///      pas un problème d'argent.
enum MomoOperator {
  mtn('MTN MoMo', '*880*6#'),
  moov('Moov Flooz', '*855#'),
  celtiis('Celtiis Cash', '*800#');

  const MomoOperator(this.label, this.ussd);
  final String label;
  final String ussd;
}

class PaymentStatusScreen extends StatefulWidget {
  const PaymentStatusScreen({
    required this.amountFcfa,
    required this.operator,
    super.key,
  });

  final int amountFcfa;
  final MomoOperator operator;

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  /// Deux minutes. C'est le délai réel d'expiration d'une demande MoMo au
  /// Bénin — pas un chiffre rond choisi pour faire joli. Afficher un compte à
  /// rebours plus court ferait abandonner des paiements qui allaient aboutir.
  static const _window = Duration(minutes: 2);

  late Duration _left = _window;
  Timer? _timer;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    setState(() {
      _left = _window;
      _failed = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left -= const Duration(seconds: 1));
      if (_left.inSeconds <= 0) {
        t.cancel();
        setState(() => _failed = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        automaticallyImplyLeading: false,
        title: Text(
          widget.operator.label,
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: _failed ? _failure(context) : _waiting(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _waiting(BuildContext context) {
    final p = context.palette;
    final mm = _left.inMinutes;
    final ss = (_left.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),

        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: p.warn),
            ),
            const SizedBox(width: Space.sm),
            Text(
              'En attente · $mm:$ss',
              style: AppText.titleM.copyWith(
                color: p.warn,
                fontFeatures: Fonts.tabular,
              ),
            ),
          ],
        ),

        const SizedBox(height: Space.md),
        Text(
          'Regarde ton téléphone.',
          style: AppText.displayM.copyWith(color: p.inkStrong),
        ),
        const SizedBox(height: Space.xs),
        Text.rich(
          TextSpan(
            text: 'Valide le paiement de ',
            style: AppText.bodyL.copyWith(color: p.inkMuted),
            children: [
              TextSpan(
                text: MoneyFcfa.short(widget.amountFcfa),
                style: AppText.bodyL.copyWith(
                  color: p.inkStrong,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: ' sur la fenêtre ${widget.operator.label}.'),
            ],
          ),
        ),

        const SizedBox(height: Space.lg),
        // LE CODE DE SECOURS. La réponse au cas le plus fréquent — « rien ne
        // s'affiche » — doit être sur l'écran, en gros, pas dans une aide.
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
                'Rien ne s\'affiche ?',
                style: AppText.bodyL.copyWith(
                  color: p.inkStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  SelectableText(
                    widget.operator.ussd,
                    style: AppText.amount.copyWith(
                      color: p.inkStrong,
                      fontFeatures: Fonts.tabular,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'Compose ce code pour approuver.',
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: Space.md),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: p.success),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                'Rien n\'est débité tant que tu n\'as pas tapé ton code '
                'secret.',
                style: AppText.bodyL.copyWith(color: p.success),
              ),
            ),
          ],
        ),

        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            minimumSize: Size(double.infinity, Touch.target(p.isHighContrast)),
            foregroundColor: p.inkMuted,
          ),
          child: const Text('Annuler la demande'),
        ),
      ],
    );
  }

  Widget _failure(BuildContext context) {
    final p = context.palette;
    final other = widget.operator == MomoOperator.mtn
        ? MomoOperator.moov
        : MomoOperator.mtn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),

        Icon(Icons.error_outline, size: 44, color: p.danger),
        const SizedBox(height: Space.md),
        Text(
          'Le paiement n\'a pas abouti.',
          style: AppText.displayM.copyWith(color: p.inkStrong),
        ),
        const SizedBox(height: Space.xs),
        // LA phrase. La crainte n'est pas l'échec, c'est d'avoir payé pour
        // rien — on y répond avant toute proposition de réessai.
        Text(
          'Aucun montant n\'a été débité de ton compte.',
          style: AppText.titleM.copyWith(color: p.success),
        ),
        const SizedBox(height: Space.xs),
        Text(
          'Délai dépassé, ou demande refusée par le réseau.',
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),

        const Spacer(),

        FilledButton(
          onPressed: _tick,
          style: FilledButton.styleFrom(
            minimumSize: Size(
              double.infinity,
              Touch.target(p.isHighContrast) + 8,
            ),
          ),
          child: Text('Réessayer avec ${widget.operator.label}'),
        ),
        const SizedBox(height: Space.xs),
        // L'AUTRE opérateur, proposé d'emblée. Un échec MTN est très souvent
        // un incident réseau MTN, pas un problème d'argent : proposer Moov
        // sauve le paiement au lieu de le reporter à demain.
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, Touch.target(p.isHighContrast)),
          ),
          child: Text('Essayer avec ${other.label}'),
        ),
      ],
    );
  }
}
