# features/onboarding

| | |
|---|---|
| Niveau | 1 |
| Epic | E1 |
| Statut | **MVP** |
| Ecrans | S01 |

Trois questions, sans compte, sans permission. Regle: une 4e question echoue la revue.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
