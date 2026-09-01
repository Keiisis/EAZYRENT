import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/domain/entities/property_type.dart';
import '../../../listing/domain/repositories/listing_repository.dart';

/// S01 — Onboarding chercheur. Trois questions, 90 secondes.
///
/// C'est la RÈGLE UX 9, et le seul endroit où le produit apprend ce que la
/// personne cherche. Sans lui, le premier écran est un catalogue « tous les
/// quartiers » — c'est-à-dire la même chose que les groupes WhatsApp qu'on
/// vient de quitter.
///
/// Cinq décisions, toutes tenues ici :
///
///   1. AUCUN CLAVIER. Le budget est un curseur. Ouvrir un clavier dans un
///      onboarding fait perdre des utilisateurs — c'est l'endroit du produit
///      où l'abandon coûte le plus cher.
///   2. AUCUNE PERMISSION, AUCUN NUMÉRO à ce stade. « Autour de moi » demande
///      la position au moment où on le touche, et explique pourquoi.
///   3. TROIS POINTS, PAS UNE BARRE. Trois questions ne méritent pas une
///      barre de progression.
///   4. RETOUR TOUJOURS POSSIBLE, aucune question verrouillée. On peut passer
///      les trois et atterrir sur un feed non filtré : c'est moins bon, mais
///      ce n'est jamais un mur.
///   5. VOCABULAIRE LOCAL. « Chambre-salon », pas « T2 ». Un produit qui
///      nomme les choses autrement que ses utilisateurs se fait relire deux
///      fois, et abandonner une.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onDone, super.key});

  /// Reçoit la requête construite. `SearchQuery()` vide si tout a été passé —
  /// passer n'est pas une erreur, c'est une réponse.
  final void Function(SearchQuery) onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  final _quartiers = <String>{};
  int? _maxEntry;
  String? _type;

  static const _quartierChoices = [
    'Fidjrossè',
    'Cadjèhoun',
    'Agla',
    'Godomey',
    'Kpota',
    'Akpakpa',
    'Vèdoko',
    'Calavi',
  ];

  // Vocabulaire local, dans l'ordre de fréquence réelle du marché — et
  // limité à ce que la base sait représenter. Un choix qui ne peut rien
  // rendre est un choix qui ment.
  static const _typeChoices = PropertyTypes.labels;

  SearchQuery get _query => SearchQuery(
    neighborhoods: _quartiers.toList(),
    maxMoveInCostFcfa: _maxEntry,
    propertyType: _type,
  );

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      widget.onDone(_query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  step: _step,
                  onBack: _step == 0 ? null : () => setState(() => _step--),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    child: switch (_step) {
                      0 => _Q1(
                        selected: _quartiers,
                        choices: _quartierChoices,
                        onToggle: (q) => setState(() {
                          _quartiers.contains(q)
                              ? _quartiers.remove(q)
                              : _quartiers.add(q);
                        }),
                      ),
                      1 => _Q2(
                        value: _maxEntry,
                        onChanged: (v) => setState(() => _maxEntry = v),
                      ),
                      _ => _Q3(
                        value: _type,
                        choices: _typeChoices,
                        onPick: (t) => setState(() => _type = t),
                      ),
                    },
                  ),
                ),

                // Zone du pouce. Le bouton principal ne remonte jamais.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    Space.xs,
                    Space.md,
                    Space.md,
                  ),
                  child: Column(
                    children: [
                      FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          minimumSize: Size(
                            double.infinity,
                            Touch.target(p.isHighContrast) + 8,
                          ),
                        ),
                        child: Text(_step < 2 ? 'Continuer' : 'Voir les biens'),
                      ),
                      // Passer est une réponse, pas un échec. Le lien est
                      // discret mais jamais caché : le masquer transformerait
                      // trois questions en trois murs.
                      TextButton(
                        onPressed: () => widget.onDone(_query),
                        style: TextButton.styleFrom(
                          minimumSize: Size(0, Touch.target(p.isHighContrast)),
                          foregroundColor: p.inkMuted,
                        ),
                        child: const Text('Passer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      child: Row(
        children: [
          SizedBox(
            width: Touch.target(p.isHighContrast),
            child: onBack == null
                ? null
                : IconButton(
                    onPressed: onBack,
                    tooltip: 'Retour',
                    icon: Icon(Icons.arrow_back, color: p.inkBase),
                  ),
          ),
          const Spacer(),
          // Trois points, pas une barre.
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == step ? p.action : p.lineStrong,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          const SizedBox(width: Space.xs),
        ],
      ),
    );
  }
}

class _Q1 extends StatelessWidget {
  const _Q1({
    required this.selected,
    required this.choices,
    required this.onToggle,
  });

  final Set<String> selected;
  final List<String> choices;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListView(
      children: [
        const SizedBox(height: Space.lg),
        Text(
          'Tu cherches où ?',
          style: AppText.titleL.copyWith(color: p.inkStrong),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          'Plusieurs quartiers possibles.',
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final q in choices)
              _BigChip(
                label: q,
                selected: selected.contains(q),
                onTap: () => onToggle(q),
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        // La position n'est demandée QU'ICI, et la phrase dit pourquoi.
        OutlinedButton.icon(
          onPressed: () => _explainLocation(context),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(
              double.infinity,
              Touch.target(p.isHighContrast) + 8,
            ),
          ),
          icon: const Icon(Icons.my_location),
          label: const Text('Autour de moi'),
        ),
      ],
    );
  }

  void _explainLocation(BuildContext context) {
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radii.sheet),
      ),
      builder: (sheet) => Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ta position, une seule fois',
              style: AppText.titleM.copyWith(color: p.inkStrong),
            ),
            const SizedBox(height: Space.xs),
            Text(
              'Elle sert à trier les biens du plus proche au plus loin. On ne '
              'la garde pas, et on ne suit jamais tes déplacements.',
              style: AppText.bodyL.copyWith(color: p.inkMuted),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: () => Navigator.of(sheet).pop(),
              style: FilledButton.styleFrom(
                minimumSize: Size(
                  double.infinity,
                  Touch.target(p.isHighContrast) + 8,
                ),
              ),
              child: const Text('Utiliser ma position'),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheet).pop(),
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, Touch.target(false)),
                foregroundColor: p.inkMuted,
              ),
              child: const Text('Je choisis mes quartiers'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Q2 extends StatelessWidget {
  const _Q2({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  // 15 000 → 300 000 F. Ces bornes sont celles du coût d'ENTRÉE, pas du
  // loyer : c'est la somme qu'il faut sortir le jour où l'on emménage, et
  // c'est elle qui décide au Bénin.
  static const _min = 15000.0;
  static const _max = 300000.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final current = (value ?? 90000).toDouble();

    return ListView(
      children: [
        const SizedBox(height: Space.lg),
        Text(
          'Tu peux sortir combien\naujourd\'hui ?',
          style: AppText.titleL.copyWith(color: p.inkStrong),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          'Avance, caution et frais compris. Pas le loyer mensuel.',
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),

        const SizedBox(height: Space.xxl),
        Center(
          child: Text(
            MoneyFcfa.short(current.round()),
            style: AppText.amountL.copyWith(color: p.inkStrong),
          ),
        ),
        const SizedBox(height: Space.sm),
        // Curseur, jamais de clavier.
        Slider(
          value: current.clamp(_min, _max),
          min: _min,
          max: _max,
          divisions: ((_max - _min) / 5000).round(),
          onChanged: (v) => onChanged(v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              MoneyFcfa.short(_min.round()),
              style: AppText.caption.copyWith(color: p.inkMuted),
            ),
            Text(
              '${MoneyFcfa.short(_max.round())} et plus',
              style: AppText.caption.copyWith(color: p.inkMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _Q3 extends StatelessWidget {
  const _Q3({required this.value, required this.choices, required this.onPick});

  final String? value;
  final List<String> choices;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListView(
      children: [
        const SizedBox(height: Space.lg),
        Text(
          'Tu cherches quoi ?',
          style: AppText.titleL.copyWith(color: p.inkStrong),
        ),
        const SizedBox(height: Space.lg),
        for (final t in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: _BigChip(
              label: t,
              selected: value == t,
              onTap: () => onPick(t),
              fullWidth: true,
            ),
          ),
      ],
    );
  }
}

/// 48 dp minimum, comme exigé par la spec : ces cibles sont touchées debout,
/// souvent d'une seule main.
class _BigChip extends StatelessWidget {
  const _BigChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radii.card),
      child: Container(
        width: fullWidth ? double.infinity : null,
        constraints: BoxConstraints(minHeight: Touch.target(p.isHighContrast)),
        // `alignment` UNIQUEMENT en pleine largeur. Un Container qui porte un
        // alignment sans taille explicite se dilate au maximum disponible —
        // c'est ce qui mettait une seule puce de quartier par ligne au lieu
        // de trois, et transformait huit choix en un écran de défilement.
        alignment: fullWidth ? Alignment.centerLeft : null,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? p.actionFill : p.surfaceRaised,
          border: Border.all(
            color: selected ? p.actionFill : p.lineHair,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: const BorderRadius.all(Radii.card),
        ),
        child: Text(
          label,
          style: AppText.bodyL.copyWith(
            color: selected ? p.actionOnFill : p.inkStrong,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// L'attente assumée entre Q3 et le feed. 2 secondes maximum, avec le
/// quartier NOMMÉ.
///
/// « Une attente courte, expliquée et personnalisée augmente la valeur perçue
/// du résultat. Au-delà de 3 s, elle la détruit. » — d'où le délai fixe et
/// court, et le basculement vers le squelette du feed derrière.
class OnboardingHandoff extends StatefulWidget {
  const OnboardingHandoff({
    required this.quartier,
    required this.onFinished,
    super.key,
  });

  final String? quartier;
  final VoidCallback onFinished;

  @override
  State<OnboardingHandoff> createState() => _OnboardingHandoffState();
}

class _OnboardingHandoffState extends State<OnboardingHandoff> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final where = widget.quartier;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: p.action,
                ),
              ),
              const SizedBox(height: Space.md),
              Text(
                where == null
                    ? 'On regarde ce qui est libre…'
                    : 'On regarde ce qui est libre à $where…',
                textAlign: TextAlign.center,
                style: AppText.titleM.copyWith(color: p.inkStrong),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
