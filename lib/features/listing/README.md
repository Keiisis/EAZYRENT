# features/listing

| | |
|---|---|
| Niveau | 1 |
| Epic | E1 E4 |
| Statut | **MVP** |
| Ecrans | S05 |

Fiche bien. Le Cout Total d'Entree (F1) est le 2e bloc de l'ecran, avant les caracteristiques.

## Regles

- Cette feature ne doit importer aucune autre feature. Tout partage passe par `core/` ou une interface de domaine.
- Structure imposee: `domain/` (entities, repositories, usecases) / `data/` (models, datasources, repositories) / `presentation/` (bloc, pages, widgets).
- Aucune couleur brute: uniquement des tokens de `core/theme/design_tokens.dart`.
- Aucune condition de palier ecrite ici: elle remonte dans `core/progression/StageResolver`.
