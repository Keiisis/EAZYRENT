import 'package:equatable/equatable.dart';

/// Un fil de discussion, tel que la LISTE en a besoin.
///
/// Il porte le nom ET le statut de l'interlocuteur. Sur un marché où
/// l'arnaque est la crainte n°1, « Mensah A. » seul ne sert à rien :
/// « Mensah A. · Bailleur vérifié » est ce qui fait ouvrir le fil.
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.otherName,
    required this.otherRole,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unread,
    this.listingId,
    this.listingLabel,
    this.otherAvatarUrl,
  });

  final String id;
  final String otherName;

  /// Rôle brut de `profiles.role`. Traduit à l'affichage, jamais stocké
  /// traduit : demain on ajoutera une langue, pas une colonne.
  final String otherRole;

  final String lastMessage;
  final DateTime lastMessageAt;
  final bool unread;

  /// Le bien dont on parle. Une conversation sans objet devient vite
  /// « bonjour » — et personne ne sait de quel logement il s'agit.
  final String? listingId;
  final String? listingLabel;
  final String? otherAvatarUrl;

  /// Le badge affiché. « Bailleur vérifié » se lit d'un coup d'œil ;
  /// « owner » ne veut rien dire pour un utilisateur.
  String get badge => switch (otherRole) {
    'owner' => 'Bailleur',
    'agency' => 'Agence',
    'broker' => 'Démarcheur',
    'field_agent' => 'Agent EAZYRENT',
    'admin' => 'Équipe EAZYRENT',
    _ => 'Locataire',
  };

  /// « 10:24 » aujourd'hui, « hier », puis la date. Personne ne lit
  /// « 2026-08-31T10:24:00Z », et « il y a 3 jours » oblige à calculer.
  String whenLabel({DateTime? now}) {
    final ref = (now ?? DateTime.now()).toLocal();
    final at = lastMessageAt.toLocal();
    final today = DateTime(ref.year, ref.month, ref.day);
    final day = DateTime(at.year, at.month, at.day);
    final days = today.difference(day).inDays;

    if (days <= 0) {
      final hh = at.hour.toString().padLeft(2, '0');
      final mm = at.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    if (days == 1) return 'hier';
    return '${at.day}/${at.month.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id, lastMessageAt, unread];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isRead,
    this.attachmentUrl,
    this.pending = false,
    this.failed = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final String? attachmentUrl;

  /// Écrit localement, pas encore confirmé par le serveur.
  ///
  /// Le message s'affiche IMMÉDIATEMENT, avec une marque d'attente. Sur une
  /// connexion à deux barres, attendre l'aller-retour avant d'afficher son
  /// propre message donne l'impression que l'envoi a échoué — et la personne
  /// le retape.
  final bool pending;

  /// L'envoi a échoué. Le message RESTE à l'écran, avec une issue : le
  /// perdre silencieusement est la pire des options.
  final bool failed;

  ChatMessage copyWith({bool? pending, bool? failed, String? id}) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        sentAt: sentAt,
        isRead: isRead,
        attachmentUrl: attachmentUrl,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
      );

  @override
  List<Object?> get props => [id, text, pending, failed, isRead];
}
