# features/lease

| | |
|---|---|
| Niveau | 3 |
| Epic | E10 |
| Statut | **post-MVP** |
| Ecrans | S15 |

Loyer, quittance immediate, bail. Porte la retention longue duree (12-36 mois).

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
