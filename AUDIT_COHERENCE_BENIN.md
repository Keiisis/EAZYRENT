# 🔎 EAZYRENT — Audit de cohérence : documents vs marché béninois

**Date :** 31 août 2026
**Périmètre audité :** `PRD.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `DATABASE_SCHEMA.sql`, `BRAND_GUIDELINES.md`
**Méthode :** BMAD (analyste → PM → architecte), Spec Kit (constitution → spec → plan), Unlazy (portes d'acceptation avant exécution)
**Verdict global :** produit désirable, positionnement mal ciblé. Les documents décrivent un marché ivoiro-sénégalais, pas le Bénin. La fonctionnalité vedette (VR) n'est pas la fonctionnalité de valeur (preuve de disponibilité). Le modèle de séquestre est le poste de risque le plus lourd et n'est adossé à aucune structure réglementaire.

---

## 1. 🚨 Incohérences internes (le document se contredit lui-même)

| # | Contradiction | Où | Gravité |
|---|---|---|---|
| I-1 | Pass Visite : « revenus **partagés** entre EAZYRENT et le propriétaire » vs « **100 %** des revenus pour EAZYRENT » | `PRD.md` §1.2 vs §4.1 | 🔴 Bloquant : c'est la clause qu'on signe avec les bailleurs |
| I-2 | Tarif du Pass : 1 500 FCFA partout, alors que le prix arrêté est **1 000 FCFA** | `PRD.md` §1.2/§4.1, `ROADMAP.md` S2.3, `DATABASE_SCHEMA.sql` L140-141 | 🔴 Bloquant |
| I-3 | Cartographie : `Mapbox` (PRD §3, ROADMAP S2.1) vs `google_maps_flutter` (ARCHITECTURE §7/§8) | 3 docs | 🟠 Chiffrage et sprint faux |
| I-4 | Qui produit les panoramas 360 ? PRD dit propriétaire et agence en **Upload** ; ROADMAP S1.3 dit **agents terrain EAZYRENT exclusivement** | `PRD.md` §3 vs `ROADMAP.md` S1.3 | 🔴 Change tout le modèle de coût et la promesse « anti-fausse annonce » |
| I-5 | Le diagramme de Gantt ne contient pas les sprints 2.2 (carte) ni 2.3 (moteur 360/VR) — soit le cœur du produit | `ROADMAP.md` §Gantt vs §Phase 2 | 🟠 Planning sous-estimé d'environ 3 semaines |
| I-6 | ARCHITECTURE §5.2 « crédite **le portefeuille** du propriétaire » — aucune table `wallets` / `payouts` n'existe | `ARCHITECTURE.md` vs `DATABASE_SCHEMA.sql` | 🔴 Trou fonctionnel : les fonds ne peuvent pas sortir |
| I-7 | PRD promet Litiges, Notifications, Dashboard comptable ; aucune table `disputes`, `notifications`, `favorites`, `saved_searches`, `reviews` | `PRD.md` §3 vs `DATABASE_SCHEMA.sql` | 🔴 Le schéma ne couvre que ~60 % du PRD |
| I-8 | Le PRD cite Termii / Twilio / Infobip pour le SMS mais aucun canal WhatsApp n'est modélisé, alors que WhatsApp est cité comme canal prioritaire | `PRD.md` §5.2 | 🟡 |
| I-9 | KPI « < 1,5 s sur 3G » sans budget de poids d'écran, alors que le produit repose sur des panoramas équirectangulaires (plusieurs Mo/scène) | `PRD.md` §6 | 🟠 Objectif non atteignable tel quel |

---

## 2. 🇧🇯 Incohérences marché : les docs ne décrivent pas le Bénin

### 2.1 Paiement — l'erreur la plus coûteuse

Les documents placent **Wave** et **Orange Money** au centre du dispositif de paiement. Ni l'un ni l'autre n'opère au Bénin : Orange n'est pas opérateur télécom béninois, et Wave n'y est pas déployé. Le schéma SQL code même `orange_money` dans `payment_method`.

**Réalité béninoise :**

| Canal | Statut | Poids |
|---|---|---|
| **MTN MoMo** | Leader incontesté | Canal n°1, obligatoire au lancement |
| **Moov Africa Flooz** | Second acteur | Canal n°2, obligatoire |
| **Celtiis Cash** | Opérateur public, en croissance | Canal n°3, phase 2 |
| Carte bancaire | Marginal en B2C | Utile pour la diaspora uniquement |
| Espèces | Toujours dominant hors app | Le vrai concurrent du paiement in-app |

**Agrégateurs :** les documents citent CinetPay et **Paystack**. Paystack ne couvre pas le Mobile Money béninois. Les intégrations pertinentes sont les agrégateurs locaux — **FedaPay** et **KkiaPay** (béninois, MTN + Moov natifs, frais et support locaux), avec CinetPay en repli régional.

> **Correctif appliqué :** `DATABASE_SCHEMA.sql` et `PRD.md` alignés sur MTN / Moov / Celtiis + FedaPay/KkiaPay.

### 2.2 Foncier — mauvais pays

`land_title_type` est commenté « Titre Foncier, ACD, Attestation Villageoise ». L'**ACD** est un instrument **ivoirien**. Au Bénin, depuis le Code foncier et domanial (loi n°2013-01 modifiée en 2017), la référence est :

- **Certificat de Propriété Foncière (CPF)** délivré par l'**ANDF** — le seul titre définitif ;
- **Titre Foncier (TF)** ancien régime, en cours de conversion en CPF ;
- **Attestation de recasement** (lotissement) ;
- **Convention de vente** sous seing privé, avec ou sans enregistrement ;
- **Permis d'habiter** (ancien régime).

L'enjeu produit est direct : au Bénin, la fraude à la vente de parcelle (double vente, vendeur non propriétaire) est *le* risque perçu numéro un sur le segment vente. Un filtre « CPF vérifié ANDF » vaut davantage qu'une visite VR sur ce segment.

### 2.3 Utilités — mauvais opérateurs

| Doc actuel | Réalité Bénin |
|---|---|
| CIE, Wooyofal (Sénégal), compteur à carte CIE | **SBEE** — compteur prépayé (« compteur à carte ») vs post-payé vs sous-compteur partagé chez le bailleur |
| SODECI / SDE | **SONEB** — réseau, ou forage privé, ou château/citerne |

Le sous-compteur partagé revendu par le bailleur au-dessus du tarif SBEE est une source de litige majeure à Cotonou : c'est un champ à rendre obligatoire et affiché en clair (prix du kWh revendu), pas une case à cocher.

### 2.4 Géographie — la cible n'est pas « la zone UEMOA »

Les docs visent « l'Afrique francophone / zone UEMOA ». Un produit qui dépend d'agents terrain équipés de caméras 360 ne peut pas se lancer sur 8 pays. La densité exploitable est le **Grand Nokoué** : Cotonou, Abomey-Calavi (Godomey, Calavi, Akassato, Togba), Sèmè-Podji, Porto-Novo — soit environ 2,5 millions d'habitants dans un rayon de 30 km, ce qui rend le déplacement d'un agent économiquement viable.

**Correctif :** UEMOA devient une ambition d'expansion (année 2+), pas le périmètre du MVP. Le MVP est **Cotonou + Abomey-Calavi**.

### 2.5 Plateforme — iOS d'abord est une erreur

La ROADMAP prévoit une publication App Store à parité avec Google Play. La part iOS au Bénin est marginale ; le parc réel est Android bas/milieu de gamme (Tecno, Infinix, itel, Samsung A), 2 à 4 Go de RAM, souvent Android 10-13.

**Conséquences non traitées dans l'architecture :**
- Poids de l'APK à contraindre (< 30 Mo) — le bundle Three.js + WebView pèse ;
- Distribution **APK direct** (partage WhatsApp / Bluetooth) : c'est un canal d'acquisition réel au Bénin, pas une dégradation ;
- Le rendu WebGL sur GPU d'entrée de gamme (Mali-G52 et inférieurs) impose un plafond de résolution des panoramas — le « 60/120 fps » annoncé n'est pas tenable partout.

### 2.6 Le mode Casque VR est un actif marketing, pas une fonctionnalité

Le parc de casques VR au Bénin est proche de zéro. Le mode stéréoscopique split-screen coûte du développement, de la QA et du poids d'app pour un usage quasi nul.

**Ce qui a de la valeur réelle, dans l'ordre :** (1) le panorama 360 tactile, (2) le gyroscope, (3) le passage de pièce en pièce, (4) le mini-plan. Le mode casque est à garder **en démonstration événementielle** (stands, salons, agences partenaires, tournées quartier) où il produit un effet de bouche-à-oreille disproportionné — mais il ne doit pas figurer sur le chemin critique du MVP.

---

## 3. 💡 La question centrale : est-ce que ça aide réellement un Béninois ?

**Oui — mais pas pour la raison écrite dans le PRD.**

Le PRD affirme que la visite 360 « évite les déplacements coûteux et les embouteillages ». C'est vrai et faible. La douleur réelle du chercheur de logement à Cotonou est plus précise et plus chère :

> **Chercher un logement coûte de l'argent avant même d'avoir trouvé.**
> On paie le zémidjan (300 à 1 000 F l'aller-retour selon le quartier) et souvent un démarcheur (500 à 2 000 F « frais de déplacement ») **pour chaque bien**, et on découvre sur place que le bien est déjà loué, plus cher qu'annoncé, sans eau, ou n'existe pas. Un chercheur type brûle **10 000 à 20 000 F et deux à trois semaines** pour 8 à 12 déplacements dont un seul sera utile.

Ce cadrage change tout :

1. **Le pass à 1 000 F cesse d'être un coût, il devient une économie.** On ne demande pas à l'utilisateur de payer pour un gadget : on lui demande de payer 1 000 F au lieu de 2 000 F pour savoir si un bien mérite le déplacement. Le point de comparaison n'est pas « gratuit sur Facebook », c'est « le zem + le démarcheur ».
2. **Le concurrent n'est pas une autre application.** C'est le démarcheur informel, les groupes Facebook « Location maison Cotonou », WhatsApp, et CoinAfrique. Aucun de ces canaux ne prouve qu'un bien est **encore disponible** — c'est le trou dans le marché.
3. **La fonctionnalité de valeur n'est pas la VR, c'est la preuve.** Panorama daté + disponibilité re-confirmée + prix affiché ferme = la fin du déplacement inutile. La VR est la manière de délivrer la preuve, pas la promesse.

**Ce que le produit tel que documenté n'aide pas à résoudre** — et qui est pourtant la douleur n°1 côté locataire au Bénin : **l'avance**. Se voir demander 6 à 12 mois de loyer d'avance (pratique courante, quoique encadrée par la loi, cf. §6) est un obstacle bien plus lourd que la peur de l'arnaque. Le séquestre sécurise l'argent, il ne le rend pas disponible. Tant qu'EAZYRENT ne propose pas un mécanisme sur ce point (paiement fractionné adossé à un partenaire financier, garantie locative, mise en relation IMF), il traite le second problème et pas le premier. **C'est à assumer explicitement dans le positionnement, ou à mettre au roadmap année 2.**

---

## 4. 🧨 Le paywall est cassé par conception

C'est le défaut technique le plus grave du schéma actuel.

`virtual_tour_scenes.panorama_url` pointe vers Supabase Storage. La table **n'a pas de RLS activée**, et rien n'indique que le bucket est privé. Conséquence : n'importe qui peut lire l'URL du panorama via l'API PostgREST et ouvrir la scène sans jamais payer les 1 000 F. Le premier utilisateur technique publie les URL dans un groupe WhatsApp et le modèle économique s'effondre en une semaine.

**Correctif obligatoire :**
1. Bucket `virtual_tours` **privé**, aucune URL publique persistée en base ;
2. `virtual_tour_scenes` et `virtual_tour_hotspots` : RLS activée, `SELECT` refusé par défaut ;
3. Une Edge Function `get-tour-access` qui vérifie l'existence d'un pass valide et retourne des **URL signées à durée courte (≤ 15 min)**, renouvelées pendant la session ;
4. Une **preview gratuite** basse résolution et floutée au-delà de 90° servie depuis un bucket public séparé — c'est l'appât, elle est censée fuiter ;
5. Filigrane dynamique avec l'identifiant du compte incrusté côté serveur sur les panoramas complets, pour dissuader la rediffusion.

Second défaut de même famille : `CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true)` expose **le numéro de téléphone de tous les utilisateurs**. Sur ce marché, cela signifie que les démarcheurs aspirent la base de tous les chercheurs de logement en un après-midi et court-circuitent la plateforme — en plus de constituer un manquement au Code du numérique béninois (loi n°2017-20) et aux obligations vis-à-vis de l'**APDP**. À remplacer par une vue publique restreinte (prénom, avatar, badge de vérification, ancienneté), le téléphone n'étant exposé qu'après mise en relation validée.

---

## 5. 🗄️ Dette du schéma de données

Manques bloquants (au-delà de la §4) :

- **Aucun index.** Pas d'index GIST sur `location_geom` alors que PostGIS `ST_DWithin` est le cœur de la recherche ; pas d'index sur `listings(city, neighborhood, price_amount, is_available)`.
- **`location_geom` jamais alimenté** — pas de trigger depuis `latitude`/`longitude`.
- **`updated_at` jamais mis à jour** — pas de trigger.
- **Tables absentes :** `wallets`, `payouts`, `disputes`, `notifications`, `device_tokens`, `favorites`, `saved_searches`, `search_alerts`, `listing_views`, `reviews`, `referrals`, `availability_checks`.
- **`availability_checks` est la table la plus importante qui manque** : c'est elle qui matérialise la promesse « ce bien est encore disponible », re-confirmée à intervalle régulier par l'agent ou le bailleur. Sans elle, EAZYRENT vend une visite d'un bien peut-être déjà loué — exactement le grief adressé au démarcheur.
- **`virtual_tour_access_passes`** ne gère pas les packs multi-visites promis par le PRD (pas de notion de crédit), et impose une expiration à 48 h : une expiration payante est une source de litige et de désinstallation. Voir `GROWTH_MONETISATION.md` §3.
- **Pas de `deleted_at`**, pas d'historique de prix, pas d'`audit_log` sur `escrow_transactions` alors que l'architecture revendique l'immutabilité.

---

## 6. ⚖️ Risques réglementaires non traités (bloquants)

| Risque | Description | Impact |
|---|---|---|
| **R-1 — Détention de fonds de tiers** | Le séquestre implique de conserver le premier loyer et la caution. Dans l'espace UEMOA, cette activité relève de la réglementation BCEAO (établissement de monnaie électronique / de paiement). EAZYRENT n'a pas ce statut et les documents n'en parlent pas. | 🔴 **Bloquant.** Le MVP doit passer par un **compte de cantonnement** ouvert chez une banque partenaire ou déléguer la conservation à l'agrégateur agréé (FedaPay/KkiaPay), EAZYRENT n'étant qu'ordonnateur. À valider avant tout développement de la Phase 3. |
| **R-2 — Avance et caution** | La loi n°2018-12 du 2 juillet 2018 portant régime juridique du bail à usage d'habitation au Bénin encadre l'avance de loyer et le dépôt de garantie. Les montants réellement pratiqués sur le marché (6 à 12 mois) sont supérieurs à ce que le cadre légal admet. | 🔴 EAZYRENT ne peut pas industrialiser en base une pratique non conforme. Deux options : plafonner dans le produit (et se positionner comme **le** canal conforme — argument de différenciation puissant), ou ne pas modéliser l'avance. **Avis juridique béninois requis.** |
| **R-3 — Données personnelles** | Loi n°2017-20 (Code du numérique) : traitement de données personnelles, formalité auprès de l'**APDP**. Le KYC (CNI, CPF) et la géolocalisation des photos d'état des lieux sont des données sensibles. | 🟠 Déclaration APDP + politique de conservation à produire avant la mise en production. |
| **R-4 — Valeur probante de la signature** | L'état des lieux « certifié SHA-256 » n'a de valeur probante que dans un cadre défini. Le hash prouve l'intégrité, pas l'identité du signataire. | 🟡 Adosser la signature au numéro de téléphone vérifié par OTP + horodatage serveur, et le documenter comme « présomption », pas comme « certification ». |

`GATES.md:G8` consigne R-1 et R-2 comme **handoff** : ce sont les seuls points de cet audit qu'un agent ne peut pas trancher.

---

## 7. 📉 Absents du PRD

1. **Aucune analyse concurrentielle.** CoinAfrique, groupes Facebook, WhatsApp, agences locales, démarcheurs : rien. Or c'est ce qui détermine le prix acceptable et le discours.
2. **Aucun KPI business.** Les 4 KPI listés sont techniques (temps de chargement, uptime). Manquent : coût d'acquisition, taux d'activation, taux de conversion vers un pass payé, nombre de passes par chercheur, taux de biens réellement disponibles, marge par annonce shootée.
3. **Aucun modèle de l'offre.** Tout le PRD est écrit du point de vue du locataire. Or le goulot d'étranglement est l'**offre** : sans stock d'annonces 360 fraîches dans les quartiers demandés, la demande n'a rien à consommer. C'est le vrai problème d'amorçage (voir `GROWTH_MONETISATION.md` §5).
4. **Aucune stratégie hors-ligne d'acquisition** alors que le marché se fait à 80 % hors application (radio, affichage quartier, tontines, églises/mosquées, réseaux de zémidjans).
5. **Aucun traitement du rôle du démarcheur.** On ne détruit pas un intermédiaire installé : on le recrute. Le démarcheur qui connaît 40 propriétaires dans Fidjrossè est le meilleur agent d'acquisition d'offre possible. Il n'existe pas dans le modèle de rôles (`user_role` ne connaît que tenant/owner/agency/admin).

---

## 8. ✅ Ce qui est solide et doit être conservé

- L'architecture Flutter Clean + BLoC + Drift est adaptée et sobre.
- Le choix Photo Sphere Viewer 5 est le bon compromis (WebXR, virtual tour plugin, maintenance active).
- L'offline-first sur l'état des lieux est **le** bon appel technique pour ce marché.
- La charte graphique est de qualité, cohérente et différenciante ; l'anti-cliché du logo est juste. Seule réserve, à traiter en phase UI : le contraste de `#FF4D2E` sur `#0B0F19` et la lisibilité de `#00E599` en plein soleil (usage réel : à l'extérieur, écran d'entrée de gamme, luminosité limitée).
- La certification terrain des visites par des agents EAZYRENT est la meilleure idée du dossier : c'est ce qui rend la promesse crédible et ce qui empêche la copie facile.

---

## 9. 📋 Corrections appliquées dans ce dépôt

| Fichier | Correction |
|---|---|
| `PRD.md` | Pass à 1 000 F, 100 % EAZYRENT (contradiction I-1 tranchée), opérateurs Bénin, filtres SBEE/SONEB/ANDF, périmètre Grand Nokoué, KPI business ajoutés |
| `ARCHITECTURE.md` | Agrégateurs FedaPay/KkiaPay/CinetPay, section paywall par URL signées, mention du compte de cantonnement |
| `ROADMAP.md` | Tarif, Google Maps unique, sprints carte et 360 ajoutés au planning, Android-first, phase de conformité placée **avant** la Phase 3 |
| `DATABASE_SCHEMA.sql` | Défauts Bénin, `payment_method` corrigé, RLS sur les scènes 360, préfixe des tables manquantes documenté |
| *(nouveau)* `UX_CORE_SPEC.md` | Les 10 exigences UX |
| *(nouveau)* `GROWTH_MONETISATION.md` | Économie unitaire, prix, boucles d'acquisition et de rétention |
| *(nouveau)* `GATES.md` | Portes d'acceptation Unlazy |
