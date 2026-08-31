# features/search

| | |
|---|---|
| Niveau | 1 |
| Epic | E1 |
| Statut | **MVP** |
| Ecrans | S02 S03 S04 |

Feed dense, bascule carte, filtres ordonnes par pouvoir de decision, recherches sauvegardees, alertes.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
