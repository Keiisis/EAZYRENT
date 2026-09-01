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
  **RÉVISÉE — l'oracle change, la porte tient.** Le moteur est désormais
  `flutter_map`, et `google_maps_flutter` est retiré de `pubspec.yaml`. Mapbox
  n'est plus une techno concurrente mais une SOURCE DE TUILES optionnelle
  parmi deux, la seconde étant OpenStreetMap. Le CHECK doit donc devenir
  `--absent "google_maps_flutter"` : chercher l'absence de « Mapbox »
  échouerait maintenant sur une mention légitime.
  PREUVE : `grep -n "google_maps_flutter" pubspec.yaml` → aucune occurrence.

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

## Phase Rôles complets

*Portes écrites avant l'exécution. Objectif : qu'aucun des trois profils ne
bute sur un écran manquant en cours de parcours.*

- [x] **G30 — Le propriétaire va de la publication à l'encaissement sans trou**
  Publier → voir la demande → accepter un RDV → encaisser. Chaque étape a son
  écran, aucune ne renvoie sur un placeholder.
  **MET.** `publish_listing_page.dart` (C7) → `owner_dashboard_page.dart` (C1)
  → `visit_requests_page.dart` (C3) → `request_tour_page.dart` (C4, construit)
  → `earnings_page.dart` (C6, construit). C4 est atteignable depuis le bouton
  « Ajouter une Visite Vérifiée — 5 000 F » du tableau de bord, C6 depuis
  « Moi → Mes encaissements ».
  PREUVE : `flutter analyze` → `No issues found!` ; `grep -rn "onPressed: () {}"
  lib/features/owner/` → plus aucune occurrence sur le chemin C1→C4.

- [x] **G31 — Le démarcheur va de l'apport au retrait sans trou**
  Apporter → suivre le statut → voir sa commission → retirer.
  Un apporteur payé en retard part, et il en parle.
  **MET.** `submit_listing_page.dart` (D2) → `broker_home_page.dart` (D1, échelle
  de statuts) → `commissions_page.dart` (D4, construit), atteignable depuis
  « Moi → Mes commissions ». Le disponible et l'en-attente sont deux montants
  distincts, et le délai de retrait (24 h) est écrit dans l'écran.

- [x] **G32 — Plus aucun onglet ne dit « à construire »**
  `Messages` était le dernier placeholder, et il est partagé par les TROIS
  profils. Un onglet vide dans la barre principale est une promesse non tenue.
  CHECK: `grep -rn "à construire" lib/`
  EXPECT: aucune occurrence
  **MET.** Sortie réelle : `aucune occurrence`. `_Placeholder` a été supprimé de
  `lib/app.dart` ; l'onglet rend `ConversationsScreen(role: …)`, avec un état
  vide et une action différents par rôle, et `thread_page.dart` derrière.

- [x] **G33 — Toute destination citée dans « Moi » mène quelque part**
  Une ligne qui ne mène nulle part est pire qu'une ligne absente.
  **MET, et rendu non régressable :** `_Row.onTap` est passé de `VoidCallback?`
  avec repli `() {}` à `required VoidCallback`. Une ligne sans destination ne
  compile plus. Les deux bascules d'affichage (Plein Soleil, Léger) sont
  devenues `_ToggleRow`, qui réagit au doigt sur toute la ligne.
  PREUVE : `flutter analyze` → `No issues found!` (le compilateur a d'abord
  refusé les deux lignes non branchées : `missing_required_argument`
  aux lignes 92 et 98 — c'est exactement ce que la porte devait attraper).

---

## Phase Derniers écrans manquants

*Portes écrites avant l'exécution.*

- [x] **G34 — La règle UX 9 existe à l'écran, pas seulement dans la spec**
  L'onboarding en 3 questions / 90 secondes est le seul endroit où le produit
  apprend ce que la personne cherche. Sans lui, le feed montre « tous les
  quartiers » à quelqu'un qui n'en veut qu'un — et la première impression du
  produit est un catalogue, pas une réponse.
  CHECK: le feed après onboarding porte le quartier choisi, pas
  « Tous les quartiers ».
  EXPECT: vérifié sur le Galaxy A56, capture à l'appui.
  **MET — et la porte a attrapé DEUX bugs réels que la relecture n'aurait pas
  vus.** Premier passage sur l'appareil : l'en-tête affichait « Fidjrossè »
  au-dessus de biens de Cadjèhoun, Agla et Godomey.
    · CAUSE 1 — `FeedCubit._fetch()` relisait `_query` AU RETOUR de l'appel.
      Le chargement du démarrage (requête vide) et celui de l'onboarding se
      chevauchaient : la réponse non filtrée s'affichait sous l'étiquette de
      la requête filtrée. Corrigé — la requête envoyée voyage avec sa réponse,
      et une réponse périmée est JETÉE. Verrouillé par
      `test/features/feed_race_test.dart`.
    · CAUSE 2 — le filtre de type envoyait « Chambre-salon » à une colonne
      `property_type_enum` qui contient `apartment` : zéro résultat, sans
      message. `PropertyTypes` est désormais la seule table de traduction, et
      l'interface ne propose plus que les cinq types que la base sait
      représenter. Trois tests le verrouillent.
  PREUVE : capture finale — en-tête « Fidjrossè », 2 biens, tous deux à
  Fidjrossè. `flutter test` → 26/26.

- [x] **G35 — Aucune permission système n'est demandée à froid**
  Une permission refusée est refusée pour toujours : Android ne redemande
  plus. L'amorce doit dire ce qu'on va envoyer AVANT que le dialogue système
  n'apparaisse, et laisser refuser sans rien casser.
  CHECK: `grep -rn "Permission.request\|requestPermission" lib/` — chaque
  appel est précédé d'un écran d'amorce.
  **MET.** Sortie : aucune occurrence — aucune permission n'est encore
  demandée. Les deux points d'amorce existent et sont branchés AVANT tout
  futur appel système : `PermissionPrimingSheet` sur « Alerte quartier », et
  la feuille d'explication de position sur « Autour de moi » dans
  l'onboarding. Elles disent quoi, combien, et quand on se taira.

- [x] **G36 — Le démarrage ne vole pas de temps**
  « Un splash animé de 2 s est 2 s volées à quelqu'un qui cherche un toit. »
  CHECK: aucune animation, aucun délai artificiel au démarrage.
  **MET.** Aucun écran de marque n'existe : `main.dart` ouvre directement le
  tunnel. Le seul délai du produit est l'attente NOMMÉE entre l'onboarding et
  le feed (1,6 s, « On regarde ce qui est libre à Fidjrossè… ») — elle porte
  une information et un quartier réel, ce qui est exactement la condition que
  la spec pose pour l'autoriser.

- [x] **G37 — Le bailleur peut ouvrir SON annonce**
  Le tableau de bord liste les biens ; P02 manquait, donc un bailleur ne
  pouvait pas voir le détail de sa propre annonce ni la corriger.
  **MET.** `my_listing_page.dart` (P02), ouvert en touchant un bien du tableau
  de bord. « Marquer comme loué » est placé juste après la preuve de demande,
  jamais relégué en bas : un bien loué qui reste en ligne détruit la
  fraîcheur du parc, c'est-à-dire le produit lui-même.

- [x] **G38 — Ce qui est affiché tient dans la carte**
  Porte ajoutée APRÈS coup, parce que le premier lancement sur l'appareil l'a
  imposée : trois des quatre lignes de la carte étaient tronquées.
  **MET, sur mesure et non sur estimation.** Le Galaxy A56 fait 1080 px à
  450 dpi, soit **384 dp**, et non les 412 supposés au dessin — la colonne de
  texte ne recevait que 180 dp. Trois corrections, toutes chiffrées :
  vignette 112 → 96 dp, écart 12 → 8 dp, « 3 mois av. » → « 3 mois », et
  « Non confirmé depuis 12 jours » → « Non confirmé · 12 jours » (miroir
  appliqué à `web/lib/format.ts` pour que les deux surfaces disent la même
  chose). PREUVE : captures avant/après — de « Fidjros… », « Vérifié
  aujourd'hui 05h… », « Entrée : 245 000 F · 3 m… » à zéro troncature.

---

## Phase Navigation et capture de position

*Portes écrites avant l'exécution.*

- [x] **G39 — Les quatre temps de trajet viennent d'un calcul d'itinéraire réel**
  Pas d'une distance à vol d'oiseau divisée par une vitesse moyenne. Un temps
  inventé sur un produit qui vend l'exactitude est pire qu'aucun temps.
  CHECK: chaque mode interroge un moteur d'itinéraire et rend une géométrie.
  EXPECT: quatre durées distinctes sur un vrai trajet Cotonou, vérifiées.
  **MET, sur l'appareil.** Cadjéhoun → Fidjrossè, position GPS réelle : zem
  8 min · à pied 31 min · vélo 11 min · voiture 8 min, 3,2 km, ± 24 m, tracé
  suivant les rues, instruction en français. Moteur : Valhalla (FOSSGIS),
  seul moteur gratuit exposant un profil `motorcycle` — Mapbox Directions n'en
  a aucun, et le zémidjan est le mode dominant ici.

- [x] **G40 — Aucun chiffre présenté comme mesuré ne l'est par estimation**
  Valhalla n'a pas de données de trafic sur Cotonou : ses temps sont en
  circulation libre, et son profil `motorcycle` ne modélise pas le faufilage
  du zémidjan. L'écran doit le DIRE, pas le masquer.
  CHECK: la mention de l'absence de trafic est visible sur l'écran, pas dans
  une aide.
  **MET.** Mesuré AVANT de coder : sur Ganhi → Fidjrossè, Valhalla rend
  exactement la même durée pour `motorcycle` et `auto` (13 min, 6,33 km). Le
  profil moto ne modélise pas le faufilage, et il n'existe aucune donnée de
  trafic sur Cotonou. Un coefficient « zem = voiture x 0,7 » aurait produit un
  chiffre plus flatteur, tout aussi faux, avec en plus l'apparence de la
  mesure. L'écran affiche le chiffre du moteur et écrit sa limite.

- [x] **G41 — La position exacte d'un bien porte sa provenance**
  Une épingle posée depuis un bureau et un relevé GPS pris devant le portail
  n'ont pas la même valeur. Confondre les deux revient à vendre une
  vérification qu'on n'a pas faite.
  CHECK: `location_source` est enregistré et affiché.
  **MET.** `MIGRATION_GEO.sql` ajoute `location_source_enum` (`gps_onsite` /
  `manual_pin` / `geocoded`), l'horodatage, l'auteur, et une colonne calculée
  `has_verified_location` vraie UNIQUEMENT pour un relevé sur place sous 40 m.
  L'écran de publication affiche les trois états avec trois phrases
  distinctes.

- [x] **G42 — La précision du relevé est montrée, et un relevé mauvais est refusé**
  Un point à ±200 m envoie quelqu'un dans la rue d'à côté. L'écran de capture
  doit afficher la précision en mètres et refuser d'enregistrer au-delà d'un
  seuil.
  **MET.** Seuil à 40 m. Bouton inactif au-delà, raison écrite dessus.
  Précision affichée en continu ET dessinée en cercle à l'échelle réelle. Le
  relevé garde la MEILLEURE mesure sur 6 secondes, pas la première : la
  première position d'un GPS froid est presque toujours la pire, et c'est
  celle que la plupart des applications enregistrent.

- [x] **G43 — Le suivi en temps réel s'arrête tout seul**
  Un flux GPS laissé ouvert vide une batterie en une heure. Le flux se ferme à
  la sortie de l'écran, et se coupe à l'arrivée.
  CHECK: `positionStream` a un `cancel()` sur tous les chemins de sortie.
  **MET.** `onClose()` ferme le flux à la sortie ; `_onPosition` le coupe
  lui-même dès l'arrivée (35 m). `distanceFilter` de 10 m plutôt qu'un débit
  continu.

- [x] **G44 — La demande de position au démarrage est précédée d'une amorce**
  L'utilisateur veut la demande au lancement ; Android ne redonne jamais une
  permission refusée. Les deux se concilient : l'amorce explique AVANT, le
  dialogue système vient après, et un refus laisse l'application utilisable.
  **MET, vérifié sur l'appareil.** `LocationPrimingScreen` s'affiche en
  premier, avant même le choix du profil, et le dialogue Android qui suit
  propose bien « Exacte » — capture à l'appui. « Plus tard » n'est pas un
  piège : on entre sans position, et on redemande au moment où elle rend un
  service visible.

---

## Écrans construits dans cette passe

| Réf | Écran | Fichier |
| :--- | :--- | :--- |
| S03 | Par quartier (substitut de carte) | `search/…/map_page.dart` |
| S04 | Filtres, compteur vivant | `search/…/filters_sheet.dart` |
| S10 | Messages | `messaging/…/conversations_page.dart` |
| S10b | Une conversation | `messaging/…/thread_page.dart` |
| S11 | Demande de RDV | `visit/…/booking_page.dart` |
| S13 | Conseil de famille | `shortlist/…/family_council_page.dart` |
| S15 | Mon logement | `tenancy/…/my_home_page.dart` |
| — | Mes quittances | `tenancy/…/receipts_page.dart` |
| S16 | Mes passes et crédits | `passes/…/passes_page.dart` |
| S17 | Alertes et recherches | `alerts/…/alerts_page.dart` |
| S18 | Signaler + confirmation | `listing/…/report_listing_page.dart` |
| S19 | Point d'ancrage | `alerts/…/anchor_point_page.dart` |
| S20 | Centre de notifications | `alerts/…/notification_center_page.dart` |
| S21 | Réglages par type | `alerts/…/notification_settings_page.dart` |
| S22 | Aide et litige | `support/…/help_page.dart` |
| S23 | Mes données (export + suppression) | `support/…/data_rights_page.dart` |
| S24 | Historique de paiements | `passes/…/payment_history_page.dart` |
| — | Conditions / Politique | `support/…/legal_page.dart` |
| C4 | Demander un tournage 360 | `owner/…/request_tour_page.dart` |
| C6 | Encaissements | `owner/…/earnings_page.dart` |
| D4 | Mes commissions | `broker/…/commissions_page.dart` |
| A5 | Sortie de secours OTP | ajoutée dans `auth/…/otp_page.dart` |

**Écart nommé — S03.** La tuile Google Maps n'est PAS branchée : elle exige une
clé `MAPS_API_KEY` que le projet n'a pas, et une carte sans clé s'affiche en
rectangle gris, c'est-à-dire comme une application cassée. L'écran rend le
service que la carte devait rendre (prix par quartier, badge 360, nombre de
biens, sélection synchronisée) mais **ce n'est pas la carte**. À rouvrir dès
que la clé existe.

**Écart nommé — couche data.** Les modules `owner`, `broker`, `messaging`,
`tenancy`, `passes` et `alerts` affichent des données de démonstration
déclarées comme telles en commentaire. Le parcours est vérifiable, les
chiffres ne le sont pas.

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

---

## Phase Navigation vivante, carte lisible, écrans restants

*Portes écrites avant l'exécution. Inventaire fait en croisant les 83 exports
de `export-html/` avec `lib/features/`.*

- [x] **G45 — « Démarrer » existe, et ce qui bouge à l'écran est la distance QUI RESTE**
  Aujourd'hui l'écran affiche la longueur TOTALE du trajet, figée. Quelqu'un
  qui marche voit le même « 3,2 km » au départ et à l'arrivée : il en conclut
  que rien ne le suit. Le suivi doit être visible, pas seulement actif.
  CHECK: la distance restante décroît quand la position change.
  **MET, vérifié sur l'appareil.** Un bouton « Démarrer » ouvre le suivi ; le
  panneau passe alors de « 3,2 km » à « 3,2 km restants », avec « Arrêter » et
  la précision GPS en clair. Le reste est calculé LE LONG DU TRACÉ, pas à vol
  d'oiseau — sur un trajet urbain les deux diffèrent d'un facteur deux.
  Le bouton a d'abord été empilé sous le chiffre : il tombait sous le pli et
  n'existait pas à l'écran. Il est désormais sur la même ligne.

- [x] **G46 — Le fond de carte est lisible en plein soleil, à bout de bras**
  Les tuiles OSM standard sont en 256 px non-retina : sur un écran à 450 dpi,
  chaque étiquette de rue est floue. Une carte qu'on ne lit pas ne sert à rien.
  CHECK: tuiles @2x, et le nom des rues reste lisible sans zoomer.
  **MET, MAIS PAS COMME PRÉVU — et l'écart est le résultat d'une faute de
  méthode de ma part.** J'ai d'abord basculé sur CARTO Voyager, qui sert bien
  du @2x : `curl` répondait 200. Sur l'appareil, chaque tuile portait
  « API KEY REQUIRED » en travers. Un code HTTP 200 ne dit rien du contenu de
  l'image ; il fallait REGARDER la tuile. Retour à OpenStreetMap, propre et
  sans filigrane. Le @2x reste possible : il arrive avec le jeton Mapbox, et
  c'est sa seule vraie raison d'être.
  ⚠️ CE QU'AUCUN FOND NE CHANGERA : « Rue 12.172 » n'est pas un défaut d'OSM,
  c'est le nom OFFICIEL de la voie. Cotonou numérote ses rues et Google Maps
  affiche exactement les mêmes.

- [x] **G47 — La photo du portail apparaît là où on en a besoin**
  Sur la fiche de la carte, AU-DESSUS du prix. À défaut, la photo du bien.
  Jamais un rectangle vide : un espace réservé qui reste vide est pire que pas
  d'espace du tout.
  **MET.** `Listing.arrivalImageUrl` = portail ?? photo du bien, et rien quand
  les deux manquent. Un badge « Le portail » distingue les deux : confondre
  une photo de salon et une photo d'entrée fait sonner à la mauvaise porte.

- [x] **G48 — Aucun écran de `export-html/` n'est absent de la version Android**
  CHECK: croisement export-html ↔ lib/features, écran par écran.
  EXPECT: chaque écran non-iOS a son fichier Dart, ou son absence est motivée.
  **MET.** Croisement des 83 exports : six écrans manquaient, tous construits
  dans cette passe — D03 Mes biens apportés, Paiement (attente et échec),
  A05 Réglages, B08 Parrainage, A04 Numéro perdu, et l'entrée D03 depuis
  l'accueil démarcheur.
  ÉCART NOMMÉ, un seul : `visionneuse-360-(tour-complet)`. Il exige
  `flutter_inappwebview`, dont aucune version publiée n'est compatible AGP 9
  (`getDefaultProguardFile('proguard-android.txt')`, refusé). L'aperçu
  verrouillé existe ; le tour complet attend une décision technique, pas du
  travail d'écran.

- [x] **G49 — Le Mode Plein Soleil change réellement le thème**
  L'interrupteur existait et ne faisait rien. Un interrupteur qui bouge sans
  rien changer est un mensonge plus coûteux qu'un interrupteur absent.
  CHECK: basculer le mode change les couleurs ET la taille des cibles.
  **MET.** `ThemeController` est un singleton `get_it` écouté par `MaterialApp`
  lui-même. Basculer depuis « Moi » ou depuis A05 change réellement la palette
  et fait passer `Touch.target` de 48 à 56 dp dans toute l'application.

- [x] **G50 — Un paiement en attente dit ce qu'il faut faire MAINTENANT**
  Le code opérateur (`*880*6#`), le compte à rebours, et la phrase qui compte :
  « rien n'est débité tant que tu n'as pas tapé ton code secret ». Un écran
  d'attente muet fait raccrocher.
  **MET.** Compte à rebours de 2 minutes — le délai réel d'expiration d'une
  demande MoMo, pas un chiffre rond. Le code de secours est en gros sur
  l'écran. À l'échec, « aucun montant n'a été débité » passe AVANT toute
  proposition de réessai, et l'autre opérateur est proposé d'emblée : un échec
  MTN est le plus souvent un incident réseau MTN, pas un problème d'argent.

---

## Phase Visionneuse 360 — le cœur du produit

- [x] **G51 — La visionneuse « tour complet » existe et se construit**
  Elle était bloquée depuis le début par `flutter_inappwebview`, incompatible
  AGP 9. Le blocage n'était pas dans l'écran, il était dans le choix du moteur.
  **MET.** Le webview est abandonné, pour trois raisons dont la première suffit
  à elle seule : `assets/tour_engine/` était RESTÉ VIDE — le bundle Photo
  Sphere Viewer + Three.js n'a jamais été livré. On se serait embarqué un
  moteur JavaScript qu'on ne relit pas, pour afficher une sphère texturée, sur
  un Mali-G52.
  `panorama_viewer` rend la même sphère équirectangulaire en Dart, gyroscope
  compris, sans moteur JS et sans conflit de build.
  PREUVE : `flutter build apk` réussit avec `panorama_viewer` + `flutter_cube`
  + `dchs_motion_sensors` sous AGP 9.1.0.

- [x] **G52 — Une visite payée ne montre JAMAIS un écran noir muet**
  C'est l'incident le plus cher du produit : quelqu'un vient de payer 1 000 F.
  **MET, vérifié sur l'appareil.** Edge Function non déployée → la visionneuse
  affiche « On n'arrive pas à charger. Réessaie. » avec « Réessayer » et
  « Revenir ». Chaque refus a son message : 402 dit que la visite n'est pas
  débloquée, une liste de scènes vide dit que les images ne sont pas en ligne
  ET que le crédit n'a pas été décompté.

- [x] **G53 — Le paywall reste incontournable**
  `TourRepository` n'expose AUCUNE méthode qui lise `virtual_tour_scenes`. Le
  seul chemin est l'Edge Function `get-tour-access`, qui identifie l'appelant
  par son JWT — jamais par un identifiant qu'il envoie —, vérifie le pass ou
  débite un crédit EN BASE, et ne rend que des URL signées 60 minutes.
  `panorama_url`, le chemin permanent, n'est jamais renvoyé au client.
  ÉCART CORRIGÉ EN COURS DE ROUTE : la première version de la fonction
  interrogeait `tour_accesses` et `tour_credits`, deux tables que j'avais
  INVENTÉES. Les vraies sont `virtual_tour_access_passes` (§5.3),
  `visit_credits` (§5.4) et `virtual_tour_hotspots` (§5.2). Écrire du SQL sans
  relire le schéma produit du code qui ne casse qu'au déploiement.

- [ ] **G54 — Un panorama réel s'affiche dans la visionneuse**
  NON TENUE, et elle ne peut pas l'être depuis cette machine : il n'existe
  aujourd'hui aucun panorama dans le stockage, aucun pass payé en base, et
  l'Edge Function n'est pas déployée. Le chemin d'erreur est vérifié, le
  chemin nominal ne l'est pas. À rejouer après :
    1. `supabase functions deploy get-tour-access`
    2. création du bucket `panoramas`
    3. import d'un tour depuis l'admin web (à construire)
