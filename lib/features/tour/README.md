# features/tour

| | |
|---|---|
| Niveau | 0 |
| Epic | E2 |
| Statut | **MVP** |
| Ecrans | S06 |

LE COEUR. Preview floutee, visionneuse PSV5, cache hors-ligne chiffre, repli photos fixes.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
