# 📱 EAZYRENT — Spécification des écrans

**Dépend de :** `UI_DESIGN_SYSTEM.md` (règles), `UX_CORE_SPEC.md` (structure), `lib/core/theme/design_tokens.dart` (valeurs)
**Convention :** tout écran expose ses **5 états** (loading / empty / error / offline / partial). Toute cible tactile fait 48 dp minimum. Aucune valeur brute n'apparaît ici : les cotes citées renvoient aux tokens.

**Profondeur de spécification, assumée :** les écrans du chemin principal (S02, S05, S06, S07, S08, S09) sont spécifiés au pixel. Les écrans secondaires le sont au niveau de la structure et de la microcopie. Ce n'est pas un raccourci : c'est l'application de la règle de hiérarchisation (`UX_CORE_SPEC.md` §3) au travail de design lui-même.

---

## Carte des écrans

```
S00 Démarrage
 └─ S01 Onboarding (3 questions)
     └─ S02 ★ FEED ──────────────┬─ S03 Carte (même données, autre vue)
         │                        └─ S04 Filtres (feuille)
         ├─ S05 Fiche bien
         │   ├─ S06 ★ Visionneuse 360   ← le cœur
         │   │   └─ S07 Paywall / paiement
         │   └─ S11 Demande de RDV
         ├─ S08 Ma liste ─── S09 Duel ─── S13 Conseil de famille
         ├─ S10 Messages
         └─ S12 Moi (4 visages selon le palier)
                ├─ S14 Publier un bien (bascule bailleur)
                └─ S15 Mon logement (locataire installé)
```

---

## S00 · Démarrage

Aucun écran de marque animé. Le logo s'affiche sur `surfaceBase`, statique, le temps du démarrage — et disparaît dès que le premier bien est prêt. Un splash animé de 2 s est 2 s volées à quelqu'un qui cherche un toit.

**Reprise :** si une recherche existe, on ouvre directement **S02** avec le cache, et on rafraîchit en arrière-plan. On ne repasse jamais par l'onboarding.

---

## S01 · Onboarding — 3 questions, 90 secondes

```
┌─────────────────────────────────┐   ┌─────────────────────────────────┐
│                                 │   │  ← retour            ● ○ ○      │
│                                 │   │                                 │
│   Arrête de payer le zem        │   │  Tu cherches où ?               │  titleL
│   pour rien.                    │   │                                 │
│                        displayL │   │  ┌───────────┐ ┌──────────────┐ │
│                                 │   │  │ Fidjrossè │ │ Cadjèhoun    │ │  chips 48dp
│   Vois le logement en entier    │   │  └───────────┘ └──────────────┘ │
│   avant de te déplacer.         │   │  ┌──────┐ ┌────────┐ ┌────────┐ │
│                          bodyL  │   │  │ Agla │ │ Godomey│ │ Kpota  │ │
│                                 │   │  └──────┘ └────────┘ └────────┘ │
│                                 │   │  ┌─────────────────────────────┐│
│                                 │   │  │ ◎  Autour de moi            ││
│  ┌───────────────────────────┐  │   │  └─────────────────────────────┘│
│  │       Commencer           │  │   │  ┌───────────────────────────┐  │
│  └───────────────────────────┘  │   │  │       Continuer           │  │  zone du pouce
└─────────────────────────────────┘   └─────────────────────────────────┘
```

**Q2** — budget : curseur 15 000 → 300 000 F, valeur affichée en `amountL`, pas de saisie clavier (ouvrir un clavier dans un onboarding fait perdre des utilisateurs).
**Q3** — type : Chambre · Chambre-salon · 2 ch-salon · Appartement · Boutique. Vocabulaire local, pas « T2 / F3 ».

**Attente assumée entre Q3 et le feed** — 2 s maximum, avec le quartier de l'utilisateur nommé : *« On regarde ce qui est libre à Fidjrossè… »*. Une attente courte, expliquée et personnalisée augmente la valeur perçue du résultat. Au-delà de 3 s, elle la détruit : au-delà, on bascule sur le feed en squelette.

**Décisions**
- Un point de progression discret (● ○ ○), jamais une barre : trois questions ne méritent pas une barre de progression.
- Retour toujours possible. Aucune question obligatoire n'est verrouillée.
- **Aucune demande de numéro, aucune permission système à ce stade.** La géolocalisation n'est demandée qu'au moment où l'utilisateur touche « Autour de moi » — et la demande explique pourquoi en une phrase.

---

## S02 · ★ Feed — l'écran d'atterrissage permanent

```
┌────────────────────────────────────────────┐
│ Fidjrossè · 30–50k · Chambre-salon    ⚙︎ 🗺 │  barre de recherche vivante
├────────────────────────────────────────────┤
│ ⚡ 4 nouveaux depuis hier                   │  bandeau, cliquable, disparaît une fois vu
├────────────────────────────────────────────┤
│ ┌────────┐ 35 000 F /mois                  │
│ │        │ Chambre-salon · Fidjrossè       │
│ │ photo  │ ◉ Vérifié aujourd'hui 09h12     │  success + icône + mot
│ │  [360] │ Entrée : 245 000 F · 3 mois av. │  LE chiffre décisif
│ └────────┘ ~22 min de ton travail       ♡  │
├────────────────────────────────────────────┤
│ ┌────────┐ 42 000 F /mois                  │
│ │ photo  │ Chambre-salon · Fidjrossè       │
│ │        │ ○ Vérifié il y a 6 jours        │  warn : la fraîcheur se dégrade visiblement
│ │  [360] │ Entrée : 294 000 F · 3 mois av. │
│ └────────┘ ~18 min de ton travail       ♡  │
├────────────────────────────────────────────┤
│ ┌────────┐ 28 000 F /mois                  │
│ │ photo  │ Chambre · Fidjrossè             │
│ │        │ ○ Photos seulement              │  pas de 360 : dit franchement
│ └────────┘ Entrée : 168 000 F · 3 mois av. │
├────────────────────────────────────────────┤
│         ╭──────────────────────╮           │
│         │  🔔  Alerte quartier │           │  FAB unique, contextuel
│         ╰──────────────────────╯           │
├────────────────────────────────────────────┤
│  🔎 Chercher   ⭐ Ma liste   💬   👤        │
└────────────────────────────────────────────┘
```

**Hiérarchie de lecture (dans l'ordre, imposé) :** prix → type et quartier → fraîcheur → coût d'entrée → temps de trajet → photo. La photo est en dernier volontairement : elle sert à disqualifier vite, pas à décider.

**Ce que l'écran refuse d'afficher :** le titre rédigé par le bailleur (« Belle chambre-salon moderne bien située » n'informe personne), la surface en m² (rarement fiable et rarement connue), le nombre de vues.

**Tri par défaut :** fraîcheur de publication, puis pertinence par rapport à la recherche. **Jamais** de tri par « mise en avant payée » sans le dire — un bien sponsorisé porte la mention `Sponsorisé` en clair.

**Le bandeau « 4 nouveaux depuis hier »** est la micro-victoire A1 (`UX_CORE_SPEC.md` §7.1). Il ne s'affiche que s'il y a réellement du nouveau, et disparaît une fois lu. Un bandeau permanent devient invisible en trois jours.

**Les 5 états**

| État | Rendu |
| :--- | :--- |
| loading | 4 squelettes à la silhouette exacte de `ListingCard`. `itemExtent` déjà fixé : aucun saut au remplacement. |
| empty | *« Aucun bien à Fidjrossè sous 40 000 F. »* + **Élargir à Godomey (12 biens)** + **Créer une alerte**. Jamais un cul-de-sac. |
| error | *« On n'arrive pas à charger. »* + **Réessayer** + les derniers biens en cache, datés. |
| offline | Bandeau persistant + feed en cache avec sa date. Les tours payés restent ouvrables. |
| partial | Un bien sans photo affiche un aplat `surfaceSunken` avec le type de logement en toutes lettres — pas une icône d'image cassée. |

---

## S03 · Carte

**Ce n'est pas un onglet, c'est une bascule** (`UX_CORE_SPEC.md` §5.2). L'icône 🗺 de la barre de recherche permute liste ⇄ carte sur les **mêmes** résultats filtrés.

- Marqueurs = pastilles de prix (`35k`), pas des épingles. Le prix est l'information, pas la position.
- Badge 360 en cyan sur la pastille quand le bien a une Visite Vérifiée.
- Carrousel horizontal en bas, synchronisé dans les deux sens avec la caméra (`ARCHITECTURE.md` §7.1).
- Marqueur sélectionné : agrandissement + halo terracotta + haptique. **C'est le seul « glow » autorisé de l'application, et sur un seul élément à la fois.**
- Regroupement au dézoom, avec le **nombre** de biens, jamais un point anonyme.

---

## S04 · Filtres — feuille modale

Ordre imposé, du plus décisif au moins décisif pour ce marché :

1. **Coût total d'entrée** — curseur, avec la phrase *« Ce que tu peux sortir aujourd'hui »*. Placé **avant** le loyer : c'est le vrai filtre.
2. Loyer mensuel
3. Nombre de mois d'avance acceptés
4. Type de logement
5. Quartiers (multi-sélection)
6. **Visite Vérifiée disponible** — interrupteur
7. Électricité : compteur à carte / post-payé / sous-compteur partagé
8. Eau : SONEB / forage / château / aucune
9. Zone inondable : exclure
10. Voie bitumée

Le compteur de résultats est **vivant** : *« 14 biens »* se met à jour à chaque changement, avant validation. On ne fait jamais découvrir un résultat vide après avoir fermé la feuille.

**Réinitialiser** est toujours présent, en `ghost`, jamais en danger.

---

## S05 · Fiche bien

```
┌────────────────────────────────────────────┐
│  ←                                  ♡  ⤴   │  partage = action de premier rang
├────────────────────────────────────────────┤
│                                            │
│         PHOTO PRINCIPALE  16:9             │
│                                            │
│      ╭──────────────────────────────╮      │
│      │  ▶  Visiter en 360°          │      │  ← cyan, sur la photo
│      ╰──────────────────────────────╯      │
├────────────────────────────────────────────┤
│  35 000 F /mois                    displayM│
│  Chambre-salon · Fidjrossè, Cotonou        │
│                                            │
│  ◉ Vérifié disponible aujourd'hui 09h12    │  success
│    par Rachid, agent EAZYRENT     [photo]  │  un humain identifiable
│                                            │
├─ CE QUE TU PAIES POUR ENTRER ──────────────┤
│    Avance      3 mois        105 000 F     │  tabulaire, aligné à droite
│    Caution     1 mois         35 000 F     │
│    Frais                     105 000 F     │
│    ──────────────────────────────────      │
│    Total                     245 000 F     │  amount, ink-strong
│    ⓘ Prix ferme, engagement du bailleur    │
├─ L'ESSENTIEL ──────────────────────────────┤
│  ⚡ Compteur à carte, individuel            │
│  💧 SONEB, eau courante                     │
│  🛣 Voie bitumée · non inondable            │
│  🚶 ~22 min de ton travail (zem)            │
├─ LES PIÈCES ───────────────────────────────┤
│  [○][○][○][○][○][○]  6 pièces filmées      │
├────────────────────────────────────────────┤
│  ┌──────────────┐ ┌───────────────────────┐│
│  │ Demander RDV │ │  ▶ Visiter en 360°    ││  action unique en terracotta
│  └──────────────┘ └───────────────────────┘│
└────────────────────────────────────────────┘
```

**Décisions**
- **Le bloc « Ce que tu paies pour entrer » est le deuxième bloc de l'écran**, avant les caractéristiques. C'est ce qui décide.
- **L'agent est nommé et montré.** « Vérifié par Rachid » avec sa photo bat n'importe quel badge logotypé : on fait confiance à une personne, pas à un tampon.
- **Un seul bouton terracotta.** « Demander RDV » est secondaire — visiter d'abord, se déplacer ensuite. C'est tout le produit résumé dans une hiérarchie de boutons.
- **Le partage est en haut à droite, en premier rang.** Le partage WhatsApp est le canal d'acquisition n°1 (`GROWTH_MONETISATION.md` §4.3) ; l'enterrer dans un menu à trois points coûterait des utilisateurs chaque jour.
- Si le bien n'a **pas** de Visite Vérifiée : le bouton devient *« Demander une visite 360 »* — signal de demande qui déclenche la décision de tournage (règle « aucun bien tourné à l'aveugle »).

---

## S06 · ★ Visionneuse 360 — le cœur du produit

### 6a — Preview gratuite (le seul verrou volontairement visible)

```
┌────────────────────────────────────────────┐
│  ✕                          Salon · 1/6    │
│                                            │
│      ░░░░░░░░  vision nette  ░░░░░░░░      │
│    ░░░░░                          ░░░░░    │  flou progressif au-delà de 90°
│  ░░░                                  ░░░  │
│                                            │
│        ↺  Tourne ton téléphone             │  invite gyroscope, 1 fois
│                                            │
├────────────────────────────────────────────┤
│  Tu vois 1 pièce sur 6.                    │
│  ┌──────────────────────────────────────┐  │
│  │   Voir tout le logement — offert 🎁  │  │  1re visite : offert
│  └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

Le flou n'est pas un cache posé dessus : c'est un **dégradé radial appliqué au rendu**, de sorte qu'on devine qu'il y a quelque chose sans pouvoir le lire. C'est la boucle ouverte du produit (effet Zeigarnik) et le réglage qui pilote directement le taux de conversion — **à instrumenter dès le premier jour** (`UX_CORE_SPEC.md` §12.5).

### 6b — Tour complet

```
┌────────────────────────────────────────────┐
│  ✕     ████████░░░░  4/6 pièces      ⚙ ⤓   │  progress-fill, la micro-victoire
│                                            │
│                                            │
│              ↗ Chambre 1                   │  hotspot cyan, 48dp de cible
│                                            │
│                        ↘ Cuisine           │
│                                            │
│                                            │
│  ┌──┐                                      │
│  │▣ │  mini-plan                           │  position courante en terracotta
│  └──┘                                      │
├────────────────────────────────────────────┤
│  Salon  Ch.1  Ch.2  Cuisine  Douche  Cour  │  pastilles, vues = pleines
└────────────────────────────────────────────┘
```

Au passage de la 6/6 :

```
        ╭──────────────────────────────╮
        │   ✓  Tour complet            │
        │                              │
        │   Tu as tout vu de ce        │
        │   logement sans bouger.      │
        │                              │
        │   💰 6 500 F économisés      │
        │      ce mois-ci              │
        │                              │
        │   ┌────────────────────────┐ │
        │   │  Garder ce bien        │ │
        │   └────────────────────────┘ │
        │        Continuer à chercher  │
        ╰──────────────────────────────╯
```

**Décisions**
- **Chrome minimal.** Une croix, une progression, deux icônes. Le panorama occupe tout. Chaque élément d'interface superposé vole de la surface au seul contenu pour lequel l'utilisateur a payé.
- **La progression est en haut et permanente.** C'est le gradient d'objectif qui fait terminer les tours — et un tour terminé est la métrique nord.
- **Les hotspots sont des cibles de 48 dp** même quand le repère visuel fait 24 dp. Un hotspot manqué trois fois de suite fait quitter le tour.
- **⤓ télécharge le tour** pour l'hors-ligne, avec son poids affiché avant. On a payé, on possède.
- **Alternative accessible obligatoire** dans ⚙ : « Voir en photos fixes » — la liste des pièces avec une photo par pièce et sa légende. Sans elle, un trouble vestibulaire ou un GPU trop faible exclut du cœur du produit.
- **Fallback matériel :** si le rendu descend sous 20 fps pendant 3 s, l'app propose d'elle-même le mode photos fixes. Elle ne laisse jamais l'utilisateur face à un tour saccadé en se disant qu'il a mal payé.

---

## S07 · Paywall et paiement

```
┌────────────────────────────────────────────┐
│                                       ✕    │
│   Voir tout le logement                    │  titleL
│                                            │
│   Un aller-retour te coûte ~2 000 F.       │  ancrage : le chiffre déclaré par
│   Cette visite : 1 000 F.                  │  l'utilisateur lui-même
│                                            │
│   ┌──────────────────────────────────────┐ │
│   │ ● 1 visite                  1 000 F  │ │
│   ├──────────────────────────────────────┤ │
│   │ ○ Pack Quartier — 3 visites 2 500 F  │ │  cible
│   │   soit 833 F la visite      ÉCONOMIE │ │
│   ├──────────────────────────────────────┤ │
│   │ ○ Pack Chasseur — 7 visites 5 000 F  │ │  ancre haute
│   └──────────────────────────────────────┘ │
│                                            │
│   Paye avec                                │
│   ┌────────┐ ┌────────┐ ┌────────┐         │
│   │  MTN   │ │  Moov  │ │Celtiis │         │  logos + noms
│   │  MoMo  │ │ Flooz  │ │  Cash  │         │
│   └────────┘ └────────┘ └────────┘         │
│                                            │
│   ⓘ Si ce bien n'est plus libre, on te     │  levée d'objection AVANT le paiement
│     rend ta visite automatiquement.        │
│   ⓘ Accès permanent + hors-ligne.          │
├────────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐  │
│  │          Payer 1 000 F               │  │  montant dans le bouton
│  └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

**Décisions**
- **Le montant est écrit dans le bouton.** Un bouton « Continuer » sur un écran de paiement est une trahison.
- **Les deux garanties sont posées avant le paiement, pas après.** Le remboursement automatique et l'accès permanent sont les deux objections réelles ; les traiter à l'avance évite l'abandon plutôt que de le réparer.
- **Trois options, jamais plus** (paradoxe du choix). L'option médiane est la cible ; l'option haute existe pour la rendre évidente.
- **L'opérateur est mémorisé** après le premier paiement et présélectionné ensuite.

### États du paiement — le plus critique de l'app

```
en attente ──▶ ┌───────────────────────────────┐
               │  📲 Regarde ton téléphone.     │
               │                               │
               │  Valide le paiement de        │
               │  1 000 F sur MTN MoMo.        │
               │                               │
               │  ⏱ 1:42                       │  compte à rebours, prolongeable
               │                               │
               │  Rien n'est débité tant que   │  la phrase qui rassure
               │  tu n'as pas validé.          │
               │                               │
               │        Annuler                │
               └───────────────────────────────┘

échec ───────▶ « Le paiement n'a pas abouti.
                 Aucun montant n'a été débité. »
                 [ Réessayer avec MTN ]  [ Essayer avec Moov ]

succès ──────▶ transition directe vers le tour complet.
                 Pas d'écran de félicitations : le succès,
                 c'est le contenu qui s'ouvre.
```

L'échec Mobile Money est fréquent (solde, réseau, expiration USSD). **Un échec non rattrapé fait perdre l'utilisateur définitivement**, avec le sentiment d'avoir perdu son argent. La bascule d'opérateur proposée d'office est ce qui récupère la transaction.

---

## S08 · Ma liste

```
┌────────────────────────────────────────────┐
│  Ma liste                                  │
│  ┌──────────┬──────────┬─────────────────┐ │
│  │ Gardés 4 │ Visitées │ RDV 1           │ │
│  └──────────┴──────────┴─────────────────┘ │
├────────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐  │
│  │  ⚔  Comparer 2 biens                 │  │  n'apparaît qu'à partir de 2
│  └──────────────────────────────────────┘  │
├────────────────────────────────────────────┤
│  [carte bien]  ◉ Toujours libre (hier)  ⋮  │
│  [carte bien]  ⚠ Plus libre ? Dis-le     ⋮  │  signalement 1 tap
│  [carte bien]  ◉ Toujours libre (2 j)   ⋮  │
├────────────────────────────────────────────┤
│  💰 Tu as économisé 6 500 F ce mois-ci     │
│     5 visites faites depuis chez toi       │
└────────────────────────────────────────────┘
```

**État vide, actif :** *« Garde un bien ici pour le comparer plus tard. »* + bouton **Retour au feed**.

Le compteur d'économies est en **bas**, pas en haut : c'est une récompense qu'on découvre après avoir vu son travail, pas un score qu'on vient consulter.

---

## S09 · Le Duel — comparateur binaire

```
┌────────────────────────────────────────────┐
│  ←   Lequel tu gardes ?              1/3   │
├─────────────────────┬──────────────────────┤
│      [photo A]      │      [photo B]       │
│                     │                      │
│   35 000 F /mois    │   42 000 F /mois     │
│   Fidjrossè         │   Cadjèhoun          │
│                     │                      │
│   Entrée 245 000 F  │   Entrée 294 000 F   │  ← écart mis en évidence
│   ◉ Libre aujourd'h.│   ○ Libre il y a 6 j │
│   ~22 min travail   │   ~18 min travail    │
│   Compteur à carte  │   Sous-compteur ⚠    │
│   SONEB             │   Forage             │
│                     │                      │
│  ┌───────────────┐  │  ┌────────────────┐  │
│  │  Je garde A   │  │  │  Je garde B    │  │
│  └───────────────┘  │  └────────────────┘  │
├─────────────────────┴──────────────────────┤
│           Les deux · Aucun des deux        │
└────────────────────────────────────────────┘
```

Deux à la fois, jamais un tableau à cinq colonnes : au-delà de deux options simultanées, la décision se bloque (loi de Hick). Les lignes où les deux biens diffèrent sont mises en valeur ; les lignes identiques sont atténuées — on ne compare que ce qui distingue.

À la fin : **« Ton finaliste : le bien de Fidjrossè. »** → propose la demande de RDV. C'est la micro-victoire A4 poussée jusqu'à sa conclusion.

---

## S10 · Messages

Liste standard, deux particularités justifiées par le marché :

- **Notes vocales de premier rang.** Bouton micro à côté du champ de saisie, même taille que l'envoi. Taper au clavier sur un Tecno, debout dehors, est lent ; parler ne l'est pas.
- **Réponses suggérées** contextuelles au bien : « Le bien est-il toujours libre ? » · « L'avance est-elle négociable ? » · « Je peux visiter samedi ? ». Elles évitent l'angoisse de la page blanche, qui est la première cause de conversation jamais démarrée.
- Statut de l'interlocuteur en clair : `Bailleur vérifié` / `Agent EAZYRENT` / `Agence`. Jamais un pseudonyme nu.

---

## S11 · Demande de RDV

Créneaux proposés par le bailleur, pas un sélecteur de date libre — un sélecteur libre produit des demandes qui ne conviennent à personne.

```
Samedi 14 mars    [ 09h ] [ 11h ] [ 15h ]
Dimanche 15 mars  [ 10h ] [ 16h ]
```

Après envoi : *« Demande envoyée. **Tu y vas en sachant déjà tout.** »* — la phrase relie explicitement le RDV à la visite 360 déjà faite. C'est la micro-victoire A6.

Rappels : J-1 à 18 h, puis J-2 h, avec l'itinéraire. Canal WhatsApp en priorité.

---

## S12 · Moi — quatre visages selon le palier

L'onglet change de contenu selon le palier de découverte progressive (`UX_CORE_SPEC.md` §10.1). **Rien n'est affiché en grisé** : une fonction verrouillée n'existe simplement pas à l'écran.

```
P1 ÉVEILLÉ            P2 CHASSEUR           P3 CANDIDAT          P4 LOCATAIRE
─────────────         ─────────────         ─────────────        ─────────────
Mes visites  1/1      Visites     3         Mon dossier  70%     ▸ MON LOGEMENT
Alerte quartier ○     Crédits     2         RDV          1       Loyer mars
Économies    1 000F   Économies  6 500F     Argent bloqué ⓘ         45 000 F
                      Parrainage             Économies             [ Payer ]
Thème / Léger         Thème / Léger         Thème / Léger        Quittances (3)
                                                                  État des lieux
                                                                  Mon bailleur
```

Le passage P3 → P4 est le plus délicat : c'est là qu'on demande de l'argent réel et des documents. **« Argent bloqué » est expliqué avant d'être proposé**, en trois phrases avec un cas chiffré (`UX_CORE_SPEC.md` §10.3), jamais sous forme de formulaire.

---

## S13 · Conseil de famille

Depuis **Ma liste** → ⤴ **Demander l'avis de quelqu'un**. Génère un lien partageable sur WhatsApp.

Le destinataire ouvre une **page web légère** (pas d'installation exigée) : les 2 à 4 biens gardés, leurs photos, leurs coûts d'entrée, et un vote en un geste. Les votes reviennent dans l'app.

Deux effets simultanés : la décision de logement est **collective** au Bénin (conjoint, parents, aîné de la famille) — un produit qui l'ignore fait décider l'utilisateur hors de l'app. Et chaque partage est une exposition gratuite auprès d'une personne qualifiée. Détail complet et validation UX : `FEATURES_V2.md` F5.

---

## S14 · Publier un bien (bascule bailleur)

**Quatre champs, un écran :** quartier · loyer · type · téléphone. Publication immédiate en annonce simple, sans photo obligatoire.

L'offre de tournage 360 n'arrive **pas** à ce moment. Elle arrive quand le bailleur a constaté la demande :

> *« 23 personnes ont vu ton bien cette semaine. Avec une Visite Vérifiée, les biens reçoivent en moyenne 4× plus de demandes de RDV. »*
> ⚠️ Le facteur cité doit être **mesuré sur les 50 premiers biens**, jamais inventé. Tant qu'il n'est pas mesuré, la phrase s'arrête à « 23 personnes ont vu ton bien cette semaine ».

---

## S15 · Mon logement — locataire installé

L'écran qui porte la rétention longue durée (12 à 36 mois), et celui que la v1.0 du produit laissait sortir du parcours après la signature.

```
┌────────────────────────────────────────────┐
│  Mon logement · Fidjrossè                  │
├────────────────────────────────────────────┤
│  Loyer de mars              45 000 F       │
│  À payer avant le 5 mars                   │
│  ┌──────────────────────────────────────┐  │
│  │   Payer avec MTN MoMo                │  │
│  └──────────────────────────────────────┘  │
│  Quittance immédiate après paiement        │
├────────────────────────────────────────────┤
│  Quittances       ▸  3 disponibles         │
│  État des lieux   ▸  signé le 12/01        │
│  Mon bail         ▸  PDF                   │
│  Mon bailleur     ▸  Message               │
│  Signaler un problème  ▸                   │
└────────────────────────────────────────────┘
```

La quittance arrive **immédiatement** après le paiement, téléchargeable et partageable. C'est la preuve tangible qui construit la confiance mois après mois — et qui rend le départ vers un paiement en espèces coûteux.

---

## Récapitulatif des décisions structurantes

| Décision | Ce qu'elle sert |
| :--- | :--- |
| Le prix et le coût d'entrée sur la carte du feed | Le critère qui élimine 80 % des biens ne se mérite pas en cliquant |
| Photo en vignette, pas en bandeau | 4 biens par écran au lieu de 2 |
| Un seul bouton terracotta par écran | La hiérarchie survit |
| Partage en premier rang sur la fiche | Le canal d'acquisition n°1 n'est pas enterré |
| Preview floutée = seul verrou visible | Le moteur de conversion |
| Montant écrit dans le bouton de paiement | Aucune surprise |
| Garanties posées avant le paiement | On évite l'abandon au lieu de le réparer |
| Bascule d'opérateur d'office à l'échec | On récupère la transaction et l'utilisateur |
| Duel à deux, jamais un tableau | La décision ne se bloque pas |
| Alternative photos fixes au tour 360 | Personne n'est exclu du cœur du produit |
| Poids affiché avant tout téléchargement | Le coût en données est payé par l'utilisateur, pas par nous |
