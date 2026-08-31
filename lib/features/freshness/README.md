# features/freshness

| | |
|---|---|
| Niveau | 1 |
| Epic | E3 |
| Statut | **MVP** |
| Ecrans | - |

Le Pouls (F2): affichage de fraicheur date + signalement 1 geste recompense. 2 signalements = re-verification.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
