import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../data/messaging_repository.dart';
import '../../domain/entities/conversation.dart';

sealed class ThreadState extends Equatable {
  const ThreadState();
  @override
  List<Object?> get props => [];
}

final class ThreadLoading extends ThreadState {
  const ThreadLoading();
}

final class ThreadReady extends ThreadState {
  const ThreadReady({required this.messages, required this.myId});

  final List<ChatMessage> messages;
  final String myId;

  @override
  List<Object?> get props => [messages];
}

final class ThreadError extends ThreadState {
  const ThreadError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

/// Un fil de discussion, en temps réel.
///
/// L'ENVOI EST OPTIMISTE. Le message apparaît AVANT la réponse du serveur,
/// marqué en attente. Sur une connexion à deux barres, attendre l'aller-retour
/// donne l'impression que l'envoi a échoué — et la personne retape son
/// message. On préfère afficher tout de suite, et corriger si ça échoue.
///
/// UN ÉCHEC NE FAIT PAS DISPARAÎTRE LE MESSAGE. Il le marque, et propose de
/// réessayer. Perdre silencieusement ce que quelqu'un vient d'écrire est la
/// pire chose qu'une messagerie puisse faire.
class ThreadCubit extends Cubit<ThreadState> {
  ThreadCubit(this._repo, this.conversationId, this.myId)
    : super(const ThreadLoading());

  final MessagingRepository _repo;
  final String conversationId;
  final String myId;

  StreamSubscription<ChatMessage>? _sub;

  /// Messages en attente ou échoués, hors du serveur. Ils vivent ici plutôt
  /// que dans la liste serveur : le flux temps réel écrase la liste à chaque
  /// événement, et emporterait avec lui tout ce qui n'est pas confirmé.
  final _local = <ChatMessage>[];
  List<ChatMessage> _server = const [];

  Future<void> load() async {
    final result = await _repo.messages(conversationId);
    result.match((f) => emit(ThreadError(f)), (list) {
      _server = list;
      _emitMerged();
      _listen();
      unawaited(_repo.markRead(conversationId));
    });
  }

  void _listen() {
    _sub?.cancel();
    _sub = _repo.watch(conversationId).listen((msg) {
      // Un message qui arrive du serveur remplace son jumeau optimiste :
      // sans ce retrait, l'utilisateur verrait son propre message en double.
      _local.removeWhere((m) => m.pending && m.text == msg.text);
      if (_server.any((m) => m.id == msg.id)) return;
      _server = [..._server, msg]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      _emitMerged();
      if (msg.senderId != myId) unawaited(_repo.markRead(conversationId));
    });
  }

  void _emitMerged() {
    emit(ThreadReady(messages: [..._server, ..._local], myId: myId));
  }

  Future<void> send(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final optimistic = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: myId,
      text: clean,
      sentAt: DateTime.now(),
      isRead: false,
      pending: true,
    );
    _local.add(optimistic);
    _emitMerged();

    final result = await _repo.send(
      conversationId: conversationId,
      text: clean,
    );
    result.match(
      (_) {
        final i = _local.indexWhere((m) => m.id == optimistic.id);
        if (i >= 0) {
          _local[i] = optimistic.copyWith(pending: false, failed: true);
        }
        _emitMerged();
      },
      (saved) {
        _local.removeWhere((m) => m.id == optimistic.id);
        if (!_server.any((m) => m.id == saved.id)) {
          _server = [..._server, saved];
        }
        _emitMerged();
      },
    );
  }

  /// Réessayer un message échoué. Il repart tel quel : on ne demande jamais
  /// de le retaper.
  Future<void> retry(ChatMessage failed) async {
    _local.removeWhere((m) => m.id == failed.id);
    await send(failed.text);
  }

  @override
  Future<void> close() {
    // Le canal Realtime se ferme AVEC l'écran. Un canal laissé ouvert
    // continue de consommer de la data pour un fil que plus personne ne
    // regarde.
    _sub?.cancel();
    return super.close();
  }
}
