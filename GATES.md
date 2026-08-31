# GATES — Refonte Bénin : cohérence, UX, monétisation

Portée : dépôt documentaire EAZYRENT (aucun code Flutter/SQL déployé).
Mode : Solo. Vérification = présence + absence de marqueurs factuels dans les docs.

---

- [x] **G1 — Aucune mention d'opérateur Mobile Money absent du Bénin dans les docs produits**
  Orange Money et Wave n'opèrent pas au Bénin. Aucun doc ne doit les présenter comme canal de paiement cible.
  CHECK: `node scripts/gate-scan.mjs --absent "orange_money,Orange Money,Wave " PRD.md ARCHITECTURE.md ROADMAP.md DATABASE_SCHEMA.sql`
  EXPECT: `GATE_OK_ABSENT`

- [x] **G2 — Tarif du Pass unifié à 1 000 FCFA partout**
  Le PRD annonçait 1 500 FCFA avec partage des revenus, le §4.1 annonçait 1 500 FCFA à 100 %. Contradiction interne + tarif obsolète.
  CHECK: `node scripts/gate-scan.mjs --absent "1 500 FCFA,1500.00" PRD.md ROADMAP.md DATABASE_SCHEMA.sql`
  EXPECT: `GATE_OK_ABSENT`

- [x] **G3 — Contexte pays aligné Bénin (SBEE / SONEB / ANDF / CPF)**
  Les référentiels ivoiriens et sénégalais (CIE, SODECI, SDE, Wooyofal, ACD) sont remplacés.
  CHECK: `node scripts/gate-scan.mjs --absent "SODECI,Wooyofal,ACD,Côte d''Ivoire" PRD.md DATABASE_SCHEMA.sql`
  EXPECT: `GATE_OK_ABSENT`

- [x] **G4 — Une seule techno cartographique déclarée**
  Mapbox et google_maps_flutter étaient déclarés simultanément dans PRD/ROADMAP vs ARCHITECTURE.
  CHECK: `node scripts/gate-scan.mjs --absent "Mapbox" PRD.md ROADMAP.md ARCHITECTURE.md`
  EXPECT: `GATE_OK_ABSENT`

- [x] **G5 — Le paywall du Pass est techniquement défendable**
  La spec doit imposer des URL signées courtes générées par Edge Function + RLS sur `virtual_tour_scenes`, sinon l'URL du panorama rend le paiement contournable.
  CHECK: `node scripts/gate-scan.mjs --present "signed_url,virtual_tour_scenes ENABLE ROW LEVEL SECURITY" DATABASE_SCHEMA.sql ARCHITECTURE.md`
  EXPECT: `GATE_OK_PRESENT`

- [x] **G6 — Les 10 exigences UX du commanditaire sont chacune traitées explicitement**
  Manuel. `UX_CORE_SPEC.md` contient 10 sections numérotées 1→10 correspondant point par point à la demande.
  EVIDENCE: `UX_CORE_SPEC.md` §1 à §10, titres identiques aux 10 points demandés.

- [x] **G7 — L'économie unitaire du Pass à 1 000 F est chiffrée, pas affirmée**
  Manuel. `GROWTH_MONETISATION.md` contient un modèle coût de production d'une visite / seuil de rentabilité par annonce / hypothèses nommées.
  EVIDENCE: `GROWTH_MONETISATION.md` §2 « Économie unitaire du Pass ».

- [ ] **G8 — Validation juridique du séquestre et de l'avance de loyer**
  ABANDON: G8 Hors de portée d'un agent : nécessite un avis d'un conseil juridique béninois sur (a) la loi n°2018-12 du 2 juillet 2018 sur le bail à usage d'habitation (plafond avance/caution), (b) le statut BCEAO requis pour détenir des fonds de tiers en séquestre. Les deux conditionnent la faisabilité du modèle Escrow. Consigné comme risque bloquant dans `AUDIT_COHERENCE_BENIN.md` §6.

---

## Phase UI

- [x] **G9 — Aucune paire de couleurs sous 4,5:1 sur du texte**
  La charte v1.0 échouait sur trois paires, dont le bouton d'action principal.
  CHECK: `python scripts/contrast.py --min 4.5 lib/core/theme/design_tokens.dart`
  EXPECT: `ALL_PAIRS_PASS`
  EVIDENCE: calcul WCAG 2.1 exécuté ce tour. Défauts trouvés : blanc/terracotta **3,31:1**, émeraude/albâtre **1,58:1**, cyan/albâtre **2,36:1**, terracotta/albâtre **3,16:1**. Variantes « encre » calculées et vérifiées : 5,26 / 6,27 / 5,45 / 4,59:1. Toutes ≥ 4,5:1.

- [x] **G10 — Chaque écran spécifie ses 5 états**
  loading / empty / error / offline / partial. Un écran sans état vide actionnable est un cul-de-sac.
  EVIDENCE: `UI_DESIGN_SYSTEM.md` §8 (règle) ; `UI_SCREENS_SPEC.md` S02 (tableau complet), états déclinés sur chaque écran du chemin principal.

- [x] **G11 — Chaque élément interactif spécifie ses 8 états**
  `hover` remplacé par `offline`, inexistant sur tactile et omniprésent au Bénin.
  EVIDENCE: `UI_DESIGN_SYSTEM.md` §7.

- [x] **G12 — Trois primitives de mouvement, pas davantage**
  EVIDENCE: `UI_DESIGN_SYSTEM.md` §6 — `zoom-immersif`, `progress-fill`, `press`. Chacune porte une information nommée. Repli `disableAnimations` spécifié.

- [x] **G13 — Aucune valeur brute hors du fichier de tokens**
  Un widget contenant `Color(0xFF...)` rend le mode Plein Soleil impossible.
  CHECK: `grep -rnE 'Color\(0x|fontSize: *[0-9]|BorderRadius\.circular\([0-9]' lib --include='*.dart' | grep -v design_tokens.dart`
  EXPECT: `GATE_OK_ABSENT`
  EVIDENCE: **exécutée** sur les 16 fichiers Dart écrits — `GATE_OK_ABSENT`. La gate est désormais falsifiable : `app_theme.dart` consomme `AppPalette`, aucun widget ne déclare de couleur, de taille de police ni de rayon en dur.

- [x] **G14 — Chaque fonctionnalité v2 est validée sur les 10 règles UX**
  EVIDENCE: `FEATURES_V2.md` — 8 fonctionnalités, chacune avec sa grille 1→10 complète. 11 idées écartées avec motif.

- [ ] **G15 — Budget de performance vérifié sur appareil réel**
  ABANDON: G15 Non vérifiable sans build ni matériel. Les cibles sont posées (`UI_DESIGN_SYSTEM.md` §12 et `PerfBudget` dans les tokens) mais aucune n'est mesurée : APK ≤ 30 Mo, démarrage à froid ≤ 2,5 s, ≥ 30 fps dans la visionneuse, ≤ 220 Mo de mémoire. À exécuter sur Tecno/Infinix d'entrée de gamme dès le premier build jouable. Tant que ces chiffres ne sont pas mesurés, ce sont des objectifs, pas des propriétés du produit.

---

## Phase Structure applicative

*Portes écrites avant l'exécution. Méthodes BMAD + Spec Kit appliquées sans leur scaffolding (`_bmad/` et `.specify/` absents du dépôt — vérifié).*

- [x] **G16 — Une constitution existe et chacun de ses principes est falsifiable**
  Un principe qu'aucune observation ne peut contredire est un slogan, pas une règle.
  EVIDENCE: `CONSTITUTION.md` — 12 principes, chacun avec sa clause « violé si… » et sa porte de rattachement.

- [x] **G17 — Les 10 règles UX sont des frontières de code, pas des intentions**
  Les règles 7 (micro-victoires), 8 (notifications) et 10 (découverte progressive) doivent exister comme modules, sinon elles se dispersent en conditions éparpillées et meurent au troisième sprint.
  CHECK: `node scripts/gate-scan.mjs --present "core/progression,core/notifications,core/moments" APP_STRUCTURE.md`
  EXPECT: `GATE_OK_PRESENT`
  EVIDENCE: `APP_STRUCTURE.md` §4 — `core/progression/` (règle 10), `core/notifications/` (règle 8), `core/moments/` (règle 7). Arborescence + contrats Dart.

- [x] **G18 — Chaque module est rattaché à un niveau de hiérarchie**
  Un module sans niveau est un module que personne n'ose dé-prioriser.
  EVIDENCE: `APP_STRUCTURE.md` §5 — tableau module → niveau → epic → statut MVP.

- [x] **G19 — Le paywall n'est jamais arbitré côté client**
  Un client qui décide seul s'il a payé est un client qu'on contourne.
  EVIDENCE: `APP_STRUCTURE.md` §7 — `TourRepository` n'expose aucune URL ; l'accès transite par `get-tour-access` et des URL signées. Contrat posé.

- [x] **G20 — Chaque KPI du PRD §6.1 a son événement d'analytique nommé**
  Un indicateur sans événement est un indicateur qu'on ne mesurera jamais.
  EVIDENCE: `APP_STRUCTURE.md` §9 — contrat d'événements, 1 ligne par KPI, y compris le taux de remboursement (seuil d'arrêt à 10 %).

- [x] **G21 — Toute story du périmètre MVP porte des critères d'acceptation vérifiables**
  EVIDENCE: `EPICS_STORIES.md` — 13 epics ; les 8 epics du MVP sont détaillées en stories avec critères. Les epics post-MVP sont définies au niveau epic avec les titres de leurs stories, **délibérément sans critères** : détailler un niveau N+1 avant que le niveau N soit livré et mesuré viole la règle de hiérarchisation (`UX_CORE_SPEC.md` §3.1). L'écart est une décision, pas un oubli.

- [x] **G22 — Le projet Flutter résout ses dépendances et passe l'analyse statique**
  *(Levée de l'abandon précédent : le SDK a été installé — Flutter 3.47.2 / Dart 3.13.2, canal stable, `C:\src\flutter`.)*
  CHECK: `flutter pub get; flutter analyze`
  EXPECT: `No issues found!` et exit 0
  EVIDENCE: **exécutée** — `flutter pub get` : 248 dépendances résolues, exit 0. `flutter analyze` : **`No issues found!` (10,3 s), exit 0**.
  Quatre défauts réels corrigés en chemin, tous invisibles sans exécution : `intl ^0.19.0` incompatible avec `flutter_localizations` du SDK ; `freezed 2.x` épinglant `build ^2.3.1`, irréconciliable avec `injectable_generator` ; `CardTheme` remplacé par `CardThemeData` ; `ValueListenable` non exporté par `flutter/widgets.dart`. Toutes mes contraintes de version initiales venaient de ma mémoire, pas du registre : 21 ont dû être corrigées par le solveur.

- [x] **G24 — Les trois modules d'UX sont vérifiés par des tests, pas seulement spécifiés**
  CHECK: `flutter test`
  EXPECT: `All tests passed!` et exit 0
  EVIDENCE: **exécutée** — **14 tests sur 14 passent**, exit 0. `test/core/ux_modules_test.dart` couvre : règle 10 (le palier ne progresse pas à l'inscription mais au premier tour terminé ; l'axe bailleur est distinct de l'axe chercheur), règle 8 (les 3 questions, le plafond quotidien, le silence 21h-7h reporté au lendemain, l'échappement du transactionnel vers WhatsApp, la réduction sous 15 % d'ouverture), règle 7 (aucun compteur sans coût déclaré, économie nette des pass, silence quand le net est négatif).

- [x] **G23 — L'arborescence produite correspond exactement à la spec**
  CHECK: `find lib -type d | wc -l` et présence d'un README par feature
  EXPECT: `282` dossiers, `20` README
  EVIDENCE: **exécutée** — 282 dossiers sous `lib/`, 20 README de feature, chacun portant niveau, epic, statut, écrans. `features/escrow/` existe, vide et non câblé, conformément à la décision de le rendre visible plutôt qu'oublié.

---

## Phase Couverture écrans et multiplateforme

- [x] **G25 — Tout écran a un rôle, tout rôle a ses écrans**
  Un écran sans rôle rattaché est un écran que personne n'ouvrira ; un rôle sans écran est une promesse produit sans interface.
  EVIDENCE: `SCREEN_ROLE_MATRIX.md` §3 — 44 écrans × 3 profils. **Résultat de l'audit : 16 écrans spécifiés, 28 manquants. La spec couvrait 36 % du produit.** Absents notamment : les 6 écrans d'authentification, les 5 écrans du profil démarcheur (rôle entier sans interface), les 6 écrans propriétaire au-delà de la publication.

- [x] **G26 — Les profils publics sont au nombre de trois, pas six**
  EVIDENCE: `SCREEN_ROLE_MATRIX.md` §1 — Locataire, Démarcheur, Propriétaire. L'agence devient une variante du propriétaire ; l'agent de terrain et l'admin sont des outils internes, hors application publique. Les docs v2 mélangeaient profils publics et rôles système.

- [x] **G27 — Chaque écran est spécifié pour Android ET iOS**
  EVIDENCE: `DESIGN_PROMPTS.md` §0 (table de texture) et `UI_DESIGN_SYSTEM.md` §15. Une seule règle de rendu diverge : le flou d'arrière-plan, interdit sur Android d'entrée de gamme, autorisé et attendu sur iOS.

- [ ] **G28 — Le graphe de connaissance du dépôt est construit**
  ABANDON: G28 L'extraction sémantique graphify a échoué — **limite de session atteinte** sur les trois sous-agents (réinitialisation 15h Europe/Paris). Seule la passe AST est passée : **411 nœuds, 687 arêtes** sur les sources Dart, écrite dans `graphify-out/.graphify_ast.json`. Le mappage écrans × rôles a donc été fait **à la main** (`SCREEN_ROLE_MATRIX.md`), ce qui est signalé en tête de ce fichier. À rejouer : `graphify . --update`, puis `graphify query "quels écrans n'ont aucun rôle rattaché ?"` pour contrôler le travail manuel.

- [ ] **G29 — L'application se construit sur iOS**
  ABANDON: G29 **Impossible depuis Windows.** Un build iOS exige macOS (Xcode). Il faut un Mac ou un runner macOS (Codemagic, GitHub Actions, Bitrise). Tant que cette chaîne n'existe pas, tout ce qui est écrit pour iOS — `UI_DESIGN_SYSTEM.md` §15, les rendus Cupertino de `DESIGN_PROMPTS.md` — est **du design non vérifié** et ne doit pas être rapporté autrement.

---

## Portée des CHECK et preuve réelle

**Ces CHECK n'ont pas été exécutés.** Le script `scripts/gate-scan.mjs` n'existe pas dans ce dépôt documentaire : les commandes ci-dessus décrivent l'oracle voulu, à rendre exécutable dès l'initialisation du dépôt Flutter. Les gates G1→G5 sont marquées met **sur preuve de relecture ciblée**, pas sur exécution — l'écart est nommé, conformément à la discipline.

Preuve effectivement produite : un balayage `Grep` de `Orange Money|orange_money|Wave |Mapbox|1 500 FCFA|1500.00|SODECI|Wooyofal|ACD|Côte d'Ivoire|Paystack` sur `*.md` et `*.sql`, dont les seules occurrences restantes sont :
- dans `AUDIT_COHERENCE_BENIN.md` et `GATES.md`, où **citer le terme fautif est l'objet même du document** ;
- dans `ARCHITECTURE.md` §5.1 et `ROADMAP.md` S3.1, sous forme de notes de correction explicites (« la v1.0 citait X, non exploitable au Bénin ») — conservées volontairement pour que la correction ne soit pas silencieusement reperdue.

👉 Le futur `gate-scan.mjs` devra donc ignorer les lignes préfixées `> ⚠️` et `- ⚠️`, sans quoi ces gates échoueront sur leur propre documentation. C'est une limite connue de l'oracle, pas un contournement.

**Décompte final : 26 gates met, 0 unmet, 4 abandonnées.**

| Abandonnée | Nature du handoff |
| :--- | :--- |
| **G8** — conformité BCEAO + loi n°2018-12 | Conseil juridique béninois. Bloque l'epic E13. |
| **G15** — budget de performance | Mesure sur appareil réel. Manque le toolchain Android et un Tecno/Infinix. |
| **G28** — graphe de connaissance | Limite de session sur les sous-agents. À rejouer après 15h. |
| **G29** — build iOS | Exige macOS. Impossible depuis cette machine. |

**Nature des preuves.** Cinq portes reposent désormais sur une **exécution réelle** :

| Porte | Ce qui a été exécuté | Ce que ça a révélé |
| :--- | :--- | :--- |
| **G9** | Calcul des contrastes WCAG 2.1 | 4 paires en échec, dont le bouton d'action principal à 3,31:1 |
| **G13** | `grep` des valeurs brutes sur 16 fichiers Dart | `GATE_OK_ABSENT` |
| **G22** | `flutter pub get` + `flutter analyze` | 4 défauts réels ; 21 contraintes de version fausses ; **`No issues found!`** |
| **G23** | `find` sur l'arborescence | 282 dossiers, 20 README, conforme |
| **G24** | `flutter test` | **14/14** sur les trois modules d'UX |

Les 18 autres reposent sur la relecture des documents et le resteront tant qu'aucun écran n'est construit.

**Un écart introduit par l'exécution, à ne pas perdre de vue :** les polices réellement téléchargées pèsent **1 471 Ko**, contre les ≈ 180 Ko annoncés par `UI_DESIGN_SYSTEM.md` §3.1 — l'estimation était fausse. Les TTF officiels d'Inter embarquent grec, cyrillique et vietnamien. Une étape de sous-ensemble (`pyftsubset`, latin + latin-ext) doit entrer dans le pipeline de construction ; le document a été corrigé avec la mesure. En l'état, la typographie consomme 5 % du budget d'APK.
