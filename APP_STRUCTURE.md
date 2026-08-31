# 🏗️ EAZYRENT — Structure de l'application mobile

**Méthode :** Spec Kit — contexte technique → contrôle constitutionnel → plan → modèle → contrats.
**Dépend de :** `CONSTITUTION.md`, `PRD.md` v2, `UX_CORE_SPEC.md`, `UI_DESIGN_SYSTEM.md`, `UI_SCREENS_SPEC.md`, `FEATURES_V2.md`, `ARCHITECTURE.md` v2.
**Statut du dépôt :** aucun projet Flutter initialisé. Ce document est la cible du premier commit (`EPICS_STORIES.md` E0.1).

---

## 1. Contexte technique

| Élément | Décision | Justification |
| :--- | :--- | :--- |
| Framework | Flutter 3.24+ / Dart 3.5+ | Rendu Impeller, un seul code Android puis iOS différé |
| `minSdkVersion` | **23** (Android 6) | Maximise la portée sur le parc Tecno/itel encore en circulation. En dessous, les coûts de compatibilité dépassent le gain. |
| `targetSdkVersion` | 35 | Exigence Play Store |
| Architecture | Clean Architecture · Presentation / Domain / Data | Conforme `ARCHITECTURE.md` §1 |
| État | `flutter_bloc` 8.1+ | Flux d'événements prédictible, testable avec `bloc_test` |
| Injection | `get_it` + `injectable` | Résolution typée à la compilation |
| Navigation | **`go_router`** | Les liens profonds sont le canal d'acquisition n°1 (`GROWTH_MONETISATION.md` §4.3). Un routeur impératif rendrait le partage WhatsApp bancal. |
| Base locale | `drift` | Requêtes typées, migrations, socle du hors-ligne |
| Backend | `supabase_flutter` | Auth OTP, PostgREST, Realtime, Storage |
| Erreurs | `fpdart` — `Either<Failure, T>` | Aucune exception ne traverse la couche domaine |
| Modèles | `freezed` + `json_serializable` | Immuabilité, égalité de valeur, unions d'états |
| Visite 360 | `flutter_inappwebview` + bundle **local** PSV5/Three.js | Bundle embarqué, pas de CDN : démarrage hors-ligne des tours payés |
| Carte | `google_maps_flutter` | Techno unique, décision tranchée (`ARCHITECTURE.md` §7) |
| Paiement | **Aucun SDK marchand dans l'app.** Edge Functions uniquement | P11. Une clé marchande embarquée dans un APK est une clé publiée. |
| Push | `firebase_messaging` | FCM |
| Images | `cached_network_image` + vignettes redimensionnées serveur | Budget `feedScreenMaxBytes` |
| Audio | `record` + `just_audio` | Notes vocales (F4), Opus 16 kHz mono |
| Analytique | Client léger maison → table Supabase | Contrat d'événements §9. Pas de SDK tiers : poids d'APK et données personnelles. |

**NEEDS CLARIFICATION résolus / restants**

| Point | Statut |
| :--- | :--- |
| Agrégateur de paiement : FedaPay ou KkiaPay ? | ⏳ **Ouvert.** N'impacte pas la structure : l'app ne parle qu'aux Edge Functions. Décision côté serveur, sans effet sur le planning mobile. |
| Statut de détention des fonds (BCEAO) | ⛔ **Bloquant** pour `features/escrow/` uniquement. Aucun autre module n'en dépend. |
| Plafonds légaux d'avance et de caution | ⛔ **Bloquant** pour la validation de `advance_months`. Le champ existe ; la règle de validation est en attente. |
| Voix off fon / yoruba | ⏳ Phase 2. Prévoir la clé `audioGuideUrl` dès maintenant, ne pas l'implémenter. |

---

## 2. Contrôle constitutionnel

| Principe | Traduction structurelle | Où |
| :--- | :--- | :--- |
| P2 · recevoir avant de donner | Aucune route ne dépend d'une session au démarrage. `AuthState.anonymous` est un état de premier rang, pas une absence. | `core/router/`, `features/auth/` |
| P4 · paywall serveur | `TourRepository` n'expose aucune URL. Une seule porte : `getTourAccess()`. | `features/tour/data/` |
| P6 · contexte réel | Trois thèmes, `PerfBudget` dans le code, mode Léger par défaut hors Wi-Fi. | `core/theme/`, `core/network/` |
| P8 · hors-ligne | File d'attente sortante + cache daté, transverses. | `core/sync/`, `core/storage/` |
| P9 · notifications | Politique exécutable, un seul point de passage. | `core/notifications/` |
| P10 · découverte progressive | Palier calculé à un seul endroit. | `core/progression/` |
| P12 · mesure | Contrat d'événements typé, un événement par KPI. | `core/analytics/` |

**Aucune violation non justifiée.** Le seul écart est `features/escrow/`, présent dans l'arborescence mais **vide et non câblé**, pour que son absence soit visible plutôt que oubliée.

---

## 3. La décision structurante

> **Les règles UX 7, 8 et 10 deviennent des modules, pas des conventions.**

Les micro-victoires, les notifications intelligentes et la découverte progressive sont les trois mécanismes qui font vivre le produit. Écrits en conditions dispersées dans les widgets, ils se contredisent au troisième sprint et disparaissent au sixième. Écrits comme modules avec un contrat, ils survivent.

C'est la seule décision d'architecture propre à ce produit ; le reste est du Clean Architecture standard.

```
core/progression/   ← règle 10 : le palier est calculé à UN endroit
core/notifications/ ← règle 8  : le test à 3 questions est exécutable
core/moments/       ← règle 7  : les micro-victoires ont un bus, pas des copier-collers
```

---

## 4. Arborescence

```
lib/
├── main.dart                      # bootstrap : DI → thème → routeur
├── app.dart                       # MaterialApp.router, écoute du thème et du palier
│
├── core/
│   ├── config/                    # Flavors dev / staging / prod, clés publiques
│   ├── di/                        # get_it + injectable, injection_container.dart
│   ├── router/
│   │   ├── app_router.dart        # go_router, routes nommées
│   │   ├── deep_links.dart        # eazyrent.bj/b/{id} → fiche, sans compte
│   │   └── stage_redirect.dart    # redirection selon le palier (P10)
│   ├── network/
│   │   ├── supabase_client.dart
│   │   ├── connectivity.dart      # en ligne / hors-ligne / mesuré → pilote le mode Léger
│   │   └── retry_policy.dart      # backoff exponentiel + jitter
│   ├── storage/
│   │   ├── app_database.dart      # drift : schéma + migrations
│   │   ├── daos/                  # listings, passes, credits, notes, outbox
│   │   ├── secure_store.dart      # jeton de session uniquement
│   │   └── tour_cache.dart        # tours payés, chiffrés, jamais purgés automatiquement
│   ├── sync/
│   │   ├── outbox.dart            # écritures différées (notes, signalements, états des lieux)
│   │   └── sync_manager.dart      # déclenché par la connectivité, jamais par un timer
│   ├── theme/
│   │   ├── design_tokens.dart     ✅ écrit
│   │   ├── app_theme.dart         # 3 ThemeData depuis AppPalette
│   │   └── theme_controller.dart  # clair / sombre / Plein Soleil + capteur de luminosité
│   ├── progression/               ◀── RÈGLE 10
│   │   ├── user_stage.dart        # enum P0..P6
│   │   ├── stage_resolver.dart    # calcule le palier depuis des faits, jamais depuis un drapeau
│   │   └── stage_gate.dart        # widget : rend l'enfant, ou RIEN. Jamais de grisé.
│   ├── notifications/             ◀── RÈGLE 8
│   │   ├── notification_policy.dart   # les 3 questions, exécutables
│   │   ├── notification_budget.dart   # 2/jour, silence 21h–7h
│   │   ├── channel_router.dart        # push | WhatsApp | SMS selon le contenu
│   │   └── fcm_handler.dart
│   ├── moments/                   ◀── RÈGLE 7
│   │   ├── moment.dart            # enum des micro-victoires nommées
│   │   ├── moment_bus.dart        # émission ; l'UI s'abonne
│   │   └── savings_counter.dart   # compteur d'économies, base déclarative
│   ├── analytics/
│   │   ├── analytics_event.dart   # union scellée, un cas par événement
│   │   └── analytics_sink.dart    # tampon local → envoi groupé
│   ├── errors/                    # Failure, mapping exception → Failure
│   ├── utils/                     # money_fcfa.dart, dates.dart, phone_bj.dart
│   └── widgets/
│       ├── atoms/                 # AppButton (8 états), AppChip, AppInput, AmountText…
│       ├── molecules/             # ListingCard, FreshnessBadge, PriceBreakdown…
│       └── states/                # LoadingSkeleton, EmptyState, ErrorState, OfflineBanner
│
├── features/
│   ├── onboarding/                # S01 — 3 questions, sans compte
│   ├── search/                    # S02 S03 S04 — feed, carte, filtres, recherches, alertes
│   ├── listing/                   # S05 — fiche, coût d'entrée (F1)
│   ├── tour/                      # S06 — preview, visionneuse, cache, repli photos fixes
│   ├── passes/                    # crédits, packs, remboursements
│   ├── payments/                  # S07 — MoMo, reprise, bascule d'opérateur
│   ├── freshness/                 # F2 — Le Pouls + signalements
│   ├── shortlist/                 # S08 S09 S13 — liste, Duel (F3), Conseil de famille (F5)
│   ├── anchors/                   # F6 — point d'ancrage, temps et coût de trajet
│   ├── auth/                      # OTP tardif, session, anonyme de premier rang
│   ├── profile/                   # S12 — Moi, réglages, thème, mode Léger
│   ├── messaging/                 # S10 — chat + notes vocales (F4)
│   ├── visits/                    # S11 — RDV, puis visite en direct (F7)
│   ├── owner/                     # S14 — publier, demander un tournage
│   ├── broker/                    # apporteur : biens apportés, commissions
│   ├── field_agent/               # tournée, tournage, re-confirmation
│   ├── lease/                     # S15 — loyer, quittances
│   ├── kyc/                       # pièces, badge vérifié
│   ├── inspection/                # état des lieux hors-ligne
│   └── escrow/                    # ⛔ VIDE — bloqué par la conformité BCEAO
│
└── l10n/                          # fr (défaut) · en · clés audio fon/yoruba en phase 2
```

**Structure interne d'une feature** — identique partout, sans exception :

```
features/<nom>/
├── domain/       entities/ · repositories/ (interfaces) · usecases/
├── data/         models/ · datasources/ (remote, local) · repositories/ (impl)
└── presentation/ bloc/ · pages/ · widgets/
```

Une feature ne dépend jamais d'une autre feature. Tout partage passe par `core/` ou par une interface de domaine. La règle est mécanique : elle se vérifie par une analyse d'import, pas par une revue.

---

## 5. Modules — niveau, epic, périmètre

Aucun module n'existe sans niveau. Un module sans niveau est un module que personne n'ose dé-prioriser.

| Module | Niveau | Epic | MVP |
| :--- | :---: | :--- | :---: |
| `core/*` (hors escrow) | — socle | E0 | ✅ |
| `onboarding` | 1 | E1 | ✅ |
| `search` | 1 | E1 | ✅ |
| `listing` + coût d'entrée (F1) | 1 | E1 / E4 | ✅ |
| `tour` | **0 — le cœur** | E2 | ✅ |
| `passes` | 1 | E2 | ✅ |
| `payments` | 1 | E2 | ✅ |
| `freshness` (F2) | 1 | E3 | ✅ |
| `auth` | 1 | E6 | ✅ |
| `profile` | 1 | E6 | ✅ |
| `core/notifications` (F alertes) | 1 | E7 | ✅ |
| `shortlist` — liste | 1 | E5 | ✅ |
| `shortlist` — Duel (F3) | 2 | E5 | ✅ |
| `shortlist` — Conseil de famille (F5) | 2 | E5 | 🟠 fin de MVP |
| `messaging` + notes vocales (F4) | 2 | E5 | 🟠 |
| `anchors` (F6) | 2 | E5 | 🟠 |
| `visits` — RDV | 2 | E9 | ⚫ post-MVP |
| `visits` — visite en direct (F7) | 2 | E9 | ⚫ |
| `owner` | 4 | E8 | ⚫ |
| `broker` | 4 | E8 | ⚫ |
| `field_agent` | 4 | E8 | ⚫ |
| `lease` | 3 | E10 | ⚫ |
| `kyc` | 3 | E10 | ⚫ |
| `inspection` | 3 | E12 | ⚫ |
| `escrow` | 3 | E13 | ⛔ bloqué |

**Périmètre du MVP : E0 → E7 + E11.** Tout le reste est nommé, situé, et hors du premier lot.

---

## 6. Les trois modules qui portent l'UX

### 6.1 `core/progression/` — règle 10

Le palier n'est jamais un drapeau posé en base : il se **calcule** à partir de faits observables. Un drapeau se désynchronise, un calcul non.

```dart
enum UserStage { p0Curieux, p1Eveille, p2Chasseur, p3Candidat,
                 p4Locataire, p5Bailleur, p6Pro }

abstract interface class StageResolver {
  /// Dérivé de faits : tours terminés, biens gardés, pass achetés,
  /// RDV demandés, bail actif, biens publiés.
  UserStage resolve(ProgressionFacts facts);
}

/// Rend son enfant si le palier est atteint. Sinon rend `SizedBox.shrink()`.
/// JAMAIS un état grisé : une fonction verrouillée n'existe pas à l'écran.
class StageGate extends StatelessWidget {
  const StageGate({required this.min, required this.child, super.key});
  final UserStage min;
  final Widget child;
}
```

**Interdit :** `if (user.hasPaid && user.shortlistCount > 2)` dans un widget. Toute condition de ce type remonte dans `StageResolver`.

### 6.2 `core/notifications/` — règle 8

Le test à trois questions devient une porte que rien ne contourne.

```dart
sealed class NotificationCandidate {
  bool get carriesNewFact;     // Q1 — un fait nouveau ?
  bool get isPersonal;         // Q2 — spécifique à cette personne ?
  Duration get actionableIn;   // Q3 — actionnable maintenant ?
  NotificationKind get kind;   // content | transactional
}

abstract interface class NotificationPolicy {
  /// Refus motivé, jamais silencieux : le motif part en analytique.
  PolicyDecision evaluate(NotificationCandidate c, NotificationLedger ledger);
}
```

`NotificationBudget` applique : **2 notifications de contenu par jour maximum**, **aucune entre 21 h et 7 h**, et **réduction automatique de fréquence** d'un type dont le taux d'ouverture tombe sous 15 % sur 14 jours glissants — avant que l'utilisateur ne coupe tout.

`ChannelRouter` choisit : **push** pour l'urgent et le contextuel · **WhatsApp** pour le transactionnel important (loyer, quittance, RDV) parce qu'il est lu et archivé · **SMS** en repli quand l'utilisateur est hors data, ce qui arrive tous les jours.

### 6.3 `core/moments/` — règle 7

```dart
enum Moment {
  tourCompleted,        // « Tu as tout vu. » — la victoire centrale
  firstSaveMade,
  duelResolved,         // « Ton finaliste. »
  alertActivated,
  reportRewarded,       // signalement F2 → crédit offert
  weeklyCreditGranted,
  familyVoteReceived,
  rentReceiptIssued,    // règle du pic-fin, côté locataire installé
}
```

Un bus unique émet ; l'UI s'abonne. Sans lui, la logique de célébration se recopie dans huit écrans et devient incohérente.

`SavingsCounter` calcule les économies **à partir du coût de déplacement déclaré par l'utilisateur lui-même**, jamais d'une moyenne inventée. Un compteur soupçonné d'être gonflé détruit exactement la confiance qu'il est censé construire.

---

## 7. Contrat du paywall — P4

Le module `tour` **n'a pas d'accès direct au stockage**. Une seule porte.

```dart
abstract interface class TourRepository {
  /// Preview publique : basse résolution, floutée au-delà de 90°.
  /// Bucket public SÉPARÉ. Elle est censée circuler : c'est l'appât.
  Future<Either<Failure, TourPreview>> getPreview(ListingId id);

  /// Tour complet. Vérifie le pass CÔTÉ SERVEUR et retourne des URL
  /// signées (TTL <= 15 min), renouvelées pendant la session.
  /// Aucune URL de scène complète n'existe jamais côté client hors de ce flux.
  Future<Either<Failure, TourAccess>> getTourAccess(ListingId id);

  /// Télécharge un tour déjà payé pour l'hors-ligne. Cache chiffré,
  /// jamais purgé automatiquement : on a payé, on possède.
  Future<Either<Failure, Unit>> downloadForOffline(ListingId id);
}
```

Le repli matériel appartient aussi à ce contrat : sous 20 fps pendant 3 s, l'application propose d'elle-même le mode **photos fixes**. Elle ne laisse jamais l'utilisateur face à un tour saccadé en se disant qu'il a mal payé.

---

## 8. Hors-ligne — P8

| Donnée | Traitement |
| :--- | :--- |
| Feed consulté | Cache drift, daté, affiché avec sa date |
| **Tour payé** | Cache chiffré, **jamais purgé automatiquement** |
| Preview | Cache court, purgeable |
| Note vocale | File d'attente sortante, part à la reconnexion |
| Signalement de fraîcheur | File d'attente sortante |
| État des lieux | File d'attente sortante, priorité haute (`ARCHITECTURE.md` §4) |
| Paiement | ❌ **Jamais mis en file.** Un paiement différé est un paiement contesté. |

`SyncManager` se déclenche sur un changement de connectivité, jamais sur un minuteur : un minuteur consomme de la batterie et des données pour rien.

---

## 9. Contrat d'analytique — P12

Un événement par KPI du PRD §6.1. Une union scellée : ajouter un KPI sans son événement ne compile pas.

```dart
sealed class AnalyticsEvent {
  const AnalyticsEvent();
}

// ★ Métrique nord
final class TourCompleted extends AnalyticsEvent { … }     // ≥ 80 % des pièces vues

final class OnboardingFinished extends AnalyticsEvent { … }   // activation
final class PreviewOpened extends AnalyticsEvent { … }        // entonnoir de conversion
final class PaywallShown extends AnalyticsEvent { … }
final class PassPurchased extends AnalyticsEvent { … }        // conversion payante
final class PassRefunded extends AnalyticsEvent { … }         // ⚠ SEUIL D'ARRÊT à 10 %
final class PaymentFailed extends AnalyticsEvent { … }        // + operator, + reason
final class ListingSaved extends AnalyticsEvent { … }
final class DuelResolved extends AnalyticsEvent { … }
final class VisitRequested extends AnalyticsEvent { … }       // visite → RDV
final class AlertActivated extends AnalyticsEvent { … }
final class FreshnessReported extends AnalyticsEvent { … }    // taux de fraîcheur
final class NotificationSuppressed extends AnalyticsEvent { … } // + motif du refus
final class ShortlistShared extends AnalyticsEvent { … }      // coefficient viral
final class LiteModeToggled extends AnalyticsEvent { … }
final class SunlightModeToggled extends AnalyticsEvent { … }
```

**`PassRefunded` est l'événement le plus important du produit après `TourCompleted`.** Au-delà de 10 %, le produit ne tient pas sa seule promesse et aucun budget marketing ne compensera cela (`GROWTH_MONETISATION.md` §7).

`NotificationSuppressed` — instrumenter les notifications **refusées** est ce qui permet de savoir si la politique est trop sévère ou trop laxiste. Sans elle, on ne pilote qu'à l'aveugle ce qu'on a envoyé.

---

## 10. Environnements, tests, livraison

**Flavors** — `dev` (Supabase local, paiement bouchonné) · `staging` (bac à sable de l'agrégateur) · `prod`. Aucune clé secrète dans l'application : seules les clés publiques Supabase et Maps, restreintes par empreinte de signature.

**Tests, par ordre de valeur pour ce produit :**

| Niveau | Cible | Priorité |
| :--- | :--- | :---: |
| Unitaires — cas d'usage, `StageResolver`, `NotificationPolicy`, `SavingsCounter` | ≥ 80 % du domaine | 🔴 |
| `bloc_test` — machines à états du paiement et du tour | 100 % des transitions d'échec | 🔴 |
| Intégration — bac à sable de paiement, y compris **échec et bascule d'opérateur** | Chemins d'échec d'abord | 🔴 |
| Intégration — hors-ligne : coupure en pleine synchronisation, sur appareil physique | | 🟠 |
| Golden — `ListingCard` dans les 3 thèmes × 2 échelles de texte | | 🟠 |
| Accessibilité — contraste et cibles tactiles, automatisés | | 🟠 |

Les chemins d'échec passent avant les chemins heureux : sur ce marché, l'échec de paiement est le cas nominal, pas l'exception.

**CI** — `flutter analyze` en mode strict · tests · **contrôle du poids de l'APK contre `PerfBudget.apkMaxBytes`, en échec bloquant** · `--tree-shake-icons` · construction AAB pour le Play Store **et APK signé** pour le partage direct (canal d'acquisition réel).

---

## 11. Ordre de construction

```
E0 Socle ─────────────────────────────────────────────┐
   ├─ E1 Découverte sans compte (onboarding, feed)     │
   │     └─ E2 ★ La Visite Vérifiée (tour, paywall, paiement)
   │           ├─ E3 Fraîcheur (Le Pouls)
   │           ├─ E4 Coût d'entrée
   │           └─ E5 Ma liste, Duel, Conseil de famille
   ├─ E6 Compte tardif et paliers                      │
   ├─ E7 Notifications intelligentes                   │
   └─ E11 Sécurité et conformité (transversal) ────────┘

                   ── frontière du MVP ──

E8 Offre (bailleur, apporteur, agent)   E9 RDV et visite en direct
E10 Locataire installé                  E12 État des lieux
E13 Escrow ⛔ bloqué
```

**E11 est transversale et commence en même temps que E0.** La sécurité arrivée en Phase 6 est une sécurité qu'on n'a plus le temps d'appliquer — c'est exactement ce qui a produit le paywall contournable de la v1.0.

---

## 12. Ce que cette structure interdit

| Interdit | Détection |
| :--- | :--- |
| Une feature qui importe une autre feature | Analyse d'import en CI |
| Une couleur brute hors de `design_tokens.dart` | `GATES.md` G13 |
| Une condition de palier écrite dans un widget | Revue + P10 |
| Une notification envoyée sans passer par `NotificationPolicy` | Un seul point d'appel, vérifiable |
| Une URL de scène complète manipulée par le client | `GATES.md` G19, P4 |
| Une clé marchande de paiement dans l'APK | P11 |
| Une exception qui traverse la couche domaine | `Either<Failure, T>` imposé |
| Un paiement mis en file d'attente hors-ligne | §8 |
| Une story close sans son événement d'analytique | P12 |
