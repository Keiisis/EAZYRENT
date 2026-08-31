# ⚖️ EAZYRENT — Constitution du projet

**Méthode :** Spec Kit — la constitution précède la spec, la spec précède le plan, le plan précède les tâches.
**Portée :** contraint toute décision produit, technique et commerciale. Un arbitrage qui contredit un principe est un arbitrage à remonter, pas à trancher seul.

Chaque principe porte une clause **« violé si »**. Un principe qu'aucune observation ne peut contredire est un slogan : il n'a pas sa place ici.

---

## P1 · La vérité avant l'effet

EAZYRENT vend la certitude qu'un bien existe, est conforme, et est encore libre. Toute donnée affichée doit être vérifiable ou datée.

**Violé si :** un chiffre non mesuré est présenté comme mesuré · une rareté est affichée sans être réelle · un bien est marqué disponible sans re-vérification datée · une statistique de vente au bailleur (« 4× plus de demandes ») est citée avant d'avoir été mesurée sur les 50 premiers biens.
**Porte :** `GATES.md` G1–G5 ; PRD §6.1 taux de fraîcheur ≥ 85 %.

---

## P2 · L'utilisateur reçoit avant de donner

Aucune valeur n'est demandée avant qu'une valeur ait été rendue. Pas de compte avant le moment de vérité, pas de paiement avant la première visite offerte, pas de permission système avant que son usage soit visible.

**Violé si :** un mur d'inscription précède le premier contenu · la première Visite Vérifiée devient payante · une permission est demandée au lancement.
**Porte :** `UX_CORE_SPEC.md` §4.1 ; taux d'activation ≥ 45 %.

---

## P3 · Le déplacement évité est l'unité de valeur

Chaque fonctionnalité se justifie par le déplacement inutile qu'elle supprime ou par la décision qu'elle permet. Une fonctionnalité qui ne fait ni l'un ni l'autre n'entre pas.

**Violé si :** une fonctionnalité ne se rattache à aucun niveau de la hiérarchie (`UX_CORE_SPEC.md` §3) · un module est développé sans que le niveau inférieur soit livré et mesuré.
**Porte :** G18 ; `FEATURES_V2.md` §9.

---

## P4 · Le paywall ne s'arbitre jamais côté client

Le client n'a jamais connaissance d'une URL de panorama complet. L'accès est décidé par une fonction serveur qui vérifie un pass, et matérialisé par des URL signées à durée courte.

**Violé si :** une URL de scène complète est persistée en base ou renvoyée à un client sans pass · `virtual_tour_scenes` perd sa RLS · une préview et un tour complet partagent le même bucket.
**Porte :** G19 ; `ARCHITECTURE.md` §6.4 ; PRD §6.2 « 0 panorama accessible sans pass ».

---

## P5 · L'argent se prend avec des garanties posées d'avance

Le montant figure dans le bouton. Le remboursement automatique et la permanence de l'accès sont annoncés **avant** le paiement. Un échec de paiement ne débite rien et le dit.

**Violé si :** un écran de paiement affiche « Continuer » sans montant · un échec laisse l'utilisateur sans issue ni bascule d'opérateur · un accès acheté expire.
**Porte :** `UI_SCREENS_SPEC.md` S07 ; taux de succès Mobile Money > 98,5 %.

---

## P6 · Rien ne se conçoit hors du contexte réel d'usage

Debout, dehors, en plein soleil, sur un Android à 40 000 F, sur data payée à l'unité, souvent à une main.

**Violé si :** une paire de couleurs passe sous 4,5:1 · une cible tactile descend sous 48 dp · un téléchargement démarre sans que son poids ait été affiché · l'interface casse à `textScaleFactor` 2,0.
**Porte :** G9 ; `UI_DESIGN_SYSTEM.md` §1, §12.

---

## P7 · La performance est une promesse chiffrée, pas une intention

Les budgets sont dans le code (`PerfBudget`) et se mesurent sur le matériel réel du marché.

**Violé si :** un budget est dépassé sans décision explicite · une valeur est annoncée sans avoir été mesurée (ex. « 60 fps ») · un `BackdropFilter` entre dans le rendu.
**Porte :** G15 (abandonnée jusqu'au premier build) ; `UI_DESIGN_SYSTEM.md` §12.

---

## P8 · Hors-ligne n'est pas un cas dégradé

Ce qui a été payé reste accessible sans réseau. Ce qui a été saisi hors-ligne part à la reconnexion. L'état de connexion est toujours visible et jamais honteux.

**Violé si :** un tour payé exige du réseau · une saisie hors-ligne est perdue · un écran affiche un vide au lieu de son cache daté.
**Porte :** `APP_STRUCTURE.md` §8 ; `ARCHITECTURE.md` §4.

---

## P9 · Une notification est un fait nouveau, personnel et actionnable

Les trois questions de `UX_CORE_SPEC.md` §8.1 sont un filtre exécutable, pas une bonne intention. Plafond : 2 notifications de contenu par jour, aucune entre 21 h et 7 h.

**Violé si :** une notification ne passe pas les trois questions · le plafond quotidien est franchi · un type d'alerte reste à fréquence pleine sous 15 % d'ouverture sur 14 jours.
**Porte :** G17 ; `core/notifications/notification_policy.dart`.

---

## P10 · La découverte est progressive et le code le sait

Le palier d'un utilisateur est une valeur calculée à un seul endroit. Aucune fonction verrouillée n'est affichée en grisé — elle n'existe pas à l'écran.

**Violé si :** une condition de palier est écrite en dur dans un widget · une fonctionnalité apparaît désactivée · un module de niveau 3 est visible à un utilisateur de palier P1.
**Porte :** G17 ; `core/progression/`.

---

## P11 · Aucun secret, aucune donnée personnelle superflue

Aucune clé d'API de paiement dans l'application. Aucun numéro de téléphone exposé avant mise en relation validée. Toute donnée collectée a une finalité écrite et une durée de conservation.

**Violé si :** un SDK de paiement est intégré côté client avec une clé marchande · la vue publique de `profiles` expose un téléphone ou un e-mail · une donnée est collectée sans finalité déclarée.
**Porte :** `AUDIT_COHERENCE_BENIN.md` §4 ; loi n°2017-20, déclaration APDP.

---

## P12 · Ce qui n'est pas mesuré n'est pas terminé

Chaque KPI du PRD §6.1 a un événement nommé émis par l'application. Une fonctionnalité livrée sans son événement est livrée à moitié.

**Violé si :** un KPI n'a pas d'événement · une story est close sans son instrumentation · un seuil d'arrêt (taux de remboursement > 10 %) n'est pas surveillé.
**Porte :** G20 ; `APP_STRUCTURE.md` §9.

---

## Trois principes suspendus, et pourquoi

| Principe attendu | Statut | Motif |
| :--- | :--- | :--- |
| « Les fonds des utilisateurs sont sécurisés par séquestre » | ⛔ **Suspendu** | Aucun statut BCEAO. Tant que le montage (compte de cantonnement ou délégation à l'agrégateur agréé) n'est pas arrêté, ce principe ne peut pas être tenu et ne doit donc pas être écrit. `GATES.md` G8. |
| « L'avance et la caution respectent la loi » | ⛔ **Suspendu** | Loi n°2018-12 : plafonds à faire confirmer par un conseil juridique béninois. La pratique du marché les dépasse. `GATES.md` G8. |
| « L'application est disponible sur iOS » | ⏸ **Différé** | Parc marginal au Bénin. Décision assumée, pas un oubli. |

Écrire un principe qu'on ne peut pas tenir est la façon la plus rapide de vider une constitution de sa valeur.

---

## Procédure d'amendement

Un principe se modifie par une note datée en fin de ce fichier, avec le motif et la porte impactée. Il ne se supprime jamais silencieusement. Un principe abandonné reste écrit, barré, avec sa date et sa raison — exactement comme une porte abandonnée dans `GATES.md`.
