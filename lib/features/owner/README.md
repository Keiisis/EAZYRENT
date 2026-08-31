# features/owner

| | |
|---|---|
| Niveau | 4 |
| Epic | E8 |
| Statut | **post-MVP** |
| Ecrans | S14 |

Publier en 4 champs. Preuve de demande AVANT de vendre le Pack Visibilite.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
