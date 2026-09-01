import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// S19 — Définir mon point d'ancrage.
///
/// F6 reposait sur un point d'ancrage que rien ne permettait de saisir.
///
/// Le point d'ancrage n'est PAS « mon adresse » : c'est le lieu vers lequel
/// on se déplace tous les jours — le travail, l'école des enfants, le marché
/// où l'on vend. À Cotonou, un logement se juge au temps de zémidjan qui l'en
/// sépare, pas à sa distance à vol d'oiseau.
///
/// Le trajet est exprimé en MINUTES AUX HEURES DE POINTE, jamais en
/// kilomètres. Trois kilomètres sur l'axe Godomey–Cotonou à 7 h ne veulent
/// rien dire ; vingt-cinq minutes veulent tout dire.
class AnchorPointScreen extends StatefulWidget {
  const AnchorPointScreen({super.key});

  @override
  State<AnchorPointScreen> createState() => _AnchorPointScreenState();
}

class _AnchorPointScreenState extends State<AnchorPointScreen> {
  final _controller = TextEditingController(text: 'Ganhi, Cotonou');
  String _mode = 'zem';
  String _moment = 'matin';

  static const _suggestions = [
    'Ganhi, Cotonou',
    'Étoile Rouge',
    'Dantokpa',
    'Zone portuaire',
    'Université d\'Abomey-Calavi',
    'Cadjèhoun',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Mon point d\'ancrage',
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
                  'Où vas-tu tous les jours ?',
                  style: AppText.titleL.copyWith(color: p.inkStrong),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Le travail, l\'école des enfants, le marché. Chaque bien '
                  'affichera le temps qu\'il faut pour y aller.',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),

                const SizedBox(height: Space.lg),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Lieu',
                    hintText: 'Quartier, marché, carrefour',
                  ),
                  style: AppText.bodyL.copyWith(color: p.inkStrong),
                ),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    for (final s in _suggestions)
                      ActionChip(
                        label: Text(s),
                        backgroundColor: p.surfaceRaised,
                        side: BorderSide(color: p.lineHair),
                        onPressed: () => setState(() => _controller.text = s),
                      ),
                  ],
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'COMMENT TU T\'Y RENDS',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                // Le mode change le temps du tout au tout. Un zem passe où une
                // voiture reste bloquée ; un piéton n'a pas les mêmes limites.
                _Choice(
                  value: _mode,
                  onChanged: (v) => setState(() => _mode = v),
                  options: const {
                    'zem': 'Zémidjan',
                    'taxi': 'Taxi / voiture',
                    'walk': 'À pied',
                  },
                ),

                const SizedBox(height: Space.md),
                Text(
                  'À QUELLE HEURE',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                _Choice(
                  value: _moment,
                  onChanged: (v) => setState(() => _moment = v),
                  options: const {
                    'matin': 'Le matin (heure de pointe)',
                    'journee': 'En journée',
                  },
                ),

                const SizedBox(height: Space.lg),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                  ),
                  child: const Text('Enregistrer mon point d\'ancrage'),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Ce lieu ne quitte jamais ton téléphone sous forme précise : '
                  'seul le quartier sert au calcul.',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final Map<String, String> options;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      children: [
        for (final entry in options.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: InkWell(
              onTap: () => onChanged(entry.key),
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
                    color: value == entry.key ? p.action : p.lineHair,
                    width: value == entry.key ? 1.5 : 1,
                  ),
                  borderRadius: const BorderRadius.all(Radii.card),
                ),
                child: Row(
                  children: [
                    Icon(
                      value == entry.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: value == entry.key ? p.action : p.inkFaint,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: AppText.bodyL.copyWith(color: p.inkStrong),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
