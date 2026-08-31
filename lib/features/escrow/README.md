# features/escrow

| | |
|---|---|
| Niveau | 3 |
| Epic | E13 |
| Statut | **BLOQUE** |
| Ecrans | - |

VIDE ET NON CABLE. Bloque par GATES.md G8 (statut BCEAO + loi 2018-12). Le dossier existe pour que son absence reste visible.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
