/* EAZYRENT · design system · v1.0
 * genre: utilitaire-éditorial · macrostructure app: Feed-led (liste dense → fiche → immersif)
 * ancre chromatique: terracotta chaude (9°) · papier: bi-mode obsidienne/albâtre
 * pre-emit critique — P5 H5 E4 S5 R4 V4
 */

# 🎨 EAZYRENT — Design System UI

**Plateformes :** Flutter — **Android et iOS**, avec chrome adaptative (Material 3 / Cupertino)
**Cible matérielle Android :** Tecno / Infinix / itel / Samsung A — 2–4 Go RAM, Android 10-13, GPU Mali-G52 et inférieurs
**Cible iOS :** parc plus récent — diaspora et propriétaires. Contraintes matérielles bien plus souples.

> **Révision : iOS entre dans le périmètre.** La v1 de ce document posait « Android-first, iOS différé ». Décision annulée. Conséquences réelles à assumer : (1) **on ne peut ni construire ni tester iOS depuis Windows** — un Mac ou un runner macOS (Codemagic, GitHub Actions) devient nécessaire ; (2) le budget de QA double ; (3) l'argument « distribution par APK partagé » reste valable pour Android seul. Voir §15 pour les règles d'adaptivité.
**Contexte d'usage réel :** en extérieur, en plein soleil, sur data mesurée, souvent à une main, souvent debout
**Base préservée :** `BRAND_GUIDELINES.md` v2.0 — Plus Jakarta Sans + Inter, terracotta / obsidienne / émeraude / cyan

> Ce document définit les **règles**. `UI_SCREENS_SPEC.md` applique ces règles écran par écran. `lib/core/theme/design_tokens.dart` en est l'implémentation littérale : **aucune valeur brute (hex, sp, dp, ms) ne doit apparaître ailleurs que dans ce fichier.**

---

## 1. Le principe directeur

> **L'écran doit se lire debout, dehors, en plein soleil, sur un téléphone à 40 000 F, avec une main.**

Ce n'est pas une contrainte d'accessibilité ajoutée après coup : c'est la condition d'usage majoritaire. Tout arbitrage esthétique qui échoue ce test est écarté, y compris quand il vient de la charte.

Trois conséquences immédiates :
1. **Le contraste n'est pas négociable et se mesure**, il ne s'apprécie pas à l'œil sur un écran de bureau calibré.
2. **La densité l'emporte sur la respiration.** Un chercheur veut voir 4 biens par écran, pas 1,5 carte aérée. L'espace blanc est un luxe de desktop.
3. **Chaque milliseconde de rendu et chaque Mo de données ont un coût réel** payé par l'utilisateur.

---

## 2. Couleur — corrigée par la mesure

### 2.1 Ce que l'audit de contraste a révélé

Ratios calculés selon WCAG 2.1 (luminance relative). **Trois défauts bloquants dans la charte v1.0**, tous invisibles à l'œil sur écran de bureau :

| Paire | Ratio | Verdict |
| :--- | ---: | :--- |
| Blanc sur terracotta `#FF4D2E` — **le bouton d'action principal** | **3,31:1** | ❌ **Échec AA.** Le CTA le plus utilisé de l'app était illisible aux normes. |
| Émeraude `#00E599` sur albâtre `#F8FAFC` | **1,58:1** | ❌ Échec total. Invisible en mode clair. |
| Cyan `#00B4D8` sur albâtre | **2,36:1** | ❌ Échec. |
| Terracotta sur albâtre (texte) | 3,16:1 | ❌ Échec pour du texte |
| Terracotta sur obsidienne | 5,79:1 | ✅ AA |
| Émeraude sur obsidienne | 11,55:1 | ✅ AAA |
| Cyan sur obsidienne | 7,77:1 | ✅ AAA |
| Albâtre sur obsidienne (texte courant) | 18,30:1 | ✅ AAA |

**Diagnostic :** la palette v1.0 a été conçue en mode sombre uniquement. Les trois accents sont des couleurs **saturées et claires** — magnifiques sur fond noir, inutilisables sur fond blanc. Or le mode clair est celui qu'on utilise dehors, en plein jour, c'est-à-dire la majorité des sessions.

### 2.2 La correction : deux jeux d'accents, pas un

Chaque accent existe désormais en deux variantes : **vive** (fonds sombres, remplissages) et **encre** (texte sur fond clair). Les variantes encre ont été calculées pour franchir 4,5:1, pas choisies à vue.

| Rôle | Vive (dark / fill) | Encre (texte sur clair) | Ratio de l'encre sur albâtre |
| :--- | :--- | :--- | ---: |
| Action / signature | `#FF4D2E` | `#C4321A` | **5,26:1** ✅ |
| Action — remplissage plein avec label blanc | `#D93A1F` | — | **4,59:1** ✅ |
| Succès / paiement / certifié | `#00E599` | `#006B4A` | **6,27:1** ✅ |
| Information / 360 / hotspots | `#00B4D8` | `#00708A` | **5,45:1** ✅ |

**Règles absolues qui en découlent :**
- ❌ Jamais de texte blanc sur `#FF4D2E` pur. Un bouton terracotta plein utilise `#D93A1F` comme fond, ou garde `#FF4D2E` avec un label **obsidienne** (5,79:1).
- ❌ Jamais `#00E599` ni `#00B4D8` comme couleur de texte en mode clair. En remplissage avec encre obsidienne uniquement (11,55:1 et 7,77:1).
- ✅ Les couleurs vives restent la signature en mode sombre et dans la visionneuse 360, où elles donnent leur meilleur rendu.

### 2.3 Structure de la palette

**La couleur ne porte jamais seule une information.** Un statut est toujours couleur **+** icône **+** mot. Environ 4 % des hommes ont une déficience de perception du rouge-vert ; sur terracotta/émeraude, c'est exactement la paire à risque.

```
SURFACES                     MODE CLAIR        MODE SOMBRE
  surface-base               #F8FAFC           #0B0F19
  surface-raised (cartes)    #FFFFFF           #141926
  surface-sunken (champs)    #EEF2F7           #080C14
  surface-overlay (modals)   #FFFFFF           #1A2030

TEXTE
  ink-strong  (titres)       #0B0F19  18,3:1   #F8FAFC  18,3:1
  ink-base    (corps)        #1E2635  13,9:1   #D6DDE8  12,4:1
  ink-muted   (secondaire)   #55617A   5,9:1   #93A0B8   6,3:1
  ink-faint   (désactivé)    #8A94A8   3,1:1   #5E6A80   3,2:1   ← jamais pour de l'information

BORDURES
  line-hair                  #E2E8F0           #232B3B
  line-strong                #CBD5E1           #384357
```

`ink-faint` est réservé au texte désactivé et aux séparateurs. **Aucune information ne s'y écrit** — c'est la règle qui empêche la dérive vers le gris illisible.

### 2.4 Sémantique — un accent, un sens, jamais deux

| Token | Sens unique | Usage autorisé |
| :--- | :--- | :--- |
| `action` (terracotta) | « fais ceci maintenant » | Le CTA principal. **Un seul par écran.** |
| `success` (émeraude) | « c'est validé, c'est vérifié, c'est payé » | Badge Visite Vérifiée, paiement confirmé, disponibilité re-confirmée |
| `info` (cyan) | « immersion, 360, repère spatial » | Hotspots, mini-plan, indicateur de tour |
| `warn` (`#F2A93B` / encre `#8A5A00`) | « attention, pas encore une erreur » | Annonce non re-confirmée depuis 7 j, crédit bientôt expiré |
| `danger` (`#E5484D` / encre `#B3151A`) | « échec, perte, destruction » | Paiement échoué, bien retiré, suppression |

Un écran avec deux boutons terracotta n'a plus de hiérarchie. Si deux actions se disputent la place, l'une des deux est secondaire — et l'arbitrage se fait dans la spec d'écran, pas dans le code.

### 2.5 Mode Plein Soleil — troisième thème, pas un réglage

Au-delà du clair et du sombre, un **troisième mode explicite**, activable depuis le sélecteur de thème et proposé automatiquement quand le capteur de luminosité dépasse un seuil (proposé, jamais imposé — un basculement automatique non consenti est désorientant).

Ce qu'il change :
- Tous les textes passent à une cible **AAA (≥ 7:1)** : `ink-muted` disparaît au profit de `ink-base`.
- Les surfaces s'aplatissent : plus d'ombres, plus de dégradés, bordures `line-strong` partout.
- Les tailles de police montent d'un cran dans l'échelle.
- Les zones tactiles passent de 48 à 56 dp.
- Les images du feed passent en luminosité +15 % / contraste +10 % côté rendu.

C'est un mode d'accessibilité **contextuelle**, motivé par le climat et le matériel, pas par le handicap. Il sert tout le monde.

---

## 3. Typographie

### 3.1 Duo préservé, rôles resserrés

- **Plus Jakarta Sans** — titres, montants héros, wordmark. Poids embarqués : **700, 800 uniquement**.
- **Inter** — corps, données, montants en FCFA, formulaires. Poids embarqués : **400, 500, 600**. `fontFeatures: [FontFeature.tabularFigures()]` **obligatoire** partout où un chiffre s'affiche : sans chiffres tabulaires, une colonne de loyers danse à chaque rafraîchissement.

**Budget de police — corrigé après mesure.** L'estimation initiale de ce document (≈ 180 Ko) était fausse. Les fichiers réellement embarqués pèsent **1 471 Ko** :

| Fichier | Poids |
| :--- | ---: |
| `Inter-Regular.ttf` | 402 Ko |
| `Inter-Medium.ttf` | 408 Ko |
| `Inter-SemiBold.ttf` | 410 Ko |
| `PlusJakartaSans-Bold.ttf` | 126 Ko |
| `PlusJakartaSans-ExtraBold.ttf` | 126 Ko |
| **Total** | **1 471 Ko** |

Les TTF officiels d'Inter (release v4.1) embarquent grec, cyrillique et vietnamien — inutiles ici. **Atteindre la cible impose une étape de sous-ensemble** (`pyftsubset --unicodes=U+0000-00FF,U+0100-017F` pour latin + latin-ext), à ajouter au pipeline de construction. Tant qu'elle n'existe pas, compter **1,5 Mo sur les 30 Mo d'APK**, soit 5 % du budget pour de la typographie.

Pas de variable font complète : le gain de flexibilité ne vaut pas son poids sur ce budget.

### 3.2 Échelle — 9 crans, pas plus

| Token | Taille / interligne | Graisse | Emploi |
| :--- | :--- | :--- | :--- |
| `display-l` | 32 / 38, tracking −0,5 | Jakarta 800 | Écran d'accueil, montant héros |
| `display-m` | 28 / 34, tracking −0,25 | Jakarta 700 | Titre d'écran immersif, prix sur fiche |
| `title-l` | 22 / 28 | Jakarta 700 | Titre d'écran |
| `title-m` | 18 / 24 | Inter 600 | Titre de carte, titre de section |
| `body-l` | **16 / 24** | Inter 400 | **Corps par défaut. Plancher de lecture.** |
| `body-m` | 14 / 20 | Inter 400 | Texte secondaire dense |
| `label` | 13 / 16, tracking +0,2 | Inter 500 | Boutons, onglets, chips |
| `caption` | 12 / 16 | Inter 400 | Horodatages, mentions légales. **Jamais d'information critique.** |
| `amount` | 24 / 28 tabulaire | Inter 600 | Loyers, coûts d'entrée, soldes |

**Planchers non négociables :** 12 sp absolu, **16 sp pour tout ce qui se lit vraiment**. La mesure d'un paragraphe reste sous 60 caractères.

### 3.3 Mise à l'échelle système

L'app doit rester utilisable jusqu'à `textScaleFactor` **2,0**. Concrètement : aucune hauteur fixe sur un conteneur de texte, aucun `maxLines: 1` sur un label essentiel, tous les boutons en hauteur intrinsèque avec un minimum de 48 dp. C'est la norme la plus souvent violée dans les apps Flutter, et celle qui exclut le plus d'utilisateurs — au Bénin comme ailleurs, beaucoup d'utilisateurs de plus de 45 ans ont la taille système au maximum.

### 3.4 Vocabulaire — l'interdit de la charte, rappelé ici

Jamais à l'écran : « VR », « immersif », « panorama équirectangulaire », « stéréoscopique », « escrow », « séquestre ».
On dit : **« Visite ce logement comme si tu y étais »**, **« Argent bloqué »**, **« Tour complet »**.

---

## 4. Espacement, grille, formes

**Échelle 4 pt**, sémantique : `2xs 4` · `xs 8` · `sm 12` · `md 16` · `lg 24` · `xl 32` · `2xl 48` · `3xl 64`.

- **Gouttière d'écran :** 16 dp. Pas 20, pas 24 — la densité prime.
- **Rythme vertical entre cartes du feed :** 12 dp. Assez pour séparer, assez serré pour montrer 4 biens.
- **Rayons** (charte préservée, deux ajouts) : `chip 8` · `input 12` · `card 16` · `sheet 24` · `pill 9999`.
- **Zone tactile minimale : 48 × 48 dp**, 56 en Plein Soleil. Écart minimal entre deux cibles : 8 dp. Une cible visuellement plus petite (icône 24) reste enveloppée d'une zone tactile de 48.
- **Zone du pouce :** toute action primaire réside dans le tiers inférieur de l'écran. Le haut d'un écran de 6,5 pouces est hors de portée d'un pouce quand on tient un sac de l'autre main — situation permanente au marché.

---

## 5. Profondeur — la contrainte matérielle décide

La charte v1.0 demande des « ombres diffuses et colorées, glow subtil ». Sur Mali-G52, chaque ombre floutée est un passage de blur coûteux, et un `BackdropFilter` en fait chuter le framerate de façon visible.

**Règles :**
1. **Élévation tonale d'abord** (Material 3) : une surface plus haute est une surface *plus claire*, pas une surface qui projette une ombre.
2. **Maximum 2 ombres floutées par écran**, réservées aux éléments réellement flottants : la barre d'action collée en bas, la feuille modale.
3. **Aucun `BackdropFilter`** — pas de verre dépoli. C'est le premier poste de perte de framerate sur ce parc.
4. **Le « glow » terracotta de la charte est conservé uniquement sur le marqueur de carte sélectionné** — un seul élément à la fois, jamais une liste.

---

## 6. Mouvement — trois primitives, pas une de plus

Chaque animation doit transporter une information. Le reste est du bruit qui coûte des images par seconde.

| Primitive | Durée / courbe | Rôle informatif |
| :--- | :--- | :--- |
| **`zoom-immersif`** | 280 ms `emphasized` | Passage photo 2D → tour 360. Transition d'élément partagé : la photo *devient* la scène. C'est le moment le plus important de l'app, il mérite sa seule animation spectaculaire. |
| **`progress-fill`** | 180 ms `standard` | La barre « 4/6 pièces vues » qui avance. C'est la micro-victoire rendue visible (`UX_CORE_SPEC.md` §7.3). |
| **`press`** | 90 ms, échelle 0,97 + retour haptique léger | Accusé de réception d'un appui. Sur un réseau lent, c'est ce qui distingue « l'app a compris » de « l'app est morte ». |

**Durées :** `fast 90` · `base 180` · `slow 280`. Rien au-delà de 280 ms — au-delà, l'interface paraît lente, pas élégante.
**Courbes :** `standard (0.2, 0, 0, 1)` · `emphasized (0.05, 0.7, 0.1, 1)` · `exit (0.3, 0, 1, 1)`. Jamais de rebond sur un changement d'état : un rebond sur une confirmation de paiement lit comme un jouet.

**`prefers-reduced-motion` / `MediaQuery.disableAnimations`** : `zoom-immersif` se réduit à un fondu de 120 ms, `progress-fill` devient instantané, `press` conserve uniquement l'haptique.

**Ce qu'on n'anime pas :** l'apparition des cartes du feed (une liste qui se met en scène retarde la lecture), les squelettes de chargement au-delà d'un shimmer unique, les anneaux de focus (ils doivent apparaître instantanément).

---

## 7. Les 8 états — obligatoires sur tout élément interactif

Sur mobile tactile, `hover` n'existe pas. Il est remplacé par **`offline`**, qui est l'état le plus fréquemment omis et le plus fréquemment rencontré au Bénin.

| État | Traitement |
| :--- | :--- |
| **default** | Repos |
| **pressed** | Échelle 0,97 + assombrissement 8 % + haptique `lightImpact` |
| **focused** | Anneau 2 dp `action`, décalage 2 dp, contraste ≥ 3:1, **apparition instantanée**. Requis pour la navigation au clavier et les commutateurs d'accessibilité. |
| **disabled** | Opacité 38 %, `ink-faint`, **plus une raison affichée**. Un bouton grisé sans explication est un cul-de-sac. |
| **loading** | Le libellé est remplacé par un indicateur, **la largeur est figée** pour éviter le saut de mise en page. Verrouillage anti-double-appui. |
| **error** | Bordure `danger` + icône + **message qui dit quoi faire**, jamais un code. |
| **success** | Émeraude + icône, **1 200 ms puis retour au repos**. Succès silencieux par défaut : on ne félicite pas quelqu'un d'avoir appuyé sur un bouton. |
| **offline** | Grisé + bandeau persistant « Pas de connexion — tu vois ce qui est déjà chargé ». Les actions qui fonctionnent hors-ligne **restent actives** : c'est le cœur de la promesse « on a payé, on possède ». |

---

## 8. Les 5 états d'écran — obligatoires sur tout écran

| État | Règle |
| :--- | :--- |
| **loading** | Squelette respectant la forme finale, jamais un cercle centré. Un squelette qui a la silhouette du contenu réduit la latence perçue. |
| **empty** | **Toujours une action.** Jamais « Aucun résultat » seul. → « Aucun bien à Fidjrossè sous 40 000 F. **Élargir à Godomey** (12 biens) ou **créer une alerte**. » |
| **error** | Cause en français simple + bouton Réessayer + issue alternative. |
| **offline** | Contenu en cache affiché avec sa date. Les tours déjà payés restent accessibles. |
| **partial** | Certaines données manquent → afficher ce qu'on a, marquer le reste. Ne jamais bloquer l'écran entier pour un champ absent. |

---

## 9. Composants — inventaire et décisions

### 9.1 `ListingCard` — le composant le plus vu de l'app

```
┌──────────────────────────────────────────────┐
│ ┌────────┐  35 000 F /mois                   │  ← amount, tabulaire, Jakarta
│ │ photo  │  Chambre-salon · Fidjrossè        │  ← body-m, ink-base
│ │ 4:3    │  ◉ Vérifié aujourd'hui 09h12      │  ← success + icône + mot
│ │ [360]  │  Entrée : 245 000 F  (3 mois av.) │  ← LE chiffre décisif
│ └────────┘  ~22 min de ton travail           │  ← ink-muted
└──────────────────────────────────────────────┘
   112dp        hauteur totale 128 dp
```

Décisions et leurs raisons :
- **Photo à gauche, pas en bandeau pleine largeur.** Une carte à photo pleine largeur fait 280 dp de haut : 2 biens par écran. En vignette 112 dp : 4 biens. Le chercheur balaie, il ne contemple pas.
- **Le prix d'abord, en haut, en gros.** C'est le premier filtre mental. Le titre du bien ne sert à rien — « Belle chambre-salon moderne » n'informe personne.
- **Le coût total d'entrée est sur la carte, pas dans la fiche.** C'est le critère qui élimine 80 % des biens au Bénin ; le cacher fait perdre du temps à tout le monde.
- **La fraîcheur est sur la carte.** C'est la promesse du produit ; elle ne se mérite pas en cliquant.
- **Le badge `[360]` est sur la photo**, en cyan, pas un texte. C'est le seul élément qui a le droit d'être décoratif.

### 9.2 Inventaire

**Atomes** — `AppButton` (primary/secondary/ghost/danger, 8 états), `AppChip` (filtre, sélectionnable), `AppInput` (label persistant, jamais un placeholder seul), `AmountText` (tabulaire, formatage FCFA avec espace insécable comme séparateur de milliers), `StatusBadge` (couleur + icône + mot), `AppAvatar`, `VoiceNoteButton`.

**Molécules** — `ListingCard`, `FreshnessBadge`, `PriceBreakdown`, `MoneyMethodTile` (MTN / Moov / Celtiis), `ProgressRooms`, `EmptyState`, `OfflineBanner`, `CreditCounter`.

**Organismes** — `FeedList`, `FilterSheet`, `TourViewer`, `PaywallSheet`, `DuelView`, `ThreadView`, `RentPanel`.

**Une règle de fabrication :** aucun composant ne connaît de couleur. Il consomme un token. Un `AppButton` qui contient `Color(0xFFFF4D2E)` est un bug, pas un détail — c'est ce qui rend impossible le mode Plein Soleil.

---

## 10. Formats, langue, monnaie

- **Montants :** `35 000 F` — espace insécable fine comme séparateur, `F` et non `FCFA` dans les listes (gain de place), `FCFA` en toutes lettres sur les écrans de paiement où l'ambiguïté coûte cher.
- **Jamais de décimales** sur un montant en FCFA. `35 000,00 F` est du bruit.
- **Dates :** relatives sous 7 jours (« il y a 2 h », « hier »), absolues au-delà (`12 mars`). Les horodatages de fraîcheur sont **toujours** absolus et précis : « Vérifié aujourd'hui à 09h12 » — la précision *est* la preuve.
- **Téléphone :** `+229 XX XX XX XX`, groupé par deux.
- **Langue :** français simple, tutoiement, phrases courtes. Voix off en **fon** et **yoruba** sur les 6 écrans clés en phase 2 — audio, pas traduction écrite : le lectorat écrit de ces langues est faible, l'oral est universel.

---

## 11. Accessibilité — le socle

- **WCAG 2.1 AA** sur tout texte et tout élément d'interface. AAA en mode Plein Soleil.
- **Étiquettes sémantiques** (`Semantics`) sur toute icône seule. Un bouton icône sans label est muet pour TalkBack.
- **Ordre de lecture** explicite sur les écrans complexes (fiche de bien, paiement).
- **Aucune information portée par la couleur seule.**
- **Aucune contrainte de temps** sur une action utilisateur — sauf le compte à rebours d'un code OTP, qui doit être prolongeable.
- **Le tour 360 doit avoir une alternative** : la liste des pièces avec une photo fixe par pièce et sa légende, accessible depuis la visionneuse. Sans elle, l'utilisateur avec un trouble vestibulaire ou un GPU trop faible est exclu du cœur du produit.

---

## 12. Budget de performance — chiffré et vérifiable

| Contrainte | Cible | Pourquoi |
| :--- | ---: | :--- |
| Taille de l'APK | ≤ 30 Mo | Partage direct WhatsApp / Bluetooth, canal d'acquisition réel |
| Démarrage à froid → premier bien affiché | ≤ 2,5 s | Sur Tecno milieu de gamme |
| Feed en 3G, premier écran utile | ≤ 1,5 s | KPI du PRD §6.2 |
| Poids d'un écran de feed (12 cartes) | ≤ 350 Ko | Vignettes 400 px WebP, ~25 Ko chacune |
| Poids d'une scène 360 | ≤ 1,5 Mo | Cf. `ARCHITECTURE.md` §6.5 |
| Images par seconde dans la visionneuse | ≥ 30 fps soutenu | Pas 60. Promettre 60 sur Mali-G52 est un mensonge. |
| Mémoire à l'exécution | ≤ 220 Mo | Marge de sécurité sur un appareil à 2 Go |

**Règles de rendu :** `const` partout où c'est possible · `ListView.builder` avec `itemExtent` fixe (la hauteur de carte est constante à 128 dp — c'est aussi pour ça qu'elle l'est) · `cacheExtent` limité à 2 écrans · vignettes redimensionnées **côté serveur**, jamais téléchargées en pleine résolution puis réduites · `RepaintBoundary` autour des cartes.

---

## 13. Mode Léger — explicite, pas caché

Un interrupteur visible dans **Moi**, activé par défaut hors Wi-Fi :
- Vignettes en 240 px au lieu de 400
- Aucun préchargement de tour
- **Le poids est affiché avant tout téléchargement** : « Ce tour = 8 Mo. Télécharger ? »
- Les tours payés déjà téléchargés restent en cache et ne se re-téléchargent jamais

Afficher le coût en données avant de le dépenser est une marque de respect que ce marché reconnaît immédiatement. C'est aussi une différenciation réelle : aucune app immobilière ne le fait.

---

## 14. Ce que ce système refuse

| Refusé | Raison |
| :--- | :--- |
| Verre dépoli / `BackdropFilter` | Effondrement du framerate sur GPU d'entrée de gamme |
| Dégradés sur les surfaces de contenu | Coût de rendu, contraste imprévisible en plein soleil |
| Carrousels de photos en pleine largeur dans le feed | Détruit la densité, cache le prix |
| Écrans de bienvenue à balayer | Personne ne les lit (`UX_CORE_SPEC.md` §9.2) |
| Deux boutons terracotta sur un écran | Plus de hiérarchie |
| Un badge « NOUVEAU » sur ce qui n'est pas nouveau | La marque est vendue sur la vérité |
| Une animation qui ne transporte aucune information | Coût en fps, gain nul |
| Un état vide sans action | Cul-de-sac |
| Une icône sans étiquette sémantique | Invisible pour TalkBack |
| `caption` (12 sp) pour une information dont dépend une décision | Illisible dehors |

---

## 15. Adaptivité iOS / Android

**Ce qui ne change jamais :** les couleurs, la typographie, la densité, la hiérarchie de l'information, les 8 états, les 5 états d'écran, les interdits du §14. Une carte de bien contient exactement les mêmes éléments dans le même ordre sur les deux plateformes.

**Ce qui change :** la chrome, les gestes, les physiques de défilement, et une règle de rendu.

| | Android — Material 3 | iOS — Cupertino |
| :--- | :--- | :--- |
| Titre d'écran | Titre compact fixe | **Grand titre repliable** au défilement |
| Retour | Geste système + flèche | **« ‹ Retour » libellé** + balayage depuis le bord |
| Rayons | 16 cartes · 24 feuilles | **12-14 cartes · 20 feuilles** — plus serré |
| Séparateurs | 1 dp pleine largeur | **Cheveu 0,33 pt**, en retrait aligné sur le contenu |
| Défilement | Effet de bord (glow) | **Rebond élastique** |
| Feuille modale | Feuille Material | **Poignée + carte empilée** (l'écran du dessous recule et s'arrondit) |
| Menu contextuel | Menu Material | **Feuille d'action** |
| Onglets internes | Onglets Material | **Contrôle segmenté** |
| Interrupteur | Switch Material | **Switch iOS** |
| Bouton d'action | **FAB** | Bouton dans la barre — **pas de FAB sur iOS** |
| Cible tactile min. | 48 × 48 dp | **44 × 44 pt** |
| Mise à l'échelle | `textScaleFactor` jusqu'à 2,0 | **Dynamic Type**, mêmes bornes |

### 15.1 La seule règle de rendu qui diverge

> **Le flou d'arrière-plan est interdit sur Android, autorisé sur iOS.**

Sur Mali-G52, un `BackdropFilter` est le premier poste d'effondrement du framerate (§5). Sur le parc iOS, le flou est peu coûteux, natif, et *attendu* — une barre opaque y a l'air d'un portage bâclé. La règle devient conditionnelle à la plateforme, pas absolue.

Corollaire : les barres translucides, les matériaux et l'élévation par superposition sont des moyens **iOS uniquement**. Sur Android, l'élévation reste tonale.

### 15.2 Ce qui reste interdit sur les deux

Les dégradés sur surfaces de contenu, le néomorphisme, les carrousels pleine largeur dans les listes, les deux boutons terracotta, les fonctions grisées. La texture iOS n'est pas une permission de décorer.

### 15.3 Impact sur le code

- `pageTransitionsTheme` doit déclarer `CupertinoPageTransitionsBuilder` pour iOS et `FadeUpwardsPageTransitionsBuilder` pour Android — `app_theme.dart` n'en déclare qu'un aujourd'hui.
- Les rayons deviennent dépendants de la plateforme : `Radii` doit exposer une variante, ou les composants doivent lire la plateforme.
- Les physiques de défilement suivent `ScrollConfiguration` par plateforme.
- `main.dart` verrouille l'orientation en portrait — à conserver sur les deux, mais la visionneuse 360 doit pouvoir déverrouiller localement.

### 15.4 Contrainte de chaîne de production

**Aucun build ni test iOS n'est possible depuis Windows.** Il faut un Mac, ou un runner macOS (Codemagic, GitHub Actions, Bitrise). Tant que ce n'est pas en place, tout ce qui est écrit ici pour iOS est **du design non vérifié** : il ne faut pas le rapporter autrement.
