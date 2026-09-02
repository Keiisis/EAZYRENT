import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../data/messaging_repository.dart';
import '../../domain/entities/conversation.dart';

sealed class ConversationsState extends Equatable {
  const ConversationsState();
  @override
  List<Object?> get props => [];
}

final class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

final class ConversationsReady extends ConversationsState {
  const ConversationsReady(this.items);
  final List<Conversation> items;
  @override
  List<Object?> get props => [items];
}

/// L'état vide n'est PAS une erreur : c'est le cas normal de quelqu'un qui
/// vient d'arriver. Il porte donc son propre état, pour que l'écran puisse
/// proposer une issue au lieu d'afficher une liste blanche.
final class ConversationsEmpty extends ConversationsState {
  const ConversationsEmpty();
}

final class ConversationsError extends ConversationsState {
  const ConversationsError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit(this._repo) : super(const ConversationsLoading());

  final MessagingRepository _repo;

  Future<void> load() async {
    final result = await _repo.conversations();
    result.match(
      (f) => emit(ConversationsError(f)),
      (items) => emit(
        items.isEmpty ? const ConversationsEmpty() : ConversationsReady(items),
      ),
    );
  }

  /// Rechargement silencieux au retour d'un fil : sans lui, l'aperçu et le
  /// compteur de non-lus resteraient sur leur valeur d'avant la lecture.
  Future<void> refresh() => load();
}
