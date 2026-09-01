import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// S11 — Demande de rendez-vous.
///
/// « Créneaux proposés par le bailleur, pas un sélecteur de date libre — un
/// sélecteur libre produit des demandes qui ne conviennent à personne. »
/// (UI_SCREENS_SPEC.md §S11)
///
/// Après envoi : « Tu y vas en sachant déjà tout. » La phrase relie
/// explicitement le déplacement à la visite 360 déjà faite. C'est la
/// micro-victoire A6, et c'est aussi ce qui justifie, après coup, les 1 000 F
/// dépensés : on ne se déplace plus pour découvrir, on se déplace pour
/// confirmer.
class BookingScreen extends StatefulWidget {
  const BookingScreen({
    required this.listingTitle,
    required this.tourDone,
    super.key,
  });

  final String listingTitle;

  /// Vrai quand la visite 360 a déjà été vue. Change la phrase de succès :
  /// promettre « tu sais déjà tout » à quelqu'un qui n'a rien vu serait faux.
  final bool tourDone;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? _slot;
  bool _sent = false;

  static const _slots = {
    'Samedi 14 mars': ['09h', '11h', '15h'],
    'Dimanche 15 mars': ['10h', '16h'],
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          _sent ? 'Demande envoyée' : 'Demander un rendez-vous',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _sent ? _success(context) : _picker(context),
          ),
        ),
      ),
    );
  }

  Widget _picker(BuildContext context) {
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
          'Quand peux-tu passer ?',
          style: AppText.titleL.copyWith(color: p.inkStrong),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          'Ces créneaux sont ceux que le bailleur a ouverts. Il n\'y a pas '
          'd\'attente de réponse pour savoir s\'il est disponible.',
          style: AppText.bodyM.copyWith(color: p.inkMuted),
        ),

        const SizedBox(height: Space.lg),
        for (final day in _slots.entries) ...[
          Text(day.key, style: AppText.bodyL.copyWith(color: p.inkStrong)),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final h in day.value)
                _SlotChip(
                  label: h,
                  selected: _slot == '${day.key} · $h',
                  onTap: () => setState(() => _slot = '${day.key} · $h'),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
        ],

        const SizedBox(height: Space.md),
        FilledButton(
          onPressed: _slot == null ? null : () => setState(() => _sent = true),
          style: FilledButton.styleFrom(
            minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
          ),
          child: Text(_slot == null ? 'Choisis un créneau' : 'Demander $_slot'),
        ),
        const SizedBox(height: Space.xs),
        Text(
          'Ton numéro n\'est transmis au bailleur qu\'à cet instant.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: p.inkMuted),
        ),
      ],
    );
  }

  Widget _success(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_available, size: 48, color: p.success),
          const SizedBox(height: Space.md),
          Text(
            'Demande envoyée.',
            style: AppText.titleL.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.xs),
          Text(
            widget.tourDone
                ? 'Tu y vas en sachant déjà tout.'
                : 'Le bailleur confirme en général dans la journée.',
            style: AppText.titleM.copyWith(color: p.success),
          ),
          const SizedBox(height: Space.md),
          Text(
            '$_slot\n${widget.listingTitle}',
            style: AppText.bodyL.copyWith(color: p.inkMuted),
          ),

          const SizedBox(height: Space.lg),
          Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: p.surfaceSunken,
              borderRadius: const BorderRadius.all(Radii.card),
            ),
            child: Row(
              children: [
                Icon(Icons.alarm, size: 20, color: p.info),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    'Rappel la veille à 18 h, puis 2 h avant, avec '
                    'l\'itinéraire. Sur WhatsApp.',
                    style: AppText.bodyM.copyWith(color: p.inkBase),
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
            child: const Text('C\'est noté'),
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = Touch.target(p.isHighContrast);

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radii.chip),
      child: Container(
        constraints: BoxConstraints(minHeight: size, minWidth: size + 16),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Space.sm),
        decoration: BoxDecoration(
          color: selected ? p.actionFill : p.surfaceRaised,
          border: Border.all(color: selected ? p.actionFill : p.lineHair),
          borderRadius: const BorderRadius.all(Radii.chip),
        ),
        child: Text(
          label,
          style: AppText.bodyL.copyWith(
            color: selected ? p.actionOnFill : p.inkStrong,
            fontWeight: FontWeight.w600,
            fontFeatures: Fonts.tabular,
          ),
        ),
      ),
    );
  }
}
