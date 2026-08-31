# features/shortlist

| | |
|---|---|
| Niveau | 1-2 |
| Epic | E5 |
| Statut | **MVP** |
| Ecrans | S08 S09 S13 |

Ma liste, Duel binaire (F3), Conseil de famille (F5), compteur d'economies.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
