# features/profile

| | |
|---|---|
| Niveau | 1 |
| Epic | E6 |
| Statut | **MVP** |
| Ecrans | S12 |

Moi, 4 visages selon le palier. Theme, mode Leger, reglages de notification par type.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
