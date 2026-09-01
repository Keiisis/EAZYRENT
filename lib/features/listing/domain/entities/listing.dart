import 'package:equatable/equatable.dart';

/// Fraîcheur — le composant n°2 de la Visite Vérifiée (UX_CORE_SPEC.md §2.1).
/// « Un tour 360 d'un bien déjà loué est pire que rien. »
enum FreshnessTone { ok, warn, stale }

class Freshness extends Equatable {
  const Freshness({required this.label, required this.tone});

  final String label;
  final FreshnessTone tone;

  /// L'horodatage est ABSOLU et précis : la précision *est* la preuve.
  /// Miroir exact de `web/lib/format.ts` — les deux surfaces doivent dire
  /// la même chose du même bien.
  factory Freshness.from(DateTime? checkedAt, {DateTime? now}) {
    if (checkedAt == null) {
      return const Freshness(
        label: 'Photos seulement',
        tone: FreshnessTone.stale,
      );
    }
    final ref = (now ?? DateTime.now()).toLocal();
    final at = checkedAt.toLocal();

    // JOUR CALENDAIRE, pas heures écoulées. Une vérification de 23h48 vue à
    // 07h48 date de 8 heures — mais elle a eu lieu HIER. Compter en heures
    // écoulées faisait dire « vérifié aujourd'hui 23h48 » à 7 h du matin.
    // Sur un produit qui vend la précision de sa datation, se tromper de jour
    // détruit précisément la confiance que cette ligne existe pour bâtir.
    final today = DateTime(ref.year, ref.month, ref.day);
    final checkDay = DateTime(at.year, at.month, at.day);
    final days = today.difference(checkDay).inDays;

    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');

    if (days <= 0) {
      return Freshness(
        label: "Vérifié aujourd'hui ${hh}h$mm",
        tone: FreshnessTone.ok,
      );
    }
    if (days == 1) {
      return Freshness(label: 'Vérifié hier ${hh}h$mm', tone: FreshnessTone.ok);
    }
    if (days <= 7) {
      return Freshness(
        label: 'Vérifié il y a $days jours',
        tone: FreshnessTone.warn,
      );
    }
    // « Non confirmé · 12 jours », et non « Non confirmé depuis 12 jours » :
    // le libellé long dépassait la colonne de la carte sur un écran de
    // 384 dp et se faisait couper en « Non confirmé depuis 12 jo… ».
    //
    // La coupure tombait sur le NOMBRE DE JOURS, c'est-à-dire sur la seule
    // partie qui dit à quel point l'information est vieille. Le point médian
    // rend les deux moitiés, et n'enlève rien : « depuis » ne portait aucun
    // sens que la structure ne porte déjà.
    return Freshness(
      label: 'Non confirmé · $days jours',
      tone: FreshnessTone.stale,
    );
  }

  @override
  List<Object?> get props => [label, tone];
}

/// Un bien tel que le feed en a besoin. Volontairement pauvre : le titre rédigé
/// par le bailleur n'y figure pas — « Belle chambre-salon moderne » n'informe
/// personne (UI_SCREENS_SPEC.md S02).
class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.monthlyRentFcfa,
    required this.propertyType,
    required this.city,
    required this.isAvailable,
    required this.hasVerifiedTour,
    required this.freshness,
    this.neighborhood,
    this.advanceMonths,
    this.totalMoveInCostFcfa,
    this.mainImageUrl,
    this.commuteMinutes,
    this.isSponsored = false,
  });

  final String id;
  final int monthlyRentFcfa;
  final String propertyType;
  final String? neighborhood;
  final String city;

  /// LE chiffre décisif : celui qui élimine 80 % des biens au Bénin.
  /// Il est sur la carte du feed, pas caché dans la fiche.
  final int? totalMoveInCostFcfa;
  final int? advanceMonths;

  final String? mainImageUrl;
  final bool hasVerifiedTour;
  final bool isAvailable;
  final Freshness freshness;

  /// F6 — n'existe que si l'utilisateur a posé un point d'ancrage.
  /// Sinon la ligne n'apparaît pas : aucun espace vide.
  final int? commuteMinutes;

  /// Un bien mis en avant porte la mention en clair. Jamais de tri payé caché.
  final bool isSponsored;

  String get locationLabel => neighborhood ?? city;

  @override
  List<Object?> get props => [id, monthlyRentFcfa, freshness, isAvailable];
}
