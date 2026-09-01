import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// C4 — Demander un tournage 360.
///
/// L'offre n'arrive JAMAIS à la publication : elle arrive quand le bailleur a
/// constaté la demande (C2). Ici, il l'a constatée — l'écran ne recommence
/// donc pas la démonstration, il organise le rendez-vous.
///
/// Trois décisions :
///   · LE PRIX EST RAPPELÉ AVANT LE CRÉNEAU, jamais après. Découvrir le
///     montant une fois le rendez-vous choisi se lit comme un piège.
///   · AUCUNE STATISTIQUE COMPARATIVE (« 4× plus de demandes ») tant qu'elle
///     n'est pas mesurée sur les 50 premiers biens. Le chiffre réel de vues
///     suffit et il est vrai.
///   · LE PAIEMENT SE FAIT APRÈS LE TOURNAGE. Demander 5 000 F d'avance à un
///     bailleur qui n'a encore rien vu du service, sur un marché où l'on
///     redoute d'être escroqué, coûterait plus de refus que le risque
///     d'impayé qu'on évite.
class RequestTourScreen extends StatefulWidget {
  const RequestTourScreen({
    required this.listingTitle,
    required this.views,
    super.key,
  });

  final String listingTitle;
  final int views;

  @override
  State<RequestTourScreen> createState() => _RequestTourScreenState();
}

class _RequestTourScreenState extends State<RequestTourScreen> {
  String? _slot;
  bool _sent = false;

  static const _slots = {
    'Demain, jeudi': ['08h — 10h', '14h — 16h'],
    'Vendredi': ['08h — 10h', '10h — 12h', '16h — 18h'],
    'Samedi': ['09h — 11h'],
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          _sent ? 'Tournage programmé' : 'Visite Vérifiée',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _sent ? _confirmed(context) : _form(context),
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
          'Un agent vient filmer ton bien',
          style: AppText.titleL.copyWith(color: p.inkStrong),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          '${widget.views} personnes l\'ont vu cette semaine sans pouvoir '
          'entrer. Une Visite Vérifiée leur montre les pièces avant de se '
          'déplacer.',
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),

        const SizedBox(height: Space.lg),
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: p.surfaceSunken,
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Le prix, AVANT le créneau.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tournage 360 complet',
                      style: AppText.bodyL.copyWith(color: p.inkStrong),
                    ),
                  ),
                  Text(
                    '5 000 F',
                    style: AppText.titleM.copyWith(
                      color: p.inkStrong,
                      fontFeatures: Fonts.tabular,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              _Point('Toutes les pièces, la cour et la vue depuis la porte'),
              _Point('Vérification que le bien est libre à cette date'),
              _Point('En ligne sous 48 h, sans autre frais'),
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  Icon(Icons.lock_open, size: 16, color: p.success),
                  const SizedBox(width: Space.xxs),
                  Expanded(
                    child: Text(
                      'Tu paies APRÈS le tournage, quand tu as vu le résultat.',
                      style: AppText.label.copyWith(color: p.success),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: Space.lg),
        Text(
          'QUAND L\'AGENT PEUT-IL VENIR ?',
          style: AppText.label.copyWith(color: p.inkMuted),
        ),
        const SizedBox(height: Space.xs),
        for (final day in _slots.entries) ...[
          Text(day.key, style: AppText.bodyL.copyWith(color: p.inkStrong)),
          const SizedBox(height: Space.xxs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final h in day.value)
                ChoiceChip(
                  label: Text(h),
                  selected: _slot == '${day.key} · $h',
                  backgroundColor: p.surfaceRaised,
                  side: BorderSide(
                    color: _slot == '${day.key} · $h' ? p.action : p.lineHair,
                  ),
                  onSelected: (_) => setState(() => _slot = '${day.key} · $h'),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
        ],

        const SizedBox(height: Space.md),
        FilledButton(
          onPressed: _slot == null ? null : () => setState(() => _sent = true),
          style: FilledButton.styleFrom(
            minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
          ),
          child: const Text('Demander le tournage'),
        ),
        const SizedBox(height: Space.xs),
        Text(
          'Quelqu\'un doit être sur place pour ouvrir. Le tournage prend '
          '20 minutes.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: p.inkMuted),
        ),
      ],
    );
  }

  Widget _confirmed(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.videocam_outlined, size: 48, color: p.success),
          const SizedBox(height: Space.md),
          Text(
            'Un agent passe $_slot.',
            style: AppText.titleL.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Il t\'appelle 30 minutes avant d\'arriver. Son nom et sa photo '
            'te sont envoyés la veille — personne d\'autre ne se présentera '
            'en notre nom.',
            style: AppText.bodyL.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
            ),
            child: const Text('C\'est noté'),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 16, color: p.inkMuted),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(text, style: AppText.bodyM.copyWith(color: p.inkBase)),
          ),
        ],
      ),
    );
  }
}
