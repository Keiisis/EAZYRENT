import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// S18 — « Ce bien n'est plus libre » + confirmation.
///
/// F2 reposait sur un bouton sans écran de retour ni de récompense.
///
/// Le signalement est le seul mécanisme qui tient la fraîcheur du parc à
/// l'échelle : aucune équipe ne peut rappeler 4 000 bailleurs chaque semaine.
/// Mais personne ne signale par civisme. On signale parce que ça rapporte
/// quelque chose TOUT DE SUITE — d'où l'écran de confirmation, qui n'est pas
/// une politesse mais la moitié du mécanisme.
///
/// La récompense est immédiate et concrète : la visite est rendue. Un
/// « merci » seul aurait produit un signalement, puis plus jamais.
class ReportListingScreen extends StatefulWidget {
  const ReportListingScreen({
    required this.listingTitle,
    this.tourWasPaid = false,
    super.key,
  });

  final String listingTitle;

  /// Détermine la récompense affichée : rendre une visite payée est concret,
  /// promettre un crédit à quelqu'un qui n'a rien payé serait creux.
  final bool tourWasPaid;

  @override
  State<ReportListingScreen> createState() => _ReportListingScreenState();
}

class _ReportListingScreenState extends State<ReportListingScreen> {
  String? _reason;
  bool _sent = false;

  static const _reasons = {
    'taken': 'Déjà loué',
    'price': 'Le prix demandé n\'est pas celui de l\'annonce',
    'unreachable': 'Personne ne répond depuis plusieurs jours',
    'wrong': 'Le bien ne correspond pas aux photos',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          _sent ? 'Merci' : 'Signaler ce bien',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _sent ? _confirmation(context) : _form(context),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final p = context.palette;

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Text(
          widget.listingTitle,
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),
        const SizedBox(height: Space.xs),
        Text(
          'Que s\'est-il passé ?',
          style: AppText.titleL.copyWith(color: p.inkStrong),
        ),
        const SizedBox(height: Space.md),

        for (final r in _reasons.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: InkWell(
              onTap: () => setState(() => _reason = r.key),
              borderRadius: const BorderRadius.all(Radii.card),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: Touch.target(p.isHighContrast),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.sm,
                  vertical: Space.xs,
                ),
                decoration: BoxDecoration(
                  color: p.surfaceRaised,
                  border: Border.all(
                    color: _reason == r.key ? p.action : p.lineHair,
                    width: _reason == r.key ? 1.5 : 1,
                  ),
                  borderRadius: const BorderRadius.all(Radii.card),
                ),
                child: Row(
                  children: [
                    Icon(
                      _reason == r.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: _reason == r.key ? p.action : p.inkFaint,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        r.value,
                        style: AppText.bodyL.copyWith(color: p.inkStrong),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: Space.lg),
        FilledButton(
          onPressed: _reason == null
              ? null
              : () => setState(() => _sent = true),
          style: FilledButton.styleFrom(
            minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
          ),
          child: const Text('Envoyer le signalement'),
        ),
        const SizedBox(height: Space.xs),
        Text(
          'Le bailleur est recontacté dans la journée. Ton nom ne lui est '
          'jamais transmis.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: p.inkMuted),
        ),
      ],
    );
  }

  /// La micro-victoire. Elle dit ce que le geste a produit POUR LES AUTRES
  /// (le bien sort des résultats) et POUR SOI (la visite est rendue). Les
  /// deux, dans cet ordre : le premier donne le sens, le second la raison de
  /// recommencer.
  Widget _confirmation(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 48, color: p.success),
          const SizedBox(height: Space.md),
          Text(
            'Le bien est retiré des résultats.',
            style: AppText.titleL.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Personne d\'autre ne perdra un déplacement pour ce logement '
            'aujourd\'hui.',
            style: AppText.bodyL.copyWith(color: p.inkMuted),
          ),

          const SizedBox(height: Space.lg),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: p.surfaceSunken,
              borderRadius: const BorderRadius.all(Radii.card),
            ),
            child: Row(
              children: [
                Icon(
                  widget.tourWasPaid
                      ? Icons.confirmation_number_outlined
                      : Icons.notifications_active_outlined,
                  color: p.success,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    widget.tourWasPaid
                        ? 'Ta visite t\'est rendue. Elle est de nouveau '
                              'disponible dans tes crédits.'
                        : 'On te préviendra en premier si un bien semblable '
                              'sort dans ce quartier.',
                    style: AppText.bodyL.copyWith(color: p.inkStrong),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
            ),
            child: const Text('Continuer à chercher'),
          ),
        ],
      ),
    );
  }
}
