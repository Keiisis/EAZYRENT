import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../domain/entities/conversation.dart';

/// La messagerie, sur les VRAIES tables : `chat_conversations` et
/// `chat_messages` (DATABASE_SCHEMA.sql §11).
///
/// Deux particularités du schéma qui gouvernent tout ce fichier :
///
///   · une conversation a `participant_one` et `participant_two`, PAS une
///     liste de participants. « L'autre » se déduit donc en comparant à
///     l'utilisateur courant, des deux côtés ;
///   · `last_message_preview` et `last_message_at` sont DÉNORMALISÉS sur la
///     conversation. C'est ce qui permet d'afficher la liste en UNE requête
///     au lieu d'une par fil — la différence entre un écran instantané et un
///     écran qui rame sur un forfait béninois.
abstract interface class MessagingRepository {
  Future<Either<Failure, List<Conversation>>> conversations();

  Future<Either<Failure, List<ChatMessage>>> messages(String conversationId);

  /// Rend le message TEL QUE LE SERVEUR L'A ENREGISTRÉ, avec son identifiant
  /// définitif : c'est lui qui remplace le message optimiste à l'écran.
  Future<Either<Failure, ChatMessage>> send({
    required String conversationId,
    required String text,
  });

  /// Flux temps réel des messages d'un fil. Se ferme avec l'écran.
  Stream<ChatMessage> watch(String conversationId);

  Future<Either<Failure, void>> markRead(String conversationId);

  /// Ouvre — ou retrouve — le fil entre l'utilisateur et un autre profil sur
  /// un bien. Créer un doublon à chaque message serait le moyen le plus sûr
  /// de perdre l'historique.
  Future<Either<Failure, String>> openWith({
    required String otherProfileId,
    String? listingId,
  });
}

class SupabaseMessagingRepository implements MessagingRepository {
  SupabaseMessagingRepository(this._db);

  final SupabaseClient _db;

  String? get _me => _db.auth.currentUser?.id;

  @override
  Future<Either<Failure, List<Conversation>>> conversations() async {
    final me = _me;
    if (me == null) return const Left(NotAuthenticatedFailure());

    try {
      // Une seule requête, jointures comprises. `participant_one` et
      // `participant_two` sont désambiguïsés par le nom de la contrainte :
      // sans ça PostgREST ne sait pas laquelle des deux clés étrangères
      // suivre, et rend une erreur au lieu d'une conversation.
      final rows = await _db
          .from('chat_conversations')
          .select('''
            id, listing_id, participant_one, participant_two,
            last_message_preview, last_message_at,
            one:profiles!chat_conversations_participant_one_fkey(id, full_name, role, avatar_url),
            two:profiles!chat_conversations_participant_two_fkey(id, full_name, role, avatar_url),
            listing:listings(property_type, neighborhood, city)
          ''')
          .or('participant_one.eq.$me,participant_two.eq.$me')
          .order('last_message_at', ascending: false)
          .limit(50);

      // Les non-lus, en UNE requête pour tous les fils plutôt qu'une par fil.
      final unreadIds = await _unreadConversationIds(me);

      return Right([for (final r in rows) _toConversation(r, me, unreadIds)]);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  Future<Set<String>> _unreadConversationIds(String me) async {
    try {
      final rows = await _db
          .from('chat_messages')
          .select('conversation_id')
          .eq('is_read', false)
          .neq('sender_id', me);
      return {for (final r in rows) r['conversation_id'] as String};
    } catch (_) {
      // Un compteur de non-lus indisponible ne doit pas faire disparaître la
      // liste des conversations. On rend « tout lu » plutôt que rien.
      return const {};
    }
  }

  Conversation _toConversation(
    Map<String, dynamic> r,
    String me,
    Set<String> unread,
  ) {
    final oneId = r['participant_one'] as String;
    final other = (oneId == me ? r['two'] : r['one']) as Map<String, dynamic>?;
    final listing = r['listing'] as Map<String, dynamic>?;

    return Conversation(
      id: r['id'] as String,
      // Un profil sans nom existe : on ne montre pas « null », on montre ce
      // qu'on sait.
      otherName: (other?['full_name'] as String?)?.trim().isNotEmpty == true
          ? other!['full_name'] as String
          : 'Contact',
      otherRole: other?['role'] as String? ?? 'tenant',
      otherAvatarUrl: other?['avatar_url'] as String?,
      lastMessage: r['last_message_preview'] as String? ?? '',
      lastMessageAt: DateTime.parse(r['last_message_at'] as String),
      unread: unread.contains(r['id']),
      listingId: r['listing_id'] as String?,
      listingLabel: listing == null
          ? null
          : '${listing['property_type']} · '
                '${listing['neighborhood'] ?? listing['city']}',
    );
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> messages(String id) async {
    try {
      final rows = await _db
          .from('chat_messages')
          .select(
            'id, conversation_id, sender_id, message_text, '
            'attachment_url, is_read, sent_at',
          )
          .eq('conversation_id', id)
          .order('sent_at', ascending: true)
          .limit(200);
      return Right([for (final r in rows) _toMessage(r)]);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  ChatMessage _toMessage(Map<String, dynamic> r) => ChatMessage(
    id: r['id'] as String,
    conversationId: r['conversation_id'] as String,
    senderId: r['sender_id'] as String,
    text: r['message_text'] as String? ?? '',
    attachmentUrl: r['attachment_url'] as String?,
    isRead: r['is_read'] as bool? ?? false,
    sentAt: DateTime.parse(r['sent_at'] as String),
  );

  @override
  Future<Either<Failure, ChatMessage>> send({
    required String conversationId,
    required String text,
  }) async {
    final me = _me;
    if (me == null) return const Left(NotAuthenticatedFailure());

    try {
      final row = await _db
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': me,
            'message_text': text,
          })
          .select()
          .single();

      // L'aperçu de la conversation est dénormalisé : sans cette mise à jour,
      // la liste continuerait d'afficher l'avant-dernier message.
      await _db
          .from('chat_conversations')
          .update({
            'last_message_preview': text.length > 120
                ? '${text.substring(0, 117)}…'
                : text,
            'last_message_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', conversationId);

      return Right(_toMessage(row));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }

  @override
  Stream<ChatMessage> watch(String conversationId) {
    // `stream` de Supabase ouvre un canal Realtime. Le filtre est appliqué
    // CÔTÉ SERVEUR : sans `eq`, on recevrait tous les messages de la base et
    // on les jetterait sur le téléphone de l'utilisateur — data payée pour
    // rien.
    return _db
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('sent_at')
        .map((rows) => rows.map(_toMessage).toList())
        .expand((list) => list);
  }

  @override
  Future<Either<Failure, void>> markRead(String conversationId) async {
    final me = _me;
    if (me == null) return const Left(NotAuthenticatedFailure());
    try {
      // On ne marque QUE les messages reçus. Marquer les siens n'a aucun
      // sens et fausserait le compteur de l'autre.
      await _db
          .from('chat_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', me);
      return const Right(null);
    } catch (e) {
      // Un accusé de lecture perdu n'est pas un incident : on n'affiche rien.
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, String>> openWith({
    required String otherProfileId,
    String? listingId,
  }) async {
    final me = _me;
    if (me == null) return const Left(NotAuthenticatedFailure());

    try {
      // On cherche le fil DANS LES DEUX SENS : « moi/lui » et « lui/moi »
      // désignent la même conversation. Ne chercher que dans un sens crée un
      // doublon une fois sur deux, et coupe l'historique en deux.
      final existing = await _db
          .from('chat_conversations')
          .select('id')
          .or(
            'and(participant_one.eq.$me,participant_two.eq.$otherProfileId),'
            'and(participant_one.eq.$otherProfileId,participant_two.eq.$me)',
          )
          .limit(1)
          .maybeSingle();

      if (existing != null) return Right(existing['id'] as String);

      final created = await _db
          .from('chat_conversations')
          .insert({
            'participant_one': me,
            'participant_two': otherProfileId,
            'listing_id': listingId,
            'last_message_preview': '',
          })
          .select('id')
          .single();

      return Right(created['id'] as String);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(debug: '${e.code} ${e.message}'));
    } catch (e) {
      return Left(NetworkFailure(debug: e.toString()));
    }
  }
}
