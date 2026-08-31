# 📋 EAZYRENT — Epics & Stories

**Méthode :** BMAD — décomposition du PRD et de l'architecture en stories porteuses de valeur, avec critères d'acceptation vérifiables.
**Dépend de :** `CONSTITUTION.md`, `APP_STRUCTURE.md`, `UX_CORE_SPEC.md`, `UI_SCREENS_SPEC.md`, `FEATURES_V2.md`.

**Convention de story**

- **AC** — critères d'acceptation. Vérifiables par une observation ou une commande, jamais par une impression.
- **Ψ** — levier psychologique mobilisé, nommé. Une story qui porte un levier sans le nommer est une story qu'on optimisera plus tard dans le mauvais sens.
- **📊** — événement d'analytique. Une story sans événement est une story livrée à moitié (P12).
- **Palier** — à partir de quel palier la fonctionnalité existe à l'écran (P10).

**Portée de détail, assumée.** Les 9 epics du MVP sont détaillées en stories avec critères. Les 4 epics post-MVP sont définies au niveau epic, avec les titres de leurs stories mais **sans critères d'acceptation** : détailler un niveau N+1 avant que le niveau N soit livré et mesuré viole la règle de hiérarchisation (`UX_CORE_SPEC.md` §3.1). C'est une décision, pas un oubli — `GATES.md` G21.

---

# PÉRIMÈTRE MVP

## E0 · Socle technique et design system

> **Valeur :** rien ne se construit avant que les frontières soient posées. Le socle est la seule epic sans valeur utilisateur directe, et la seule qu'on ne peut pas différer.

### E0.1 · Squelette Flutter conforme à la spec
- **AC1** `flutter analyze` passe sans avertissement en mode strict.
- **AC2** L'arborescence correspond exactement à `APP_STRUCTURE.md` §4, y compris `features/escrow/` vide et non câblé.
- **AC3** Les 3 flavors (`dev`, `staging`, `prod`) se construisent.
- **AC4** Aucune clé secrète dans le dépôt ni dans l'APK.
- **AC5** La CI échoue si l'APK dépasse `PerfBudget.apkMaxBytes`.
- 📊 —

### E0.2 · Thème à trois modes depuis les tokens
- **AC1** Clair, sombre et Plein Soleil se construisent depuis `AppPalette`, sans une seule couleur brute ailleurs.
- **AC2** Le mode Plein Soleil est proposé quand la luminosité dépasse le seuil — **proposé, jamais imposé**, et le refus est mémorisé.
- **AC3** Un test automatisé vérifie que toute paire texte/fond de chaque thème atteint 4,5:1 (7:1 en Plein Soleil).
- **AC4** L'interface reste utilisable à `textScaleFactor` 2,0 sur les 6 écrans du chemin principal.
- 📊 `SunlightModeToggled`

### E0.3 · Atomes et molécules à 8 états
- **AC1** `AppButton`, `AppInput`, `AppChip` implémentent les 8 états, dont `offline`.
- **AC2** Un état `disabled` affiche toujours **une raison**. Un bouton grisé sans explication échoue la revue.
- **AC3** `ListingCard` mesure exactement `Sizes.listingCardHeight` — condition de l'`itemExtent` fixe.
- **AC4** Tests golden sur `ListingCard` : 3 thèmes × 2 échelles de texte.
- 📊 —

### E0.4 · Les trois modules d'UX
- **AC1** `StageResolver` calcule le palier depuis des faits ; aucun drapeau de palier n'existe en base.
- **AC2** `StageGate` rend l'enfant ou `SizedBox.shrink()`. **Aucun chemin de code ne produit un état grisé.**
- **AC3** `NotificationPolicy.evaluate()` est le seul point d'émission ; tout refus est motivé et instrumenté.
- **AC4** `MomentBus` émet les 8 moments nommés ; aucune logique de célébration n'est dupliquée dans un widget.
- **AC5** Couverture unitaire ≥ 90 % sur ces trois modules.
- 📊 `NotificationSuppressed`

---

## E1 · Découverte sans compte

> **Valeur :** amener un inconnu au moment de vérité en moins de 90 secondes, sans lui demander quoi que ce soit.
> **Ψ d'ensemble :** réciprocité — on donne d'abord.

### E1.1 · Onboarding en trois questions
- **AC1** Trois questions maximum : quartier, budget, type. Une quatrième échoue la revue.
- **AC2** Aucun compte, aucune permission système demandée. La géolocalisation n'est sollicitée qu'au toucher de « Autour de moi », avec sa raison en une phrase.
- **AC3** Le budget se règle au curseur, sans clavier.
- **AC4** Le délai avant le feed nomme le quartier de l'utilisateur et ne dépasse jamais 3 s ; au-delà, bascule sur le feed en squelette.
- **AC5** Retour possible à chaque étape.
- **Ψ** Énergie d'activation minimale · loi de Hick.
- 📊 `OnboardingFinished`
- **Palier** P0

### E1.2 · Feed dense et lisible
- **AC1** 4 `ListingCard` visibles sur un écran de 6,1 pouces à échelle de texte 1,0.
- **AC2** Ordre de lecture imposé : prix → type et quartier → fraîcheur → coût d'entrée → trajet → photo.
- **AC3** Le titre rédigé par le bailleur n'est **pas** affiché.
- **AC4** Un bien sponsorisé porte la mention `Sponsorisé` en clair.
- **AC5** Les 5 états d'écran sont implémentés ; l'état vide propose toujours **deux** issues (élargir, alerter).
- **AC6** Premier écran utile en moins de 1,5 s sur 3G bridée.
- 📊 `PreviewOpened` (au niveau de la fiche)
- **Palier** P0

### E1.3 · Bascule carte
- **AC1** La carte est une bascule de la barre de recherche, **pas un onglet**.
- **AC2** Marqueurs = pastilles de prix ; badge 360 en cyan quand la Visite Vérifiée existe.
- **AC3** Synchronisation bi-directionnelle carrousel ⇄ caméra.
- **AC4** Le halo terracotta n'existe que sur le marqueur sélectionné, un seul à la fois.
- 📊 —
- **Palier** P2

### E1.4 · Filtres ordonnés par pouvoir de décision
- **AC1** Le **coût total d'entrée** est le premier filtre, placé au-dessus du loyer.
- **AC2** Le compteur de résultats se met à jour à chaque changement, avant validation.
- **AC3** Aucun chemin ne mène à un résultat vide découvert après fermeture de la feuille.
- 📊 —
- **Palier** P0

### E1.5 · Lien profond depuis WhatsApp
- **AC1** `eazyrent.bj/b/{id}` ouvre la fiche directement, **sans compte**.
- **AC2** Sans l'application installée : page web légère (< 100 Ko) avec la preview et l'invitation à installer.
- **AC3** Un code de parrainage est **saisissable manuellement**, pas seulement transporté par le lien — l'APK se partage aussi de main en main.
- **Ψ** Preuve sociale — le partage vient d'un proche, pas d'une publicité.
- 📊 `ShortlistShared`
- **Palier** P0

---

## E2 · ★ La Visite Vérifiée

> **Valeur :** le cœur. Tout le reste existe pour amener ici et pour convertir ce qui s'y passe.

### E2.1 · Preview gratuite délibérément frustrante
- **AC1** Une pièce, 90° explorables, flou **progressif** appliqué au rendu — pas un cache posé par-dessus.
- **AC2** Servie depuis un bucket **public séparé** : elle est censée circuler.
- **AC3** L'invite gyroscope apparaît une seule fois, jamais bloquante.
- **AC4** Le périmètre exact (pièce imposée, angle) est **paramétrable côté serveur** et instrumenté dès le premier jour : c'est le réglage qui pilote le taux de conversion.
- **Ψ** Effet Zeigarnik — la boucle ouverte est le moteur de conversion.
- 📊 `PreviewOpened`
- **Palier** P0

### E2.2 · Première visite offerte
- **AC1** Tout nouveau compte reçoit une Visite Vérifiée complète, sans condition et sans carte.
- **AC2** L'offre est présentée **après** que l'utilisateur ait tenté d'aller au-delà de la preview, jamais avant.
- **AC3** Le pass gratuit est un enregistrement de plein droit (`source = free_first_visit`), soumis aux mêmes règles d'accès.
- **Ψ** Réciprocité + effet de dotation — on ne vend pas une expérience jamais vécue.
- 📊 `PassPurchased` (avec `source`)
- **Palier** P0

### E2.3 · Visionneuse et tour complet
- **AC1** Chrome minimal : croix, progression, deux icônes. Rien d'autre.
- **AC2** Les hotspots ont une cible de 48 dp même quand le repère visuel fait 24 dp.
- **AC3** La progression « 4/6 pièces » est permanente et en haut.
- **AC4** ≥ 30 fps soutenu sur appareil de référence d'entrée de gamme.
- **AC5** Sous 20 fps pendant 3 s, l'application **propose d'elle-même** le mode photos fixes.
- **AC6** Le mode photos fixes est accessible en permanence depuis ⚙ — sans lui, un trouble vestibulaire exclut du cœur du produit.
- **Ψ** Gradient d'objectif — la progression fait terminer les tours, et un tour terminé est la métrique nord.
- 📊 `TourCompleted` (≥ 80 % des pièces)
- **Palier** P0

### E2.4 · Paywall étanche
- **AC1** Aucune URL de scène complète n'est persistée en base ni renvoyée sans pass valide.
- **AC2** URL signées, TTL ≤ 15 min, renouvelées en session.
- **AC3** Filigrane serveur portant l'identifiant du compte.
- **AC4** **Test de pénétration :** un client authentifié sans pass qui interroge directement PostgREST sur `virtual_tour_scenes` obtient zéro ligne. Ce test est une porte de CI, pas une revue.
- 📊 `PaywallShown`
- **Palier** P0

### E2.5 · Écran de déblocage et packs
- **AC1** Trois options exactement : 1 visite, pack 3, pack 7. Une quatrième échoue la revue.
- **AC2** L'ancrage au coût de déplacement affiche **le montant déclaré par l'utilisateur**, pas une moyenne inventée.
- **AC3** Les deux garanties — remboursement automatique, accès permanent — sont visibles **avant** l'appui sur payer.
- **AC4** Le montant figure dans le bouton.
- **Ψ** Ancrage · comptabilité mentale · paradoxe du choix · aversion au regret.
- 📊 `PaywallShown`
- **Palier** P0

### E2.6 · Paiement Mobile Money et récupération d'échec
- **AC1** MTN MoMo, Moov Flooz, Celtiis Cash. Ni Wave ni Orange n'apparaissent nulle part.
- **AC2** Aucun SDK marchand dans l'application ; tout transite par Edge Function.
- **AC3** L'écran d'attente affiche « Rien n'est débité tant que tu n'as pas validé » et un compte à rebours **prolongeable**.
- **AC4** À l'échec : message en français simple, aucun code technique, et **bascule d'opérateur proposée d'office**.
- **AC5** L'opérateur est mémorisé et présélectionné au paiement suivant.
- **AC6** Un paiement n'est **jamais** mis en file d'attente hors-ligne.
- **AC7** Les transitions d'échec sont couvertes à 100 % par `bloc_test`.
- **Ψ** Aversion à la perte — un échec non rattrapé fait perdre l'utilisateur définitivement, avec le sentiment d'avoir perdu son argent.
- 📊 `PassPurchased`, `PaymentFailed` (avec opérateur et motif)
- **Palier** P0

### E2.7 · Accès permanent et hors-ligne
- **AC1** Un tour payé reste accessible tant que l'annonce est en ligne. **Aucune expiration à 48 h.**
- **AC2** Le téléchargement affiche le poids avant de démarrer.
- **AC3** Le cache d'un tour payé n'est **jamais** purgé automatiquement.
- **AC4** Le tour s'ouvre en mode avion.
- **Ψ** Effet de dotation — on a payé, on possède.
- 📊 `LiteModeToggled`
- **Palier** P0

---

## E3 · Le Pouls — la fraîcheur

> **Valeur :** c'est le composant qui rend la promesse vraie. Sans lui, EAZYRENT vend le tour d'un bien peut-être déjà loué — le grief exact adressé au démarcheur.

### E3.1 · Affichage de la fraîcheur
- **AC1** Chaque bien porte son état : `◉ Vérifié aujourd'hui 09h12` → `○ il y a 6 jours` → `⚠ non confirmé depuis 12 jours`.
- **AC2** L'horodatage est **absolu et précis** — la précision *est* la preuve.
- **AC3** L'état est couleur **+** icône **+** mot. Jamais la couleur seule.
- **AC4** La dégradation est visible : on ne prétend jamais qu'un bien de 12 jours vaut un bien du matin.
- 📊 —
- **Palier** P0

### E3.2 · Signalement en un geste, récompensé
- **AC1** Un seul geste depuis Ma liste : « Ce bien n'est plus libre ».
- **AC2** **Deux signalements indépendants** déclenchent une re-vérification. Un seul ne retire jamais rien — sinon un concurrent efface le catalogue en une soirée.
- **AC3** Signalement confirmé ⇒ une visite offerte au signalant, notifiée.
- **AC4** Seul un agent ou le bailleur retire effectivement le bien.
- **Ψ** Réciprocité — l'incident devient une récompense, l'inverse exact de l'expérience face à un démarcheur.
- 📊 `FreshnessReported`
- **Palier** P1

### E3.3 · Remboursement automatique
- **AC1** Bien devenu indisponible ⇒ crédit rendu **automatiquement**, sans réclamation, à tous les acheteurs du tour.
- **AC2** L'utilisateur est notifié du remboursement, pas seulement crédité.
- **AC3** Le taux de remboursement est surveillé ; **au-delà de 10 %, alerte d'arrêt** — le produit ne tiendrait plus sa seule promesse.
- **Ψ** Aversion au regret — l'objection est levée avant l'achat, l'incident est traité avant la plainte.
- 📊 `PassRefunded`
- **Palier** P0

---

## E4 · Le Coût Total d'Entrée

### E4.1 · Affichage du vrai chiffre
- **AC1** `Entrée : 245 000 F · 3 mois av.` sur la carte du feed.
- **AC2** Détail avance / caution / frais / total en deuxième bloc de la fiche, chiffres tabulaires alignés à droite.
- **AC3** Mention `Prix ferme` quand le bailleur s'engage.
- **AC4** Aucune décimale sur un montant en FCFA.
- 📊 —
- **Palier** P0

### E4.2 · Filtre inversé « ce que je peux sortir »
- **AC1** Un curseur de budget d'entrée, placé au-dessus du filtre de loyer.
- **AC2** Le tri par coût d'entrée est disponible et distinct du tri par loyer.
- **AC3** Passer de zéro résultat à des résultats atteignables produit un moment nommé.
- **Ψ** Cadrage — on transforme une liste décourageante en liste atteignable.
- 📊 —
- **Palier** P2

---

## E5 · Ma liste, Duel, Conseil de famille

### E5.1 · Ma liste et compteur d'économies
- **AC1** Trois onglets : Gardés, Visitées, RDV.
- **AC2** État vide **actif**, avec retour au feed.
- **AC3** Le compteur d'économies est en **bas** de l'écran — une récompense qu'on découvre, pas un score qu'on consulte.
- **AC4** Le calcul utilise le coût de déplacement **déclaré par l'utilisateur**. Aucune valeur inventée.
- **Ψ** Comptabilité mentale — la dépense devient un gain net affiché.
- 📊 `ListingSaved`
- **Palier** P1

### E5.2 · Le Duel
- **AC1** Deux biens à la fois, plein écran. Jamais un tableau à plus de deux colonnes.
- **AC2** Les lignes différentes sont mises en valeur, les lignes identiques atténuées.
- **AC3** Le bouton n'apparaît qu'à partir de 2 biens gardés.
- **AC4** Issues : Je garde A · Je garde B · Les deux · Aucun des deux.
- **AC5** Conclusion : « Ton finaliste » + proposition de RDV.
- **AC6** Aucune notification propre. Une fonctionnalité n'a pas droit à une notification simplement parce qu'elle existe.
- **Ψ** Loi de Hick — la décision binaire débloque ce qu'un tableau paralyse.
- 📊 `DuelResolved`
- **Palier** P2

### E5.3 · Conseil de famille
- **AC1** Partage vers WhatsApp depuis Ma liste, 2 à 4 biens.
- **AC2** Page web < 100 Ko, sans framework, lisible dans le navigateur intégré de WhatsApp.
- **AC3** Vote possible **sans compte et sans installation**. On ne prend jamais la famille en otage.
- **AC4** La page montre les previews, **jamais** les tours complets.
- **AC5** Les votes reviennent dans Messages.
- **Ψ** Preuve sociale + engagement — celui qui a engagé sa famille n'abandonne plus sa recherche.
- 📊 `ShortlistShared`
- **Palier** P2

### E5.4 · Notes vocales
- **AC1** Micro de **même taille** que le bouton d'envoi, dans le chat et sur un bien gardé.
- **AC2** Opus mono 16 kHz, durée plafonnée à 60 s.
- **AC3** Enregistrement hors-ligne, envoi à la reconnexion.
- **AC4** Aucune transcription automatique — elle échoue sur le français local mêlé de fon et produirait des contresens.
- **Ψ** Effet IKEA — annoter, c'est investir ; investir, c'est rester.
- 📊 —
- **Palier** P1 (note sur bien) · P2 (chat)

### E5.5 · Point d'ancrage
- **AC1** La question est posée **après** la première visite terminée, jamais à l'onboarding.
- **AC2** Chaque bien affiche `~22 min de ton travail` et le **coût mensuel** du trajet.
- **AC3** Sans ancrage renseigné, la ligne n'existe pas — aucun espace vide.
- **AC4** Tri « le plus proche de mon travail » disponible.
- 📊 —
- **Palier** P2

---

## E6 · Compte tardif et paliers

### E6.1 · Anonyme de premier rang
- **AC1** L'application est pleinement utilisable sans session : feed, preview, filtres, première visite.
- **AC2** `AuthState.anonymous` est un état de plein droit ; aucune route ne redirige vers une connexion au démarrage.
- 📊 —
- **Palier** P0

### E6.2 · Inscription au bon moment
- **AC1** Le numéro n'est demandé **qu'après** le premier tour terminé, au moment de garder un bien.
- **AC2** La demande est justifiée par un bénéfice concret : « pour retrouver ta liste ».
- **AC3** OTP par SMS, code prolongeable, aucune contrainte de temps punitive.
- **AC4** Les données anonymes (recherche, tour vu, bien gardé) sont **rattachées** au compte, jamais perdues.
- **Ψ** Engagement et cohérence — un petit pas déjà franchi rend le suivant naturel.
- 📊 —
- **Palier** P1

### E6.3 · Paliers et révélation progressive
- **AC1** Le palier est calculé par `StageResolver` à partir de faits. Aucun drapeau en base.
- **AC2** L'onglet **Moi** change de contenu selon le palier ; il n'affiche jamais de fonction verrouillée.
- **AC3** Aucune visite guidée générale. Une bulle contextuelle unique, non bloquante, au moment où la fonction devient utile.
- **AC4** Un test vérifie qu'aucun chemin de code ne produit un élément grisé pour cause de palier.
- 📊 —
- **Palier** transversal

### E6.4 · Réglages : thème, mode Léger, notifications
- **AC1** Mode Léger activé par défaut hors Wi-Fi.
- **AC2** Réglages de notification **par type**, jamais un interrupteur unique tout-ou-rien.
- **AC3** Suppression de compte avec export des données (loi n°2017-20).
- 📊 `LiteModeToggled`
- **Palier** P1

---

## E7 · Notifications intelligentes

### E7.1 · Politique exécutable
- **AC1** Toute notification passe par `NotificationPolicy.evaluate()`. Aucun autre point d'émission n'existe.
- **AC2** Les trois questions sont implémentées et testées unitairement.
- **AC3** Plafond de 2 notifications de contenu par jour ; silence de 21 h à 7 h.
- **AC4** Tout refus est motivé et instrumenté.
- 📊 `NotificationSuppressed` (avec motif)
- **Palier** transversal

### E7.2 · Alerte quartier — la notification qui justifie l'interruption
- **AC1** Émise en moins de 30 min après la publication d'un bien correspondant.
- **AC2** Contient quartier, prix et disponibilité du tour. Jamais « de nouveaux biens sont disponibles ».
- **AC3** Le bouton d'action flottant du feed active l'alerte pour la recherche courante.
- **Ψ** Aversion à la perte, fondée sur un fait réel — les bons biens partent en 24 à 48 h.
- 📊 `AlertActivated`
- **Palier** P1

### E7.3 · Notifications de confiance et de reprise
- **AC1** J+3 après une mise en liste : « Toujours libre — vérifié ce matin ». Elle ne vend rien.
- **AC2** Tour interrompu : relance à J+1, **entre 19 h et 21 h**, fenêtre où l'utilisateur est chez lui avec du réseau.
- **AC3** Crédit hebdomadaire : samedi 10 h, moment réel de recherche de logement au Bénin.
- **AC4** Baisse de prix et pression sur un bien gardé : uniquement si le fait est **vrai**.
- **Ψ** Preuve sociale et rareté — **exclusivement** sur des faits vérifiés. Mentir ici serait un suicide de marque.
- 📊 —
- **Palier** P1

### E7.4 · Routage de canal et budget d'attention
- **AC1** Push pour l'urgent et le contextuel · WhatsApp pour le transactionnel · SMS en repli hors data.
- **AC2** Un type d'alerte sous 15 % d'ouverture sur 14 jours voit sa fréquence réduite **automatiquement**, avant que l'utilisateur ne coupe tout.
- 📊 —
- **Palier** transversal

---

## E11 · Sécurité et conformité — transversale, démarre avec E0

> **Valeur :** la sécurité arrivée en Phase 6 est une sécurité qu'on n'a plus le temps d'appliquer. C'est exactement ce qui a produit le paywall contournable de la v1.0.

### E11.1 · RLS et vue publique des profils
- **AC1** La politique `USING (true)` sur `profiles` est supprimée.
- **AC2** La vue publique n'expose ni téléphone ni e-mail.
- **AC3** Un test vérifie qu'un client authentifié ne peut pas énumérer les numéros.
- 📊 —

### E11.2 · Étanchéité du paywall en continu
- **AC1** Le test de pénétration de E2.4 tourne à chaque CI.
- **AC2** Les buckets preview et tours complets sont **séparés** et le privé n'a aucune politique publique.
- 📊 —

### E11.3 · Données personnelles
- **AC1** Chaque donnée collectée a une finalité écrite et une durée de conservation.
- **AC2** Documents KYC chiffrés, accès limité au déposant et aux administrateurs.
- **AC3** Dossier de déclaration APDP constitué avant la mise en production.
- 📊 —

### E11.4 · Secrets et intégrité du build
- **AC1** Aucune clé marchande dans l'APK ; audit automatisé en CI.
- **AC2** Clés Maps et Supabase restreintes par empreinte de signature.
- **AC3** APK signé reproductible pour le partage direct.
- 📊 —

---

# HORS PÉRIMÈTRE MVP

*Définies au niveau epic. Les critères d'acceptation seront écrits quand le niveau inférieur sera livré et mesuré — pas avant.*

## E8 · L'offre : bailleur, apporteur, agent de terrain
**Valeur :** le stock est le facteur limitant de l'entreprise, pas le code. Un agent = 5 biens/jour = ~110 biens/mois.
**Stories :** E8.1 Publier en 4 champs · E8.2 Preuve de demande avant vente du Pack Visibilité · E8.3 Espace apporteur et commissions · E8.4 Tournée d'agent et tournage · E8.5 Re-confirmation de disponibilité en série.
**Dépend de :** E1, E3.

## E9 · Rendez-vous et visite guidée en direct
**Valeur :** convertir la visite en déplacement utile ; servir la diaspora, segment au consentement à payer le plus élevé.
**Stories :** E9.1 Créneaux proposés par le bailleur · E9.2 Rappels J-1 et H-2 · E9.3 Créneaux d'agent pour la visite en direct · E9.4 Appel vidéo avec repli audio + photos.
**Dépend de :** E2, E5.

## E10 · Locataire installé
**Valeur :** la rétention longue durée. La v1.0 laissait sortir l'utilisateur du produit après la signature — l'erreur la plus coûteuse du dossier.
**Stories :** E10.1 Paiement du loyer · E10.2 Quittance immédiate · E10.3 Bail et documents · E10.4 Signalement de problème · E10.5 Remise des clés soignée (règle du pic-fin).
**Dépend de :** E9, et partiellement de E13.

## E12 · État des lieux hors-ligne
**Valeur :** preuve légale, utilisable sans réseau.
**Stories :** E12.1 Grille pièce par pièce · E12.2 Photos horodatées et géolocalisées · E12.3 Signature tactile conjointe · E12.4 File de synchronisation prioritaire · E12.5 PDF certifié.
**Dépend de :** E10.

## E13 · Séquestre — ⛔ BLOQUÉE
**Statut :** aucune story n'est écrite et aucune ne doit l'être avant que `GATES.md` G8 soit tranchée par un conseil juridique béninois : statut BCEAO pour la détention de fonds de tiers, et plafonds de la loi n°2018-12.
**Le module `features/escrow/` existe, vide et non câblé, pour que son absence reste visible.**

---

## Récapitulatif

| Epic | Stories détaillées | Niveau | Statut |
| :--- | :---: | :---: | :--- |
| E0 Socle | 4 | — | MVP |
| E1 Découverte sans compte | 5 | 1 | MVP |
| **E2 ★ La Visite Vérifiée** | **7** | **0** | MVP |
| E3 Le Pouls | 3 | 1 | MVP |
| E4 Coût d'entrée | 2 | 1 | MVP |
| E5 Liste, Duel, Famille | 5 | 1–2 | MVP |
| E6 Compte et paliers | 4 | 1 | MVP |
| E7 Notifications | 4 | 1 | MVP |
| E11 Sécurité et conformité | 4 | — | MVP, transversale |
| E8 L'offre | — | 4 | post-MVP |
| E9 RDV et visite en direct | — | 2 | post-MVP |
| E10 Locataire installé | — | 3 | post-MVP |
| E12 État des lieux | — | 3 | post-MVP |
| E13 Séquestre | — | 3 | ⛔ bloquée |

**38 stories détaillées, 9 epics, périmètre MVP.**
