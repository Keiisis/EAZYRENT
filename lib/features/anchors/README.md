# features/anchors

| | |
|---|---|
| Niveau | 2 |
| Epic | E5 |
| Statut | **MVP tardif** |
| Ecrans | - |

Point d'ancrage (F6): temps ET cout mensuel du trajet. Question posee APRES la 1re visite.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
