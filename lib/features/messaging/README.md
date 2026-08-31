# features/messaging

| | |
|---|---|
| Niveau | 2 |
| Epic | E5 |
| Statut | **MVP tardif** |
| Ecrans | S10 |

Chat + notes vocales (F4). Micro de MEME taille que le bouton d'envoi.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
