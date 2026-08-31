# features/broker

| | |
|---|---|
| Niveau | 4 |
| Epic | E8 |
| Statut | **post-MVP** |
| Ecrans | - |

Apporteur / demarcheur partenaire. Role `broker` a ajouter a user_role.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
