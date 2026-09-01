import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/domain/repositories/listing_repository.dart';

/// S04 — Filtres.
///
/// L'ORDRE EST LE PRODUIT. Le coût total d'entrée passe AVANT le loyer, parce
/// que c'est lui qui décide ici : un loyer de 35 000 F avec six mois d'avance
/// demande 245 000 F le jour de l'entrée. Une personne qui filtre par loyer
/// découvre l'obstacle réel trois écrans plus tard, sur place.
///
/// Le compteur de résultats est VIVANT : il se met à jour avant validation.
/// Faire découvrir un résultat vide après avoir fermé la feuille est la façon
/// la plus sûre de faire fermer l'application.
///
/// « Réinitialiser » est en `ghost`, jamais en danger : effacer ses propres
/// filtres n'est pas un acte risqué.
class FiltersSheet extends StatefulWidget {
  const FiltersSheet({
    required this.initial,
    required this.countFor,
    super.key,
  });

  final SearchQuery initial;

  /// Le compteur vivant. Injecté pour que la feuille ne connaisse ni le
  /// dépôt ni le réseau.
  final int Function(SearchQuery) countFor;

  static Future<SearchQuery?> show(
    BuildContext context, {
    required SearchQuery initial,
    required int Function(SearchQuery) countFor,
  }) => showModalBottomSheet<SearchQuery>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FiltersSheet(initial: initial, countFor: countFor),
  );

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late SearchQuery _q = widget.initial;

  // Bornes calées sur le marché du Grand Nokoué, pas sur des ronds arbitraires.
  static const _entryMax = 600000.0;
  static const _rentMax = 200000.0;

  static const _types = ['Chambre-salon', 'Studio', 'Appartement', 'Villa'];
  static const _quartiers = [
    'Fidjrossè',
    'Godomey',
    'Cadjèhoun',
    'Akpakpa',
    'Calavi',
    'Vèdoko',
  ];

  void _set(SearchQuery next) => setState(() => _q = next);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final count = widget.countFor(_q);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: const BorderRadius.vertical(top: Radii.sheet),
        ),
        child: Column(
          children: [
            const SizedBox(height: Space.xs),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.lineStrong,
                borderRadius: const BorderRadius.all(Radii.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtres',
                      style: AppText.titleL.copyWith(color: p.inkStrong),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _set(const SearchQuery()),
                    style: TextButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast)),
                      foregroundColor: p.inkMuted,
                    ),
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(Space.md),
                children: [
                  // 1 — le vrai filtre, en premier.
                  _Slider(
                    title: 'Ce que tu peux sortir aujourd\'hui',
                    subtitle: 'Avance, caution et frais compris',
                    value: (_q.maxMoveInCostFcfa ?? _entryMax.toInt())
                        .toDouble(),
                    max: _entryMax,
                    step: 10000,
                    onChanged: (v) => _set(
                      SearchQuery(
                        neighborhoods: _q.neighborhoods,
                        minRentFcfa: _q.minRentFcfa,
                        maxRentFcfa: _q.maxRentFcfa,
                        propertyType: _q.propertyType,
                        maxMoveInCostFcfa: v.round(),
                        verifiedTourOnly: _q.verifiedTourOnly,
                      ),
                    ),
                  ),

                  // 2 — le loyer, ensuite.
                  _Slider(
                    title: 'Loyer mensuel',
                    subtitle: 'Au maximum',
                    value: (_q.maxRentFcfa ?? _rentMax.toInt()).toDouble(),
                    max: _rentMax,
                    step: 5000,
                    onChanged: (v) => _set(
                      SearchQuery(
                        neighborhoods: _q.neighborhoods,
                        minRentFcfa: _q.minRentFcfa,
                        maxRentFcfa: v.round(),
                        propertyType: _q.propertyType,
                        maxMoveInCostFcfa: _q.maxMoveInCostFcfa,
                        verifiedTourOnly: _q.verifiedTourOnly,
                      ),
                    ),
                  ),

                  const SizedBox(height: Space.md),
                  _Label('Type de logement'),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      for (final t in _types)
                        ChoiceChip(
                          label: Text(t),
                          selected: _q.propertyType == t,
                          backgroundColor: p.surfaceBase,
                          side: BorderSide(
                            color: _q.propertyType == t ? p.action : p.lineHair,
                          ),
                          onSelected: (on) => _set(
                            SearchQuery(
                              neighborhoods: _q.neighborhoods,
                              minRentFcfa: _q.minRentFcfa,
                              maxRentFcfa: _q.maxRentFcfa,
                              propertyType: on ? t : null,
                              maxMoveInCostFcfa: _q.maxMoveInCostFcfa,
                              verifiedTourOnly: _q.verifiedTourOnly,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: Space.md),
                  _Label('Quartiers'),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      for (final n in _quartiers)
                        FilterChip(
                          label: Text(n),
                          selected: _q.neighborhoods.contains(n),
                          backgroundColor: p.surfaceBase,
                          side: BorderSide(
                            color: _q.neighborhoods.contains(n)
                                ? p.action
                                : p.lineHair,
                          ),
                          onSelected: (on) {
                            final next = [..._q.neighborhoods];
                            on ? next.add(n) : next.remove(n);
                            _set(
                              SearchQuery(
                                neighborhoods: next,
                                minRentFcfa: _q.minRentFcfa,
                                maxRentFcfa: _q.maxRentFcfa,
                                propertyType: _q.propertyType,
                                maxMoveInCostFcfa: _q.maxMoveInCostFcfa,
                                verifiedTourOnly: _q.verifiedTourOnly,
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: Space.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _q.verifiedTourOnly,
                    onChanged: (v) => _set(
                      SearchQuery(
                        neighborhoods: _q.neighborhoods,
                        minRentFcfa: _q.minRentFcfa,
                        maxRentFcfa: _q.maxRentFcfa,
                        propertyType: _q.propertyType,
                        maxMoveInCostFcfa: _q.maxMoveInCostFcfa,
                        verifiedTourOnly: v,
                      ),
                    ),
                    title: Text(
                      'Visite Vérifiée disponible',
                      style: AppText.bodyL.copyWith(color: p.inkStrong),
                    ),
                    subtitle: Text(
                      'Filmé sur place par un agent, avec une date',
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                  ),

                  const SizedBox(height: Space.md),
                  // Les critères qui ne changent pas la requête serveur
                  // aujourd'hui sont annoncés comme tels plutôt que simulés :
                  // un filtre qui ne filtre rien détruit la confiance dans
                  // tous les autres.
                  Text(
                    'Électricité, eau, zone inondable et voie bitumée '
                    'arrivent avec la prochaine campagne de vérification. '
                    'Ils ne sont pas encore renseignés sur assez de biens '
                    'pour filtrer honnêtement.',
                    style: AppText.bodyM.copyWith(color: p.inkMuted),
                  ),
                  const SizedBox(height: Space.xxl),
                ],
              ),
            ),

            // Le compteur VIVANT, dans la barre d'action.
            Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: p.surfaceRaised,
                boxShadow: Elevation.stickyBar,
              ),
              child: SafeArea(
                top: false,
                // Le compteur porte sur les biens DÉJÀ CHARGÉS. Il est exact
                // quand on resserre un critère — le cas courant — et prudent
                // quand on l'élargit. C'est pourquoi le bouton ne se
                // désactive JAMAIS : afficher « aucun bien » sur un décompte
                // partiel empêcherait de valider une recherche qui, côté
                // serveur, donne des résultats.
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_q),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(
                      double.infinity,
                      Touch.target(p.isHighContrast) + 8,
                    ),
                  ),
                  child: Text(
                    count == 0
                        ? 'Chercher avec ces critères'
                        : 'Voir $count bien${count > 1 ? 's' : ''}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Text(
        text.toUpperCase(),
        style: AppText.label.copyWith(color: p.inkMuted),
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final double value;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // La valeur est lisible pendant qu'on glisse, pas seulement
              // après avoir lâché.
              Text(
                MoneyFcfa.short(value.round()),
                style: AppText.bodyL.copyWith(
                  color: p.action,
                  fontWeight: FontWeight.w700,
                  fontFeatures: Fonts.tabular,
                ),
              ),
            ],
          ),
          Text(subtitle, style: AppText.bodyM.copyWith(color: p.inkMuted)),
          Slider(
            value: value.clamp(0, max),
            max: max,
            divisions: (max / step).round(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
