import 'package:equatable/equatable.dart';

/// Les quatre fournisseurs, et le public de chacun.
///
/// L'ORDRE EST CELUI DU MARCHÉ, pas celui de la notoriété mondiale. KkiaPay
/// et FedaPay agrègent MTN MoMo, Moov Flooz et Celtiis Cash : ce sont eux qui
/// encaissent 95 % des paiements à Cotonou. Stripe et Revolut n'existent que
/// pour la diaspora — quelqu'un à Paris qui paie le loyer d'un frère à
/// Godomey. Mettre la carte bancaire en premier serait recopier une
/// hiérarchie occidentale sur un marché qui ne l'est pas.
enum PaymentProvider {
  kkiapay,
  fedapay,
  stripe,
  revolut;

  String get label => switch (this) {
    PaymentProvider.kkiapay => 'Mobile Money',
    PaymentProvider.fedapay => 'Mobile Money (FedaPay)',
    PaymentProvider.stripe => 'Carte bancaire',
    PaymentProvider.revolut => 'Revolut',
  };

  /// Ce que la personne verra vraiment derrière le bouton.
  String get hint => switch (this) {
    PaymentProvider.kkiapay => 'MTN MoMo · Moov Flooz · Celtiis Cash',
    PaymentProvider.fedapay => 'MTN MoMo · Moov Flooz',
    PaymentProvider.stripe => 'Visa · Mastercard',
    PaymentProvider.revolut => 'Compte Revolut · carte',
  };

  /// Les deux agrégateurs béninois ne traitent QUE le franc CFA. Proposer
  /// « payer en euros » avec KkiaPay produit un refus incompréhensible.
  bool get xofOnly =>
      this == PaymentProvider.kkiapay || this == PaymentProvider.fedapay;

  /// Réservé à la diaspora : on ne le propose pas par défaut à quelqu'un
  /// connecté depuis Cotonou.
  bool get isInternational =>
      this == PaymentProvider.stripe || this == PaymentProvider.revolut;
}

enum PaymentStatus { pending, paid, failed, cancelled }

/// Ce que le SERVEUR rend après avoir créé la transaction.
///
/// Le client ne fabrique jamais ces valeurs : il les reçoit. C'est la leçon
/// n°1 du template — « l'ID de transaction est connu avant le paiement, et la
/// vérification côté serveur fonctionnera correctement ».
class PaymentIntent extends Equatable {
  const PaymentIntent({
    required this.reference,
    required this.provider,
    required this.amountFcfa,
    required this.checkoutUrl,
  });

  /// Notre référence, générée en base. C'est elle qu'on cite au support, et
  /// elle qu'on interroge pour vérifier — jamais l'identifiant du
  /// fournisseur, qui change d'un fournisseur à l'autre.
  final String reference;

  final PaymentProvider provider;
  final int amountFcfa;

  /// La page hébergée du fournisseur. Le client l'ouvre, il ne la reconstruit
  /// pas : aucune clé, aucun montant, aucun paramètre ne transite par lui.
  final String checkoutUrl;

  @override
  List<Object?> get props => [reference, provider, amountFcfa];
}

class PaymentResult extends Equatable {
  const PaymentResult({
    required this.reference,
    required this.status,
    required this.amountFcfa,
    this.creditsAdded = 0,
    this.message,
  });

  final String reference;
  final PaymentStatus status;
  final int amountFcfa;

  /// Crédits effectivement ajoutés, tels que le serveur les a écrits. Le
  /// client ne les calcule jamais lui-même.
  final int creditsAdded;

  final String? message;

  bool get isPaid => status == PaymentStatus.paid;

  @override
  List<Object?> get props => [reference, status, creditsAdded];
}
