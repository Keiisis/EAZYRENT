# 🧩 EAZYRENT — Fonctionnalités complémentaires v2

**Règle d'admission :** une fonctionnalité n'entre que si elle **sert la Visite Vérifiée** (`UX_CORE_SPEC.md` §2) et si elle passe **les 10 règles UX** sans trou. Une fonctionnalité qui n'a pas de micro-victoire, pas de place dans le flow, ou pas de palier de révélation n'est pas une fonctionnalité : c'est un écran de plus.

Huit retenues. Onze écartées, listées en §10 avec leur motif — la discipline se mesure autant à ce qu'on refuse.

**Grille de validation, appliquée à chacune :**

| # | Règle |
|---|---|
| 1 | Quel problème précis ? |
| 2 | Comment elle sert la fonctionnalité principale |
| 3 | Niveau de hiérarchie |
| 4 | Place dans le User Flow |
| 5 | Impact sur la navigation principale |
| 6 | Chemins secondaires ouverts |
| 7 | Action clé et micro-victoire |
| 8 | Notification intelligente associée |
| 9 | Impact sur l'onboarding |
| 10 | Palier de découverte progressive |

---

## F1 · Le Coût Total d'Entrée

### Ce que c'est
Chaque bien affiche **le vrai chiffre** : avance + caution + frais, additionnés, en gros, sur la carte du feed et en deuxième bloc de la fiche. Assorti d'un filtre inversé — **« Ce que je peux sortir aujourd'hui »** — qui trie non pas par loyer, mais par ce que l'utilisateur a réellement en main.

Un bien à 35 000 F/mois avec 6 mois d'avance coûte 280 000 F à l'entrée. Un bien à 45 000 F avec 2 mois d'avance en coûte 135 000 F. **Le second est moins cher, et le tri par loyer le classe après.** Tous les sites du marché trient par loyer. Aucun ne dit combien il faut sortir.

### Pourquoi c'est indispensable au Bénin
L'avance est la douleur n°1 en montant (`AUDIT_COHERENCE_BENIN.md` §3). Un chercheur passe des semaines sur des biens qu'il ne peut pas payer parce que l'information décisive n'est nulle part. C'est la fonctionnalité qui fait gagner le plus de temps par ligne de code.

### UI
Sur la carte : `Entrée : 245 000 F · 3 mois av.` Sur la fiche : bloc détaillé aligné à droite, chiffres tabulaires, mention **Prix ferme** quand le bailleur s'engage. Filtre placé **au-dessus** du loyer dans la feuille (S04).

### Validation
| # | |
|---|---|
| 1 | On perd des semaines sur des biens qu'on ne peut pas payer, faute de connaître le montant d'entrée. |
| 2 | Évite d'acheter une Visite Vérifiée pour un bien inaccessible — protège la promesse et le taux de remboursement. |
| 3 | **Niveau 1** — sert directement le cœur. |
| 4 | Entre le feed et la fiche, avant toute décision de déblocage. |
| 5 | Aucun écran nouveau. Une ligne sur la carte, un bloc sur la fiche, un curseur dans les filtres. |
| 6 | « Bien hors budget d'entrée » → proposer les biens à avance réduite du même quartier. |
| 7 | **« 3 biens sont accessibles avec ce que tu as. »** — passer d'une liste décourageante à une liste atteignable est une victoire réelle. |
| 8 | *« Un bien à Fidjrossè demande seulement 2 mois d'avance — 135 000 F d'entrée. »* Fait nouveau, personnel, actionnable. |
| 9 | **Non.** La règle des 3 questions tient. Le budget d'entrée est demandé au palier P2, quand l'utilisateur sait ce qu'il cherche. |
| 10 | Affichage dès **P0**. Le filtre inversé apparaît en **P2**. |

**Base de données :** `advance_months`, `total_move_in_cost`, `is_price_firm` — déjà ajoutés au schéma v2.0.

---

## F2 · Le Pouls — la fraîcheur, et son signalement en un geste

### Ce que c'est
Deux moitiés indissociables.

**Côté affichage :** chaque bien porte son état de fraîcheur, précis et daté. `◉ Vérifié aujourd'hui 09h12` → `○ Vérifié il y a 6 jours` → `⚠ Non confirmé depuis 12 jours`. La dégradation est visible ; on ne prétend jamais qu'un bien de 12 jours est aussi sûr qu'un bien du matin.

**Côté contribution :** sur tout bien gardé ou visité, un bouton d'un seul geste — **« Ce bien n'est plus libre »**. Deux signalements concordants déclenchent une re-vérification par l'agent ; le signalement confirmé rapporte **une visite offerte** à celui qui l'a fait.

### Pourquoi c'est le plus intelligent des huit
La fraîcheur est *la* promesse du produit et son poste de coût le plus lourd : re-confirmer 200 biens par quartier chaque semaine mobilise un agent à plein temps. Le signalement communautaire fait faire ce travail par ceux qui le découvrent naturellement — les chercheurs eux-mêmes — pour un coût marginal proche de zéro.

Et il retourne un incident en actif : celui qui signale ne subit plus la mauvaise nouvelle, **il est récompensé pour elle**. C'est de la réciprocité, et c'est le contraire exact de l'expérience qu'on a face à un démarcheur.

### Garde-fou
Le signalement ne retire jamais un bien seul. Deux signalements indépendants ⇒ re-vérification ; seul l'agent ou le bailleur retire. Sans cela, un concurrent efface le catalogue en une soirée.

### Validation
| # | |
|---|---|
| 1 | On se déplace, ou on paie une visite, pour un bien déjà loué. |
| 2 | **C'est le composant n°2 de la Visite Vérifiée.** Sans lui, on vend le tour d'un bien peut-être parti. |
| 3 | **Niveau 1.** |
| 4 | Sur la carte du feed, sur la fiche, dans Ma liste après le déblocage. |
| 5 | Aucun écran nouveau. Un badge, un bouton dans Ma liste. |
| 6 | Signalement → re-vérification → soit crédit rendu à tous les acheteurs du tour, soit confirmation « toujours libre » envoyée. |
| 7 | **« Merci. On vérifie. Tu gagnes une visite. »** Micro-victoire immédiate sur ce qui était une déception. |
| 8 | *« ✅ Le bien de Kpota est toujours libre — vérifié ce matin. »* à J+3 d'une mise en liste : la notification de confiance, qui relance sans rien vendre. |
| 9 | Aucun. |
| 10 | Badge dès **P0**. Signalement à **P1**, dès qu'un bien est gardé. |

**Base de données :** `availability_checks` (déjà ajoutée), + `availability_reports` à créer.

---

## F3 · Le Duel

### Ce que c'est
Deux biens côte à côte, plein écran, et une seule question : **lequel tu gardes ?** On élimine, on recommence, on obtient un finaliste. Jamais un tableau à cinq colonnes.

Les lignes où les deux biens diffèrent sont mises en valeur ; les lignes identiques sont atténuées. On ne compare que ce qui distingue.

### Pourquoi binaire
Un tableau comparatif à cinq entrées produit de la paralysie, pas de la décision (loi de Hick). Le duel force une préférence à chaque tour, exactement comme on choisit dans la vraie vie : par élimination, pas par tableur.

### Validation
| # | |
|---|---|
| 1 | Après 4 ou 5 visites, on ne sait plus lequel était le meilleur — et on finit par n'en choisir aucun. |
| 2 | Convertit des Visites Vérifiées consommées en **décision**. Sans lui, la valeur produite s'évapore. |
| 3 | **Niveau 2** — convertit la visite en action. |
| 4 | Après 2 biens gardés, avant la demande de RDV. |
| 5 | Vit dans **Ma liste**, n'ajoute pas d'onglet. Le bouton n'apparaît qu'à partir de 2 biens gardés. |
| 6 | « Les deux » (on garde et on reprend plus tard) · « Aucun des deux » (on retourne au feed avec les critères ajustés). |
| 7 | **« Ton finaliste : le bien de Fidjrossè. »** Puis proposition de RDV. La liste devient une décision. |
| 8 | Aucune notification propre — le Duel se déclenche dans l'app, pas depuis l'extérieur. **Une fonctionnalité n'a pas droit à une notification simplement parce qu'elle existe.** |
| 9 | Aucun. |
| 10 | **P2**, à 2 biens gardés. |

---

## F4 · Notes vocales

### Ce que c'est
Le micro à côté du champ de saisie, **de la même taille que le bouton d'envoi**, dans trois endroits : le chat avec le bailleur, une note personnelle attachée à un bien gardé, et la description d'annonce côté bailleur.

### Pourquoi c'est structurel et pas cosmétique
Taper au clavier sur un Tecno d'entrée de gamme, debout dehors, une main sur un sac, est lent et pénible. Parler ne l'est pas. Le vocal est déjà le mode dominant sur WhatsApp au Bénin — on n'introduit pas un usage, on cesse de le contrarier.

Trois gains distincts :
- **Chat** : plus de conversations démarrées, moins d'abandons devant la page blanche.
- **Note sur un bien** : *« la douche est dehors, mais la cour est calme »* — dit en 4 secondes, jamais écrit. Cette note est aussi de l'**investissement** : plus on annote, plus on est attaché à sa liste.
- **Annonce bailleur** : un bailleur qui ne rédige pas peut publier quand même. C'est du stock gagné.

### Contrainte technique
Opus mono 16 kHz, ~2 Ko/s. 30 secondes ≈ 60 Ko. Durée plafonnée à 60 s. Lecture en cache. Transcription automatique **non** au MVP : elle échoue sur le français local mêlé de fon et produirait des contresens.

### Validation
| # | |
|---|---|
| 1 | Écrire coûte cher en temps et en effort ; beaucoup de conversations et de notes n'existent jamais pour cette seule raison. |
| 2 | Une note vocale attachée à un bien visité en 360 conserve l'impression du tour — sans elle, cinq tours se confondent en trois jours. |
| 3 | **Niveau 2.** |
| 4 | Après la visite (note), et dans la mise en relation (chat). |
| 5 | Aucun écran nouveau. Un bouton dans deux composants existants. |
| 6 | Sans réseau : la note s'enregistre localement et part à la reconnexion, comme les photos d'état des lieux. |
| 7 | *« Note ajoutée. »* Silencieux. Le gain est de pouvoir la réécouter au moment du Duel. |
| 8 | Aucune. |
| 9 | Aucun. |
| 10 | Chat à **P2**. Notes sur bien à **P1**. Annonce vocale bailleur à **P5**. |

---

## F5 · Le Conseil de famille

### Ce que c'est
Depuis Ma liste : **« Demander l'avis de quelqu'un »** → un lien WhatsApp. Le destinataire ouvre une **page web légère, sans installation** : 2 à 4 biens, photos, coûts d'entrée, quartier, et un vote en un geste. Les votes remontent dans l'app.

### Pourquoi c'est la plus sous-estimée des huit
**Au Bénin, on ne choisit pas un logement seul.** Le conjoint, un parent, un aîné de la famille pèsent dans la décision — souvent depuis une autre ville, parfois depuis l'étranger. Aujourd'hui cette conversation a lieu **hors de l'application**, par captures d'écran envoyées sur WhatsApp. Le produit perd le contrôle du moment le plus décisif de son propre parcours.

La ramener dans le produit fait trois choses d'un coup :
1. La décision se prend avec les bonnes informations (coût d'entrée, fraîcheur) au lieu d'une capture d'écran floue.
2. Chaque partage expose la marque à une personne **qualifiée**, gratuitement.
3. L'utilisateur qui a engagé sa famille dans sa recherche ne l'abandonne plus. C'est l'investissement le plus fort que le produit puisse produire.

### La page web est un vrai livrable, pas un lot de consolation
< 100 Ko, sans framework, ouverte dans le navigateur intégré de WhatsApp, lisible sur n'importe quel téléphone. Elle ne montre **pas** les tours 360 complets — seulement les previews. Le pass reste le pass.

### Validation
| # | |
|---|---|
| 1 | La décision est collective, mais l'outil est individuel. La conversation décisive se tient ailleurs, sans les bonnes données. |
| 2 | Ce qu'on partage, ce sont des biens qu'on a **visités en 360**. La fonctionnalité met en valeur exactement ce qu'on a produit. |
| 3 | **Niveau 2.** |
| 4 | Après le Duel ou en parallèle, avant la demande de RDV. |
| 5 | Une action de partage dans Ma liste. Les votes reviennent dans **Messages**. Aucun onglet nouveau. |
| 6 | Le votant sans compte peut voter · s'il installe, sa voix est rattachée et le parrainage s'applique · s'il n'installe pas, le vote compte quand même. **On ne prend jamais la famille en otage pour forcer une installation.** |
| 7 | **« Ta sœur a voté pour le bien de Fidjrossè. »** Une voix extérieure qui confirme est une victoire émotionnelle forte. |
| 8 | *« 2 personnes ont donné leur avis sur ta liste. »* — fait nouveau, personnel, actionnable. |
| 9 | Aucun. |
| 10 | **P2**, à partir de 2 biens gardés — le même seuil que le Duel. |

**Base de données :** `shared_shortlists`, `shortlist_votes` à créer.

---

## F6 · Ton point d'ancrage

### Ce que c'est
L'utilisateur pose **un lieu qui compte** : son travail, l'école des enfants, le marché. Chaque bien affiche alors *« ~22 min de ton travail »*, en zémidjan, aux heures réelles.

### Pourquoi ça vaut plus qu'une carte
À Cotonou, la distance à vol d'oiseau ne veut rien dire : entre Fidjrossè et Akpakpa, le pont change tout. Ce que l'utilisateur veut savoir n'est pas « où est le bien » mais **« combien de temps et combien de francs par jour, tous les jours, pendant deux ans »**.

Complément fort : afficher aussi le **coût mensuel du trajet**. Un bien 5 000 F moins cher mais 15 minutes plus loin coûte plus cher à la fin du mois. Personne ne calcule ça, et tout le monde le subit.

### Pourquoi la question n'est pas dans l'onboarding
La règle des trois questions tient (`UX_CORE_SPEC.md` §9.2). Une quatrième question, plus intime, posée avant toute valeur reçue, coûterait plus d'utilisateurs qu'elle n'en servirait. Elle est posée **après la première visite terminée**, au moment où l'utilisateur a une raison de répondre.

### Validation
| # | |
|---|---|
| 1 | On choisit un logement sans savoir ce que le trajet coûtera chaque jour pendant deux ans. |
| 2 | Filtre en amont de la visite : on ne dépense pas 1 000 F pour un bien à 50 minutes de son travail. |
| 3 | **Niveau 2.** |
| 4 | Après la première visite terminée, en enrichissement du feed. |
| 5 | Une ligne sur la carte du feed. Un tri « le plus proche de mon travail ». Aucun écran nouveau. |
| 6 | Point d'ancrage non renseigné → la ligne n'existe pas, aucun espace vide. Plusieurs ancrages possibles (travail + école) en P3. |
| 7 | **« 4 de tes biens gardés sont à moins de 20 min. »** |
| 8 | *« Nouveau bien à 12 min de ton travail, 38 000 F. »* — la formulation la plus performante possible pour ce marché : un fait, une distance, un prix. |
| 9 | **Non.** Posée à P2, jamais à l'onboarding. |
| 10 | **P2.** Ancrages multiples à **P3**. |

---

## F7 · La Visite Guidée en Direct

### Ce que c'est
Un créneau réservé, un agent EAZYRENT sur place, un appel vidéo. L'utilisateur dit *« montre-moi derrière la porte »*, *« ouvre le robinet »*, *« fais voir le compteur »*. L'agent obéit.

### Pourquoi c'est indispensable pour un segment précis
Le tour 360 répond à *« à quoi ça ressemble »*. Il ne répond pas à *« est-ce que ça coule »*, *« est-ce que ça sent »*, *« qui sont les voisins »*. Deux publics ont besoin de cette réponse et ne peuvent pas l'obtenir autrement :
- **La diaspora** — le segment au consentement à payer le plus élevé, aujourd'hui totalement dépendant d'un cousin ou d'un démarcheur (`GROWTH_MONETISATION.md` §2.6).
- **Le finaliste local** — celui qui hésite entre deux biens et veut vérifier un point précis avant de se déplacer.

C'est aussi la seule fonctionnalité de la liste qui **augmente directement le revenu par utilisateur** : 5 000 F l'appel local, inclus dans l'offre Recherche à distance à 25 000 F.

### Contrainte assumée
Elle dépend de la disponibilité d'un agent : c'est un service, pas un bouton. Créneaux limités, affichés honnêtement, jamais promis en instantané.

### Validation
| # | |
|---|---|
| 1 | Le tour 360 ne répond pas aux questions qu'on ne peut poser qu'à quelqu'un présent sur place. |
| 2 | Prolongement direct : on ne la propose qu'**après** un tour terminé, sur un bien déjà en liste. |
| 3 | **Niveau 2.** |
| 4 | Après le Duel, sur le finaliste, avant ou à la place du déplacement. |
| 5 | Depuis la fiche d'un bien déjà débloqué et depuis Ma liste. Aucun onglet. |
| 6 | Aucun créneau → mise en liste d'attente avec notification · Réseau insuffisant → bascule audio + l'agent envoie des photos en direct. |
| 7 | **« Tu as tout vérifié sans faire le déplacement. »** Pour la diaspora, c'est davantage : la première fois qu'ils voient un logement de leurs propres yeux. |
| 8 | Rappel J-1 et H-1 du créneau. Rien d'autre. |
| 9 | Aucun. |
| 10 | **P3** en local. Proposée dès **P1** aux comptes détectés hors du Bénin — leur parcours est différent et leur urgence est réelle. |

---

## F8 · Plein Soleil et Mode Léger

### Ce que c'est
Deux interrupteurs dans **Moi**, et la seule fonctionnalité de cette liste qui ne se voit pas quand elle marche.

**Plein Soleil** — troisième thème, cible AAA (≥ 7:1), surfaces aplaties, typographie montée d'un cran, cibles tactiles à 56 dp, images éclaircies. Proposé automatiquement quand le capteur de luminosité dépasse un seuil — **proposé, jamais imposé** : un basculement non consenti désoriente.

**Mode Léger** — activé par défaut hors Wi-Fi. Vignettes 240 px, aucun préchargement, et surtout : **le poids est affiché avant tout téléchargement** — *« Ce tour = 8 Mo. Télécharger ? »*

### Pourquoi ce n'est pas de l'accessibilité en option
On utilise cette application **dehors, en plein jour, sur data payée à l'unité**. Une interface illisible au soleil n'est pas une gêne, c'est une interface inutilisable la moitié du temps. Un tour qui consomme 30 Mo sans prévenir n'est pas une maladresse, c'est de l'argent pris sans le dire.

Afficher le coût en données avant de le dépenser est une marque de respect que ce marché reconnaît immédiatement — et qu'aucune application immobilière ne pratique.

### Validation
| # | |
|---|---|
| 1 | L'écran est illisible dehors ; les données coûtent cher et se consomment sans prévenir. |
| 2 | Protège directement le moment de vérité : un tour payé qu'on ne peut pas regarder au soleil, ou qu'on n'ose pas charger, est un tour perdu. |
| 3 | **Niveau 1** — c'est une condition d'usage du cœur, pas un confort. |
| 4 | Transversal, présent partout. |
| 5 | Deux interrupteurs dans **Moi**. Aucun écran nouveau. |
| 6 | Hors Wi-Fi → Léger par défaut · Forte luminosité → Plein Soleil proposé une fois, puis mémorisé · Tour déjà téléchargé → jamais re-téléchargé. |
| 7 | **« Ce tour est à toi. Tu peux le revoir sans réseau. »** — la promesse « on a payé, on possède », rendue concrète. |
| 8 | Une seule, contextuelle : *« Tu es en 4G. Mode Léger activé — tes tours téléchargés restent disponibles. »* |
| 9 | Aucun. Les valeurs par défaut sont bonnes dès le premier lancement. |
| 10 | Actif dès **P0**, réglages visibles à partir de **P1**. |

---

## 9. Synthèse — hiérarchie et séquence

```
★ NIVEAU 0 — La Visite Vérifiée

NIVEAU 1 (conditionne le cœur)
  F1 Coût Total d'Entrée      ← protège le taux de remboursement
  F2 Le Pouls + signalement   ← EST le composant fraîcheur
  F8 Plein Soleil / Léger     ← condition d'usage réelle

NIVEAU 2 (convertit la visite en décision)
  F3 Le Duel
  F4 Notes vocales
  F5 Conseil de famille
  F6 Point d'ancrage
  F7 Visite Guidée en Direct
```

**Ordre de construction imposé** (règle §3 : un niveau N n'entre pas avant N−1 livré et mesuré) :

| Rang | Fonctionnalité | Justification du rang |
| ---: | :--- | :--- |
| 1 | **F1** Coût d'entrée | Le plus de temps gagné par ligne de code |
| 2 | **F2** Pouls + signalement | Sans elle, la promesse du produit est fausse |
| 3 | **F8** Plein Soleil / Léger | Condition d'usage, pas confort |
| 4 | **F3** Le Duel | Transforme la valeur produite en décision |
| 5 | **F4** Notes vocales | Faible coût, fort effet d'attachement |
| 6 | **F6** Point d'ancrage | Enrichit le feed, dépend d'une donnée à collecter |
| 7 | **F5** Conseil de famille | Nécessite la page web légère |
| 8 | **F7** Visite en Direct | Dépend d'agents disponibles : service avant logiciel |

### Ce qu'il faut ajouter au schéma

```sql
availability_reports  -- F2 : signalements, 2 concordants -> re-vérification
voice_notes           -- F4 : chat, notes sur bien, annonces
shared_shortlists     -- F5 : listes partagées
shortlist_votes       -- F5 : votes, avec ou sans compte
user_anchors          -- F6 : points d'ancrage + coût de trajet
live_tour_slots       -- F7 : créneaux d'agents
live_tour_bookings    -- F7 : réservations
```

---

## 10. Écartées — et pourquoi

Une liste de refus est aussi utile qu'une liste d'ajouts : elle empêche que ces idées reviennent à chaque réunion.

| Idée | Motif du refus |
| :--- | :--- |
| **Tirelire pour l'avance** (épargne progressive vers le montant d'entrée) | L'idée est excellente et adresse la douleur n°1. Mais détenir l'épargne d'un tiers relève de la réglementation BCEAO, exactement comme le séquestre. **Bloquée par la même contrainte que R-1.** À reprendre en version non financière (objectif + rappels, sans détenir un franc) ou via un partenaire IMF. |
| **Score de compatibilité par IA** | Une note sur 100 générée par un modèle est invérifiable. Vendre de la certitude qu'on ne peut pas prouver, sur un produit dont la promesse est la preuve, est incohérent. |
| **Gamification par séries quotidiennes** | Chercher un logement est épisodique. Une série culpabilise et ne correspond à aucune valeur réelle (`UX_CORE_SPEC.md` §7.4). |
| **Fil social / commentaires publics sur les biens** | Ouvre la porte à la diffamation, au sabotage entre bailleurs, à la modération à plein temps. Coût de gouvernance sans rapport avec le gain. |
| **Estimation automatique du loyer « juste »** | Pas assez de données transactionnelles fiables au Bénin. Un chiffre faux détruirait la crédibilité de tous les autres chiffres affichés. |
| **Réalité augmentée pour placer ses meubles** | Aucun rapport avec la douleur. Coûteux, spectaculaire, inutile. |
| **Chat vocal en direct avec le bailleur** | Le bailleur ne veut pas être appelé toute la journée : c'est justement ce qu'il fuit. Le chat asynchrone protège les deux parties. |
| **Notation des bailleurs par les locataires** | Exposition juridique lourde, faible volume au départ, risque de représailles hors application dans un marché où tout le monde se connaît. |
| **Mode Casque VR au MVP** | Parc de casques quasi nul. Conservé pour la démonstration terrain uniquement. |
| **Widget d'écran d'accueil** | Peu utilisé sur les surcouches Android d'entrée de gamme, coût de maintenance disproportionné. |
| **Programme de fidélité à points** | Les crédits de visite jouent déjà ce rôle, en étant directement convertibles en valeur d'usage. Une seconde monnaie ne ferait qu'embrouiller. |
