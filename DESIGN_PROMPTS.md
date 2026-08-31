# 🎨 EAZYRENT — Prompts de design de l'application mobile (v2)

**Corrige la v1**, qui oubliait 28 écrans sur 44 — dont **toute l'authentification** et **l'intégralité du profil démarcheur**. Inventaire complet : `SCREEN_ROLE_MATRIX.md`.

**Nouveau dans cette version :**
- **Trois profils** — Locataire (T), Démarcheur (D), Propriétaire (P). L'agence est une variante de P, pas un quatrième profil.
- **iOS ET Android.** Chaque écran se demande en deux rendus. La décision « Android-first, iOS différé » de la v1 est annulée.
- Les 6 écrans d'authentification, les 9 écrans locataire manquants, les 6 écrans propriétaire, les 5 écrans démarcheur.

**À utiliser avec :** n'importe quel générateur d'interface (v0, Lovable, Figma AI, Stitch, Uizard, Galileo, Claude). Agnostique d'outil.

---

## 0 · Le prompt-socle — à coller en tête de chaque session

```
Tu conçois EAZYRENT, une application mobile pour le Bénin (Cotonou,
Abomey-Calavi), publiée sur Android ET iOS.

CE QUE FAIT LE PRODUIT
On paie 1 000 FCFA pour visiter un logement en 360° depuis chez soi, au lieu
de payer 2 000 F de moto-taxi et de démarcheur pour découvrir sur place que
le bien est déjà loué. La valeur n'est pas la technologie 360 : c'est la
PREUVE qu'un bien existe, est conforme, et est encore libre.

TROIS PROFILS, TROIS APPLICATIONS DANS UNE
· LOCATAIRE  — cherche, visite, garde, candidate. Navigation à 4 onglets.
· DÉMARCHEUR — apporte des biens, suit ses commissions. Navigation à 3 onglets.
· PROPRIÉTAIRE — publie, reçoit des demandes, encaisse. Navigation à 3 onglets.
Ils ne partagent que : authentification, messages, réglages, fiche de bien.

CONTEXTE D'USAGE — la contrainte qui décide de tout
Debout, dehors, en plein soleil, à une main. Sur Android : téléphone
d'entrée de gamme (Tecno/Infinix/itel, 2-4 Go de RAM), data payée à l'unité.
Sur iOS : parc plus récent, surtout la diaspora et les propriétaires aisés.

SYSTÈME VISUEL — identique sur les deux plateformes
· Fond clair #F8FAFC / cartes #FFFFFF / fond sombre #0B0F19
· Texte principal #0B0F19 sur clair, #F8FAFC sur sombre
· Texte secondaire #55617A sur clair (jamais plus clair)
· Action (terracotta) : #C4321A en texte sur clair, #D93A1F en remplissage
  avec label blanc, #FF4D2E uniquement sur fond sombre
· Succès / vérifié : #006B4A en texte sur clair, #00E599 sur sombre seulement
· Information / 360 : #00708A sur clair, #00B4D8 sur sombre seulement
· Titres : Plus Jakarta Sans Bold/ExtraBold. Corps et chiffres : Inter,
  chiffres tabulaires.
· Échelle : 32 / 28 / 22 / 18 / 16 (plancher de lecture) / 14 / 13.
· Espacement base 4. Gouttière 16. Écart entre cartes 12.

CE QUI CHANGE ENTRE LES DEUX PLATEFORMES — la « texture »
ANDROID (Material 3)
· Rayons 16 cartes / 24 feuilles / pilule boutons
· Barre d'onglets Material, bouton d'action flottant
· Retour par le geste système et la flèche en haut à gauche
· Feuilles modales Material, poignée discrète
· Défilement à effet de bord (glow), pas de rebond
· Séparateurs 1 dp
· AUCUN flou d'arrière-plan : le GPU d'entrée de gamme ne suit pas
· Élévation par ombre douce

iOS (texture Cupertino)
· Rayons 12-14 sur les cartes, 20 sur les feuilles — plus serré qu'Android
· Grand titre qui se replie en titre compact au défilement
· Retour par « ‹ Retour » libellé en haut à gauche + geste de balayage
· Feuilles modales avec poignée de préhension et effet de carte empilée
  (l'écran du dessous recule légèrement et s'arrondit)
· Défilement avec REBOND élastique
· Séparateurs cheveu 0,33 pt, avec retrait aligné sur le contenu
· FLOU AUTORISÉ : barres translucides, matériaux. C'est attendu sur iOS
  et le GPU le supporte.
· Élévation par superposition et flou, pas par ombre portée
· Feuilles d'action (action sheets) au lieu des menus Material
· Contrôles segmentés au lieu des onglets Material
· Interrupteurs style iOS
· Respect de la zone sûre et de la barre d'accueil en bas

INTERDITS ABSOLUS (les deux plateformes)
✗ Photos en bandeau pleine largeur dans les listes
✗ Plus d'un bouton terracotta par écran
✗ Texte blanc sur #FF4D2E (contraste 3,31:1, échoue les normes)
✗ Émeraude ou cyan comme couleur de texte sur fond clair (1,58:1 et 2,36:1)
✗ Les mots « VR », « immersif », « panorama », « escrow », « séquestre »
✗ Un état vide sans bouton d'action
✗ Une fonction verrouillée affichée en grisé — elle n'existe pas à l'écran
✗ Une couleur qui porte seule une information (toujours couleur + icône + mot)
✗ Une zone tactile sous 48×48 (Android) ou 44×44 pt (iOS)

LANGUE
Français simple, tutoiement, phrases courtes. Montants en FCFA sans décimale,
séparateur de milliers : « 35 000 F ».
```

**Comment demander les deux rendus.** Ajoutez systématiquement en fin de prompt d'écran :

> *« Produis deux versions côte à côte : **Android Material 3** et **iOS Cupertino**, en respectant les différences de texture du prompt-socle. Le contenu, la hiérarchie et les couleurs sont identiques ; seule la chrome change. »*

---

# PARTIE A · Authentification — l'oubli le plus grave

Elle est commune aux trois profils. C'est ici que les parcours se séparent.

## A1 · L'aiguillage d'entrée

```
Premier écran après le démarrage, mode clair.

Une phrase en très gros : « Arrête de payer le zem pour rien. »
Une ligne de corps : « Vois le logement en entier avant de te déplacer. »

Puis TROIS choix, pas deux, en cartes empilées avec icône à gauche :
  🔎  Je cherche un logement            → aucune inscription demandée
  🏠  J'ai un bien à louer
  🤝  J'apporte des biens (démarcheur)

Sous les trois, un lien discret, souligné : « J'ai déjà un compte »

RÈGLE : « Je cherche un logement » n'exige RIEN. Il mène directement aux
trois questions. Les deux autres mènent à la création de compte, parce que
leur première action est de donner quelque chose au système — s'identifier
n'y est pas ressenti comme un péage.
```

## A2 · Création de compte

```
Écran de création de compte, mode clair.

En haut : le profil déjà choisi, affiché comme une puce modifiable
(« 🏠 Propriétaire · changer »).

Un seul champ visible : le numéro de téléphone, avec l'indicatif +229
préfixé et non modifiable, et un formatage automatique par groupes de deux
(« 97 12 34 56 »). Clavier numérique.

Sous le champ, une ligne fine : « On t'envoie un code par SMS. »

Une case à cocher NON pré-cochée :
  « J'accepte les conditions et la politique de données »
  avec les deux mots soulignés et cliquables.

Bouton principal en bas : « Recevoir mon code ».

Sous le bouton, un lien : « J'ai déjà un compte → Connexion ».

INTERDITS : pas de mot de passe, pas d'e-mail, pas de nom demandé à
cette étape. Le nom est demandé plus tard, quand il sert.
```

## A3 · Saisie du code

```
Écran de saisie de code OTP, mode clair.

Titre : « Entre le code »
Sous-titre : « Envoyé au +229 97 12 34 56 · modifier »

Six cases carrées séparées, remplissage automatique depuis le SMS.
Grand chiffre centré dans chaque case. La case active porte une bordure
terracotta de 2.

Sous les cases : « Renvoyer le code dans 0:42 » — le compte à rebours devient
un bouton « Renvoyer le code » actif à zéro, et il est PROLONGEABLE : au
deuxième échec, proposer « Recevoir un appel à la place ».

État d'erreur : les six cases passent en bordure rouge, le texte devient
« Code incorrect. Il te reste 2 essais. » Aucun code technique.

Produis aussi l'état de chargement : les cases figées, un indicateur fin
sous elles, et le bouton désactivé AVEC sa raison affichée.
```

## A4 · Connexion

```
Écran de connexion, mode clair. Volontairement plus dépouillé que la
création de compte — quelqu'un qui revient sait ce qu'il fait.

Titre : « Content de te revoir »
Un seul champ : numéro de téléphone, indicatif +229 préfixé.
Bouton : « Recevoir mon code »
Deux liens sous le bouton :
  « Je n'ai plus ce numéro »
  « Créer un compte »

Pas d'illustration, pas de logo géant. Le champ est dans le tiers inférieur,
à portée de pouce.
```

## A5 · Numéro perdu

```
Écran de récupération de compte, mode clair.

Titre : « Tu n'as plus ce numéro ? »
Corps : « On peut retrouver ton compte. Dis-nous ton ancien numéro et ton
nouveau — un agent vérifie sous 24 h. »

Deux champs : ancien numéro, nouveau numéro.
Un champ optionnel : « Un détail qui prouve que c'est ton compte »
  (placeholder : « le quartier que tu cherchais, un bien que tu as visité »)

Bouton : « Envoyer la demande ».

Encadré d'information en bas, ton neutre :
« Tes crédits et tes visites payées suivent ton compte, pas ton numéro. »

C'est l'écran qui évite qu'un client payant soit perdu après un changement
de puce — pratique très courante au Bénin.
```

## A6 · Consentement et données

```
Écran de consentement, mode clair, apparaît une seule fois après l'OTP.

Titre : « Ce qu'on fait de tes données »

Trois blocs courts à icône, pas un pavé juridique :
  📱 Ton numéro sert à te connecter et à te prévenir. On ne le vend pas
     et on ne le montre pas aux autres utilisateurs.
  📍 Ta position sert à te montrer les biens proches. Tu peux refuser.
  🗂 Tes recherches restent sur ton téléphone.

Deux liens : « Conditions d'utilisation » · « Politique de données »
Un bouton principal : « J'ai compris »
Un lien discret : « Supprimer mon compte plus tard, c'est dans Réglages »

TON : factuel, pas rassurant à l'excès. Sur ce marché la méfiance vis-à-vis
de la revente de numéros est fondée ; la traiter frontalement est ce qui
crée la confiance.
```

## A7 · Amorces de permission

```
Trois petites feuilles modales, une par permission, à produire ensemble.
Chacune s'affiche AVANT la boîte de dialogue du système, jamais au lancement.

(a) LOCALISATION — déclenchée par « Autour de moi »
    Icône, titre « Voir les biens autour de toi »
    « On utilise ta position seulement quand tu appuies sur ce bouton. »
    [ Autoriser ]  [ Plus tard ]

(b) NOTIFICATIONS — déclenchée après l'activation d'une alerte quartier
    « Les bons biens partent en 48 h »
    « On te prévient dès qu'un bien correspond. 2 messages par jour maximum,
      jamais la nuit. »
    [ Me prévenir ]  [ Non merci ]

(c) MICRO — déclenchée au premier appui sur le bouton vocal
    « Réponds à la voix »
    « Plus rapide que taper. Ton message part seulement si tu l'envoies. »
    [ Autoriser ]  [ Écrire à la place ]

RÈGLE : le refus n'est jamais un cul-de-sac. Chaque feuille propose une
alternative fonctionnelle. Une permission refusée sans amorce est perdue à vie.
```

---

# PARTIE B · Locataire

Les six écrans du chemin principal restent ceux de la v1 (feed, fiche, visionneuse, paywall, duel, onboarding), avec le prompt-socle mis à jour. Voici **les neuf qui manquaient**.

## B1 · Mes passes et crédits

```
Écran, mode clair, accessible depuis Moi.

En haut, une carte en évidence :
  « 2 visites disponibles »
  en dessous, plus petit : « Ta visite offerte de la semaine arrive samedi »

Puis un bouton en contour : « Prendre un pack » (mène au paywall).

Puis l'historique, en liste simple, la plus récente en haut :
  ✓ Chambre-salon Fidjrossè      utilisée   12 mars
  ↩ Villa Cadjèhoun              remboursée · bien plus libre   10 mars
  🎁 Visite offerte              utilisée   8 mars
  ✓ Pack Quartier · 3 visites    2 500 F    8 mars

Les remboursements sont affichés en émeraude avec le motif en clair.
C'est l'écran qui prouve que la promesse de remboursement est tenue —
il vaut plus que la phrase qui l'annonce.
```

## B2 · Mes alertes et recherches

```
Écran, mode clair.

Une liste de cartes, une par recherche sauvegardée :
  ┌──────────────────────────────────────┐
  │ Fidjrossè, Cadjèhoun                 │
  │ 30 000 – 50 000 F · Chambre-salon    │
  │ 🔔 Alerte activée          [bascule] │
  │ 4 nouveaux depuis hier               │
  └──────────────────────────────────────┘

Chaque carte : un interrupteur d'alerte, un compteur de nouveautés
cliquable, un menu pour modifier ou supprimer.

État vide actif : « Sauvegarde une recherche pour être prévenu en premier. »
+ bouton « Aller chercher ».

Bouton d'action en bas : « Nouvelle recherche ».
```

## B3 · Signaler qu'un bien n'est plus libre

```
Feuille modale courte, mode clair.

Titre : « Ce bien n'est plus libre ? »
Corps : « Merci de le dire. On vérifie et on prévient les autres. »

Trois options en liste à sélection unique :
  ○ Le propriétaire dit qu'il est loué
  ○ Je suis passé sur place, c'est occupé
  ○ Personne ne répond depuis plusieurs jours

Bouton : « Envoyer »

PUIS, deuxième image, l'écran de confirmation — c'est lui qui compte :
  ✓ en émeraude, gros
  « Merci. On vérifie. »
  « 🎁 Tu gagnes une visite offerte. »
  bouton « Continuer à chercher »

Le signalement doit être ressenti comme une récompense, pas comme une
corvée. C'est l'inverse exact de l'expérience face à un démarcheur.
```

## B4 · Mon point d'ancrage

```
Écran, mode clair, proposé APRÈS la première visite terminée — jamais
pendant l'onboarding.

Titre : « D'où pars-tu tous les jours ? »
Corps : « On te dira le temps et le coût du trajet pour chaque logement. »

Un champ de recherche d'adresse, avec une carte en dessous et un repère
déplaçable.
Sous la carte, trois puces de type : 💼 Travail · 🎓 École · 🛒 Marché

Bouton : « Enregistrer »
Lien discret : « Plus tard »

Deuxième image : l'état renseigné, montrant l'ancrage enregistré et une
ligne « Tes biens gardés sont à 12–34 min » — la valeur rendue immédiatement.
```

## B5 · Centre de notifications

```
Écran, mode clair, accessible par une cloche dans l'en-tête du feed.

Liste chronologique, groupée par jour (« Aujourd'hui », « Hier »).
Les non-lues portent un point terracotta à gauche.

Chaque ligne : icône de type, texte complet sur deux lignes maximum,
horodatage relatif à droite.
  ⚡ Chambre-salon à Fidjrossè, 35 000 F. Visite 360 dispo.      il y a 20 min
  ✅ Le bien de Kpota est toujours libre — vérifié ce matin.      2 h
  🎁 Ta visite offerte de la semaine est là.                      hier

En haut à droite : « Tout marquer comme lu ».
En bas de liste, un lien : « Régler mes notifications ».

État vide : « Rien pour l'instant. Active une alerte quartier pour être
prévenu en premier. » + bouton.
```

## B6 · Réglages de notification par type

```
Écran de réglages, mode clair.

PAS un interrupteur unique. Une liste de types, chacun avec son
interrupteur ET une ligne qui dit ce qu'il fait :

  Nouveaux biens dans mes quartiers        [●]
    Dès qu'un bien correspond. Le plus utile.
  Baisse de prix sur mes biens gardés      [●]
  Disponibilité reconfirmée                [●]
    « Toujours libre » tous les 3 jours.
  Visite non terminée                      [○]
  Visite offerte de la semaine             [●]
  Rappels de rendez-vous                   [●]  ← non désactivable, grisé AVEC
                                                  la mention « toujours actif »
  Loyer et quittances                      [●]  ← idem

Un encadré en bas : « Maximum 2 messages par jour. Jamais entre 21 h et 7 h. »

Puis une section « Comment on te joint » :
  ○ Notification sur le téléphone
  ● WhatsApp    (recommandé pour le loyer et les quittances)
  ○ SMS         (si tu n'as pas internet)
```

## B7 · Aide, litige, signalement

```
Écran d'aide, mode clair.

Trois grandes cartes d'action en haut :
  💬 Écrire au support        réponse sous 24 h
  ⚠️ Signaler une annonce      fausse photo, faux prix, arnaque
  ⚖️ Ouvrir un litige          problème avec un propriétaire

Puis une liste de questions fréquentes, repliables :
  Comment marche la visite à 1 000 F ?
  Et si le bien n'est plus libre ?
  Comment je récupère mon argent ?
  Qui est l'agent qui filme ?

En bas, discret : numéro WhatsApp du support, cliquable.

Produis aussi l'écran « Signaler une annonce » : motif à choisir,
champ libre, possibilité de joindre une photo, bouton d'envoi.
```

## B8 · Suppression de compte et export

```
Écran, mode clair, au fond des réglages.

Titre : « Ton compte »

Deux actions, visuellement très différentes :
  [Bouton en contour]  Télécharger mes données
     « Tout ce qu'on a sur toi, en un fichier. »

  [Lien texte rouge]   Supprimer mon compte

Au clic sur la suppression, une feuille de confirmation qui dit la VÉRITÉ :
  « Supprimer ton compte, c'est définitif. »
  · Tes 2 visites en crédit seront perdues
  · Tes visites déjà payées ne seront plus accessibles
  · Ton historique de loyer sera conservé 5 ans (obligation légale)
  Champ : « Écris SUPPRIMER pour confirmer »
  [Supprimer définitivement]  [Annuler]

Ne jamais cacher ce que l'utilisateur perd.
```

## B9 · Historique de paiements

```
Écran, mode clair. Liste de transactions, chiffres tabulaires alignés
à droite.

  12 mars   Pack Quartier · 3 visites    MTN MoMo    2 500 F   ✓
  10 mars   Remboursement · bien loué    crédit      +1 000 F  ↩
   8 mars   Visite · Chambre-salon       Moov Flooz  1 000 F   ✓
   5 mars   Paiement échoué              MTN MoMo    —         ✗

Chaque ligne ouvre un reçu partageable : montant, opérateur, référence,
date, bien concerné, et un bouton « Partager le reçu ».

Les échecs sont affichés avec la mention « aucun montant débité » —
les laisser dans l'historique sans cette phrase créerait de l'inquiétude.
```

---

# PARTIE C · Propriétaire

Navigation à trois onglets : **🏠 Mes biens · 💬 Messages · 👤 Moi**. Pas de feed, pas de recherche.

## C1 · Tableau de bord bailleur

```
Écran d'accueil du profil propriétaire, mode clair.

En haut, une bande de trois chiffres, sans décor :
     3            47              2
  mes biens    vues 7 jours   demandes

Puis la liste de ses biens, en cartes :
  ┌──────────────────────────────────────────┐
  │ [photo]  Chambre-salon · Fidjrossè       │
  │          35 000 F /mois                  │
  │          👁 23 vues · 2 demandes de RDV   │
  │          ◉ Visite 360 active             │
  └──────────────────────────────────────────┘
  ┌──────────────────────────────────────────┐
  │ [photo]  Studio · Godomey                │
  │          25 000 F /mois                  │
  │          👁 4 vues · 0 demande            │
  │          ○ Photos seulement  → Booster    │
  └──────────────────────────────────────────┘

Le bien sans visite 360 porte un appel à l'action discret, pas agressif.

Bouton d'action en bas : « Publier un bien ».

État vide : « Publie ton premier bien. C'est gratuit et ça prend 2 minutes. »
```

## C2 · Mon annonce — la preuve de demande

```
Écran de détail d'une annonce, vue propriétaire, mode clair.

En haut, la photo et le prix, puis un bloc de statistiques SIMPLE :
  Cette semaine
    23 personnes ont vu ton bien
    6 l'ont gardé dans leur liste
    2 ont demandé un rendez-vous

Puis, SEULEMENT si le bien n'a pas encore de visite 360, un encadré
proposant le Pack Visibilité — et il ne se déclenche qu'après que la
demande a été prouvée :
  « 23 personnes ont vu ton bien cette semaine. »
  [ Ajouter une Visite Vérifiée — 5 000 F ]

⚠️ NE PAS écrire de statistique comparative (« 4× plus de demandes »)
tant qu'elle n'a pas été mesurée sur de vrais biens. Le prompt s'arrête
au chiffre réel.

Puis les actions : Modifier · Mettre en pause · Marquer comme loué.
```

## C3 · Demandes de rendez-vous reçues

```
Écran, mode clair. Liste de demandes, la plus récente en haut.

  ┌──────────────────────────────────────────┐
  │ [avatar]  Koffi A.        ◉ Vérifié      │
  │ Chambre-salon Fidjrossè                  │
  │ Demande : samedi 14 mars, 15 h           │
  │ 🎥 A déjà visité ton bien en 360         │  ← l'information qui compte
  │ [ Accepter ]   [ Proposer un autre ]     │
  └──────────────────────────────────────────┘

La mention « a déjà visité en 360 » est l'argument central pour le
propriétaire : elle lui dit que la personne ne vient pas en curieuse.
Elle doit être visible avant les boutons.

Onglets en haut : À traiter (2) · Acceptées · Passées.
```

## C4 · Demander un tournage 360

```
Feuille modale, mode clair.

Titre : « Fais filmer ton bien »
Corps : « Un agent EAZYRENT vient avec une caméra 360. Les visiteurs
voient tout le logement avant de se déplacer — tu ne reçois que des
gens sérieux. »

Prix affiché en grand : 5 000 F, une seule fois.

Trois lignes de ce qui est inclus, à icône :
  📸 Toutes les pièces filmées sur place
  ✅ Badge « Visite Vérifiée » sur ton annonce
  📅 Mise en avant 30 jours

Puis le choix du créneau : trois jours proposés avec des plages
(matin / après-midi).

Bouton : « Réserver — 5 000 F »
Sous le bouton : « Payable après le tournage. »

Ce dernier point est décisif : demander 5 000 F d'avance à un
propriétaire qui n'a encore rien reçu ferait échouer l'offre.
```

## C5 · KYC propriétaire

```
Écran de vérification, mode clair, en trois étapes avec une barre de
progression à trois segments.

Étape 1 — Ton identité
  Deux zones de dépôt : recto CNI, verso CNI. Aperçu après capture.
  Une ligne : « Photo nette, les 4 coins visibles. »

Étape 2 — Ta preuve sur le bien
  Un choix entre trois options, pas un champ libre :
    ○ Certificat de Propriété Foncière (CPF, délivré par l'ANDF)
    ○ Titre Foncier ancien régime
    ○ Mandat de gestion signé par le propriétaire
  Puis la zone de dépôt correspondante.

Étape 3 — Où on t'envoie l'argent
  Numéro Mobile Money, opérateur, nom du titulaire.

Écran final : « Vérification en cours — réponse sous 48 h »
avec ce qui reste possible entre-temps (publier oui, encaisser non).

Produis aussi l'état « Vérifié » : badge émeraude sur le profil,
et l'état « Refusé » avec le motif en clair et un bouton pour recommencer.
```

## C6 · Encaissements

```
Écran, mode clair.

En haut, un montant en très gros :
     145 000 F
  reçus ce mois-ci

En dessous, deux chiffres secondaires côte à côte :
  En attente 35 000 F   ·   Retard 0

Puis la liste des mouvements, chiffres tabulaires :
  12 mars  Loyer mars · Chambre-salon Fidjrossè   45 000 F  ✓
  12 mars  Commission EAZYRENT                    −4 500 F
  1 mars   Loyer mars · Studio Godomey            25 000 F  ✓

Chaque loyer reçu ouvre la quittance émise, téléchargeable.

Un bouton en contour en bas : « Exporter » (PDF / Excel).
```

---

# PARTIE D · Démarcheur

Le profil qui n'avait **aucun** écran. Navigation à trois onglets : **🤝 Mes apports · 💰 Gains · 👤 Moi**.

## D1 · Accueil apporteur

```
Écran d'accueil du profil démarcheur, mode clair.

En haut, le gain du mois en très gros, c'est la seule chose qui l'intéresse :
     12 000 F
  gagnés ce mois-ci

Une ligne dessous : « 4 biens publiés · 1 loué via l'app »

Puis un rappel du barème, en encadré discret et permanent :
  1 000 F par bien vérifié et publié
  3 000 F de plus si le bien est loué via l'app

Puis ses biens en cours, en cartes courtes avec statut coloré :
  Chambre-salon Fidjrossè     ✓ Publié          +1 000 F
  Villa Cadjèhoun             ⏳ En vérification
  Studio Agla                 ✗ Refusé · doublon

Bouton d'action, terracotta, très visible : « Apporter un bien ».

État vide : « Apporte ton premier bien. Tu gagnes 1 000 F dès qu'il est
vérifié. » + bouton.
```

## D2 · Apporter un bien

```
Formulaire court, mode clair, UN SEUL écran défilant — pas un assistant
en plusieurs étapes. Le démarcheur saisit debout, dans la rue.

Champs, dans cet ordre :
  Quartier            [puces : Fidjrossè, Agla, Godomey, Kpota, Autre]
  Type                [puces : Chambre, Chambre-salon, 2 ch-salon, Boutique]
  Loyer mensuel       [numérique, suffixe F]
  Avance demandée     [pas à pas : 1, 2, 3, 6, 12 mois]
  Photos              [zone de capture, 3 minimum, compteur visible]
  Contact du propriétaire  [téléphone]
  Note vocale         [gros bouton micro — plus rapide que taper]

Bouton en bas : « Envoyer — 1 000 F si vérifié »

Le montant DANS le bouton : c'est ce qui motive l'envoi.

Produis aussi l'écran de confirmation : « Bien envoyé. Un agent vérifie
sous 48 h. Tu seras prévenu. »
```

## D3 · Mes biens apportés

```
Écran de liste, mode clair, avec des onglets de statut en haut :
  Tous (12) · En vérification (2) · Publiés (8) · Refusés (2)

Chaque carte :
  [photo]  Chambre-salon · Fidjrossè · 35 000 F
           ✓ Publié le 8 mars          +1 000 F crédités
           👁 23 vues · 2 demandes

Pour un bien refusé, le motif est écrit en clair et sans jugement :
  « Refusé — ce bien était déjà dans l'application (apporté par
    quelqu'un d'autre le 2 mars). »

Un motif de refus flou fait perdre un apporteur. Or c'est lui qui
alimente le stock.
```

## D4 · Mes commissions

```
Écran, mode clair.

En haut :
     12 000 F     disponibles
      3 000 F     en attente de validation

Bouton principal : « Retirer sur MTN MoMo »

Puis l'historique, chiffres tabulaires :
  12 mars  Bien loué · Chambre-salon Fidjrossè   +3 000 F
   8 mars  Bien publié · Chambre-salon Fidjrossè +1 000 F
   5 mars  Retrait vers +229 97 12 34 56         −8 000 F  ✓

Un encadré en bas : « Les retraits partent sous 24 h. »

Et le respecter : un apporteur payé en retard part, et il en parle.
```

## D5 · KYC démarcheur

```
Deux étapes seulement — moins exigeant que le propriétaire, parce que
le démarcheur ne reçoit pas de fonds de tiers.

Étape 1 — Identité : recto/verso CNI.
Étape 2 — Où on t'envoie tes gains : numéro Mobile Money + nom du titulaire.

Écran final avec le badge « Apporteur vérifié » — le badge a une valeur
sociale réelle dans le quartier, il doit être beau et affichable.
Prévoir un bouton « Partager mon badge » qui génère une image carrée
partageable sur WhatsApp.
```

---

# PARTIE E · Rendus iOS spécifiques à demander

Trois écrans où la texture iOS change réellement quelque chose. À demander en plus des deux rendus systématiques.

```
(a) FEED en iOS
    Grand titre « Fidjrossè » qui se replie au défilement en titre compact
    centré, avec la barre de navigation qui devient translucide et laisse
    voir le contenu défiler derrière.
    Barre d'onglets du bas translucide, icônes fines style SF, libellés
    sous les icônes.
    Défilement avec rebond élastique en haut et en bas.
    Séparateurs cheveu 0,33 pt entre les cartes, avec un retrait aligné
    sur le texte, pas sur le bord de l'écran.

(b) PAYWALL en iOS
    Feuille modale qui monte en laissant voir l'écran du dessous RECULER
    et s'arrondir aux coins — l'effet de carte empilée d'iOS.
    Poignée de préhension grise centrée en haut de la feuille.
    Rayon de 20 en haut seulement.
    Les trois options de pack en liste groupée iOS : fond blanc, coins
    arrondis 12, séparateurs internes en retrait.

(c) MOI en iOS
    Liste groupée à sections, en style Réglages iOS : sections avec
    en-tête en petites majuscules grises, lignes à chevron à droite,
    interrupteurs style iOS.
    Comparer avec la version Android en liste Material plate.
```

---

## F · Comment corriger un résultat générique

Les cinq retours qui redressent un générateur, par ordre d'efficacité :

1. **« Tu m'as fait 2 biens par écran. Il m'en faut 4. Réduis la photo à une vignette de 112 à gauche et supprime tout l'espace décoratif. »**
2. **« Le prix n'est pas l'élément le plus visible de la carte. Remonte-le, grossis-le, et descends la photo dans la hiérarchie. »**
3. **« Tu as mis du texte blanc sur le terracotta. Contraste 3,31:1, ça échoue les normes. Fonce le fond à #D93A1F ou passe le label en #0B0F19. »**
4. **« Ta version iOS est une version Android avec une autre police. Applique la texture : grand titre repliable, rebond au défilement, séparateurs cheveu, feuille modale avec poignée et carte empilée. »**
5. **« Tu as grisé une fonction verrouillée. Elle ne doit pas exister à l'écran du tout. Retire-la. »**

Et le test final, à poser à chaque écran rendu :

> **Est-ce que je peux lire cet écran debout, dehors, en plein soleil, à une main ?**
> Si la réponse est non, le reste ne compte pas.

---

## G · Ordre de production

| # | Lot | Pourquoi dans cet ordre |
| :---: | :--- | :--- |
| 1 | **Feed + fiche de bien** | L'écran le plus vu fixe la densité, et la densité fixe tout le reste. |
| 2 | **Authentification (A1→A7)** | Bloque les trois profils. Rien d'autre ne peut être testé sans elle. |
| 3 | **Visionneuse 360 + paywall** | Le cœur. Une fois le langage visuel stable. |
| 4 | **Démarcheur (D1→D5)** | C'est le rôle qui alimente le stock. Sans stock, le feed est vide. |
| 5 | **Propriétaire (C1→C6)** | Sans lui, personne ne publie. |
| 6 | **Les 9 écrans locataire manquants** | Complètent le parcours. |
| 7 | **Rendus iOS spécifiques** | Une fois les écrans stabilisés — refaire la texture deux fois coûte cher. |

Concevoir l'onboarding en premier reste l'erreur classique : on soigne une porte d'entrée vers une maison qu'on n'a pas encore dessinée.
