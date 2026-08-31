# 🗺️ EAZYRENT — Matrice écrans × rôles

**Objet :** l'inventaire exhaustif des écrans, rattachés à leur rôle, pour qu'aucun ne soit oublié une seconde fois.
**Méthode :** mappage manuel. ⚠️ **Ce n'est pas une sortie graphify.** L'extraction sémantique a échoué sur une limite de session ; seule la passe AST est passée (411 nœuds, 687 arêtes sur les sources Dart). À rejouer quand la limite se lève : `graphify . --update` puis `graphify query "quels écrans n'ont aucun rôle rattaché ?"`.

---

## 1. Les trois profils publics — décision de cadrage

Les documents v2 listaient **six** rôles (`tenant`, `owner`, `agency`, `broker`, `field_agent`, `admin`). C'était un mélange de deux choses différentes. Correction :

| | Profil | S'inscrit dans l'app | Rôle |
| :---: | :--- | :---: | :--- |
| **T** | **Locataire** (chercheur) | ✅ | Cherche, visite, garde, candidate |
| **D** | **Démarcheur** (apporteur) | ✅ | Apporte des biens, suit ses commissions |
| **P** | **Propriétaire** (bailleur) | ✅ | Publie, reçoit des demandes, encaisse |
| — | *Agence* | ✅ | **Variante de P**, pas un 4ᵉ profil : mêmes écrans + multi-agents et comptabilité |
| — | *Agent de terrain* | ❌ | **Outil interne.** Application séparée ou build à drapeau. Pas un profil public. |
| — | *Admin* | ❌ | **Console web.** Jamais dans l'app mobile. |

**Trois profils à l'inscription. Ni quatre, ni six.**

---

## 2. Ce qui manquait — 28 écrans absents des specs

Le recensement fait apparaître beaucoup plus que les deux écrans d'authentification signalés.

### 2.1 Authentification et compte — **aucun écran spécifié**

| Code | Écran | Rôles | Pourquoi c'est bloquant |
| :--- | :--- | :---: | :--- |
| **A01** | Connexion | T D P | Un utilisateur qui réinstalle ou change de téléphone n'a **aucun chemin de retour**. |
| **A02** | Création de compte + **choix du profil** | T D P | C'est ici que les 3 profils se séparent. Sans cet écran, D et P n'ont pas de porte d'entrée. |
| **A03** | Saisie du code OTP | T D P | Évoqué partout, dessiné nulle part. Écran à fort taux d'échec. |
| **A04** | Numéro perdu / changement de numéro | T D P | Au Bénin on change de puce souvent. Sans cela, un compte payant devient inaccessible. |
| **A05** | Consentement CGU + données personnelles | T D P | **Obligation loi n°2017-20 / APDP.** Absent = non conforme. |
| **A06** | Amorce de permission ×3 (localisation, notifications, micro) | T D P | Demander une permission système sans l'expliquer d'abord fait perdre le droit à vie après un refus. |

### 2.2 Locataire — écrans manquants

| Code | Écran | Pourquoi |
| :--- | :--- | :--- |
| **S16** | Mes passes et crédits | Le module `passes` n'avait aucun écran. On vend des crédits sans lieu pour les voir. |
| **S17** | Mes alertes et recherches sauvegardées | L'alerte quartier est l'action à plus fort rendement de rétention — sans écran de gestion, elle est irrévocable ou invisible. |
| **S18** | Signaler « ce bien n'est plus libre » + confirmation | F2 reposait sur un bouton sans écran de retour ni de récompense. |
| **S19** | Définir mon point d'ancrage | F6 n'avait aucun écran de saisie. |
| **S20** | Centre de notifications | Une notification manquée est perdue à jamais. |
| **S21** | Réglages de notification **par type** | Exigé par la règle 8 ; jamais dessiné. |
| **S22** | Aide, litige, signalement d'annonce | Promis par le PRD §3, aucun écran. |
| **S23** | Suppression de compte + export des données | Obligation légale. |
| **S24** | Historique de paiements et reçus | On prend de l'argent sans en donner la trace. |

### 2.3 Propriétaire — quasi tout manquait

| Code | Écran |
| :--- | :--- |
| **P01** | Tableau de bord bailleur (mes biens, vues, demandes) |
| **P02** | Détail de mon annonce + **preuve de demande** (« 23 personnes ont vu ton bien ») |
| **P03** | Demandes de RDV reçues — accepter / proposer un autre créneau |
| **P04** | Demander un tournage 360 (Pack Visibilité 5 000 F) |
| **P05** | KYC propriétaire — CNI + CPF/ANDF ou mandat |
| **P06** | Encaissements et quittances émises |

`S14 Publier` existait, mais seul et sans suite : on pouvait publier, jamais rien en faire.

### 2.4 Démarcheur — **rôle entier sans un seul écran**

| Code | Écran |
| :--- | :--- |
| **D01** | Accueil apporteur — gains du mois, biens en cours |
| **D02** | Apporter un bien (formulaire court, photo, contact du propriétaire) |
| **D03** | Mes biens apportés + statut de vérification |
| **D04** | Mes commissions — payées, en attente |
| **D05** | KYC démarcheur — CNI + attestation |

C'est le rôle qui alimente le stock, et il n'avait aucune interface.

### 2.5 Agent de terrain — interne, à spécifier séparément

**AG01** Tournée du jour · **AG02** Capture 360 et pose des hotspots · **AG03** Re-confirmation de disponibilité en série.
Ne fait pas partie de l'application publique : build à drapeau ou application distincte.

---

## 3. Matrice complète

Légende : ● écran principal du rôle · ○ accessible · — hors périmètre du rôle

| Code | Écran | T | D | P | Statut |
| :--- | :--- | :-: | :-: | :-: | :--- |
| S00 | Démarrage | ● | ● | ● | spécifié |
| A01 | Connexion | ● | ● | ● | **manquant** |
| A02 | Création de compte + choix de profil | ● | ● | ● | **manquant** |
| A03 | Saisie OTP | ● | ● | ● | **manquant** |
| A04 | Numéro perdu | ○ | ○ | ○ | **manquant** |
| A05 | Consentement CGU / données | ● | ● | ● | **manquant** |
| A06 | Amorce de permission | ● | ● | ● | **manquant** |
| S01 | Onboarding chercheur (3 questions) | ● | — | — | spécifié |
| S02 | Feed | ● | ○ | ○ | spécifié |
| S03 | Carte | ● | — | — | spécifié |
| S04 | Filtres | ● | — | — | spécifié |
| S05 | Fiche de bien | ● | ○ | ○ | spécifié |
| S06 | Visionneuse 360 | ● | ○ | ○ | spécifié |
| S07 | Paywall et paiement | ● | — | — | spécifié |
| S08 | Ma liste | ● | — | — | spécifié |
| S09 | Duel | ● | — | — | spécifié |
| S10 | Messages | ● | ● | ● | spécifié |
| S11 | Demande de RDV | ● | — | — | spécifié |
| S12 | Moi | ● | ● | ● | spécifié |
| S13 | Conseil de famille | ● | — | — | spécifié |
| S15 | Mon logement (locataire installé) | ● | — | — | spécifié |
| S16 | Mes passes et crédits | ● | — | — | **manquant** |
| S17 | Alertes et recherches sauvegardées | ● | — | — | **manquant** |
| S18 | Signaler un bien plus libre | ● | ○ | ○ | **manquant** |
| S19 | Point d'ancrage | ● | — | — | **manquant** |
| S20 | Centre de notifications | ● | ● | ● | **manquant** |
| S21 | Réglages de notification par type | ● | ● | ● | **manquant** |
| S22 | Aide et litige | ● | ● | ● | **manquant** |
| S23 | Suppression de compte + export | ● | ● | ● | **manquant** |
| S24 | Historique de paiements | ● | — | ○ | **manquant** |
| S14 | Publier un bien | — | ○ | ● | spécifié (mince) |
| P01 | Tableau de bord bailleur | — | — | ● | **manquant** |
| P02 | Mon annonce + preuve de demande | — | — | ● | **manquant** |
| P03 | Demandes de RDV reçues | — | — | ● | **manquant** |
| P04 | Demander un tournage 360 | — | ○ | ● | **manquant** |
| P05 | KYC propriétaire | — | — | ● | **manquant** |
| P06 | Encaissements et quittances | — | — | ● | **manquant** |
| D01 | Accueil apporteur | — | ● | — | **manquant** |
| D02 | Apporter un bien | — | ● | — | **manquant** |
| D03 | Mes biens apportés | — | ● | — | **manquant** |
| D04 | Mes commissions | — | ● | — | **manquant** |
| D05 | KYC démarcheur | — | ● | — | **manquant** |

**44 écrans au total. 16 spécifiés, 28 manquants.** La spec couvrait 36 % du produit.

---

## 4. Comment l'authentification se réconcilie avec « recevoir avant de donner »

Le principe P2 dit : aucun compte avant la première valeur. Ajouter une connexion ne le contredit pas, **à condition de séparer les portes d'entrée** :

```
                    ┌─ S00 Démarrage ─┐
                    │                 │
      « Je cherche un logement »   « J'ai déjà un compte »
                    │                 │
              S01 Onboarding      A01 Connexion
              (3 questions)            │
                    │                  │
              S02 Feed ────────────────┤
                    │                  │
        ★ 1re Visite Vérifiée offerte  │
                    │                  │
              A02 Création de compte ──┘
              (déclenchée par « garder ce bien »)
                    │
              A03 OTP → A05 Consentement
```

Et pour les deux autres profils, qui arrivent **avec une intention**, pas en exploration :

```
S00 → « Je veux publier un bien » ou « Je veux apporter des biens »
   → A02 Création de compte AVEC CHOIX DE PROFIL
   → A03 OTP → A05 Consentement → P01 / D01
```

**La règle exacte devient :** le locataire ne crée pas de compte avant d'avoir reçu ; le propriétaire et le démarcheur créent un compte immédiatement, parce que leur première action *est* de donner quelque chose au système. Un chercheur qu'on force à s'inscrire est un chercheur perdu ; un propriétaire qui veut publier ne trouve pas anormal de s'identifier.

---

## 5. Conséquences à répercuter

- [ ] `UI_SCREENS_SPEC.md` — 28 écrans à spécifier
- [ ] `EPICS_STORIES.md` — E6 s'élargit (auth complète) ; **E8 remonte dans le MVP** : sans écrans démarcheur, pas de stock
- [ ] `APP_STRUCTURE.md` — `broker` passe MVP ; ajouter `features/notifications_center/`, `features/legal/`
- [ ] `DATABASE_SCHEMA.sql` — `user_role` doit distinguer profils publics et rôles internes
- [ ] `PRD.md` §2 — ramener les personas publics à 3
- [ ] `UX_CORE_SPEC.md` §5 — la navigation à 4 onglets ne vaut que pour T ; D et P ont la leur
