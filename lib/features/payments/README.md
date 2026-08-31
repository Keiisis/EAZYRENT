# features/payments

| | |
|---|---|
| Niveau | 1 |
| Epic | E2 |
| Statut | **MVP** |
| Ecrans | S07 |

MTN MoMo / Moov Flooz / Celtiis. Aucun SDK marchand: Edge Functions uniquement. Bascule d'operateur a l'echec.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
