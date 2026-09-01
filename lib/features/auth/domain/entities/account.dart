import 'package:equatable/equatable.dart';

/// Les TROIS profils publics — SCREEN_ROLE_MATRIX.md §1.
///
/// Les documents v2 en listaient six : c'était un mélange de deux choses
/// différentes. `agency` est une VARIANTE de propriétaire, pas un quatrième
/// profil. `field_agent` et `admin` sont des outils internes — build à drapeau
/// et console web — et n'ont rien à faire dans l'inscription publique.
enum UserRole {
  /// Cherche, visite, garde, candidate. Le seul qui peut rester anonyme.
  tenant('locataire', 'Je cherche un logement'),

  /// Apporte des biens, suit ses commissions. C'est lui qui alimente le stock.
  broker('demarcheur', "J'apporte des biens"),

  /// Publie, reçoit des demandes, encaisse.
  owner('proprietaire', "J'ai un bien à louer");

  const UserRole(this.dbValue, this.entryLabel);

  /// Valeur stockée dans `profiles.role`.
  final String dbValue;

  /// Ce que l'utilisateur lit sur l'écran d'aiguillage. On ne lui demande pas
  /// « quel est ton profil » — on lui demande ce qu'il vient faire.
  final String entryLabel;

  static UserRole fromDb(String? v) => switch (v) {
    'broker' || 'demarcheur' => UserRole.broker,
    'owner' || 'proprietaire' || 'agency' => UserRole.owner,
    _ => UserRole.tenant,
  };
}

class Account extends Equatable {
  const Account({
    required this.id,
    required this.role,
    required this.phone,
    this.email,
    this.fullName,
    this.isPhoneVerified = false,
    this.hasAcceptedTerms = false,
  });

  final String id;
  final UserRole role;
  final String phone;

  /// Sert a l'authentification, pas a joindre l'utilisateur.
  final String? email;

  final String? fullName;
  final bool isPhoneVerified;

  /// Obligation loi n°2017-20 / APDP. Un compte sans consentement explicite
  /// n'est pas exploitable.
  final bool hasAcceptedTerms;

  @override
  List<Object?> get props => [
    id,
    role,
    phone,
    isPhoneVerified,
    hasAcceptedTerms,
  ];
}

/// CONSTITUTION P2 — « L'absence de session est un état de plein droit. »
///
/// Le chercheur navigue, visite et reçoit sa première visite offerte sans
/// jamais s'identifier. Le propriétaire et le démarcheur, eux, arrivent AVEC
/// une intention : leur première action est de donner quelque chose au
/// système, et s'identifier n'y est pas ressenti comme un péage.
sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// État de plein droit, pas une absence.
final class Anonymous extends AuthState {
  const Anonymous();
}

/// L'anonyme a demande un compte de lui-meme — typiquement apres avoir garde
/// un bien. Distinct de `Anonymous` : ici on OUVRE le tunnel, on ne se
/// contente pas de ne pas etre connecte.
final class SignUpRequested extends AuthState {
  const SignUpRequested();
}

/// Le code part par E-MAIL (pas de budget SMS au lancement), mais le NUMERO
/// reste collecte : c'est lui l'identite sur ce marche, et c'est par lui que
/// passeront les rappels de visite, de loyer et de quittance via WhatsApp.
///
/// L'e-mail est le canal technique. Le telephone est la donnee produit.
final class AwaitingOtp extends AuthState {
  const AwaitingOtp({
    required this.email,
    required this.phone,
    required this.intendedRole,
  });
  final String email;
  final String phone;
  final UserRole intendedRole;
  @override
  List<Object?> get props => [email, phone, intendedRole];
}

final class NeedsConsent extends AuthState {
  const NeedsConsent(this.account);
  final Account account;
  @override
  List<Object?> get props => [account];
}

final class Authenticated extends AuthState {
  const Authenticated(this.account);
  final Account account;
  @override
  List<Object?> get props => [account];
}
