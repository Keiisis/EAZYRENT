# features/visits

| | |
|---|---|
| Niveau | 2 |
| Epic | E9 |
| Statut | **post-MVP** |
| Ecrans | S11 |

RDV sur creneaux proposes, puis Visite Guidee en Direct (F7).

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
