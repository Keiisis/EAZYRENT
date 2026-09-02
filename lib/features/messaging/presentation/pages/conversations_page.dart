import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/domain/entities/account.dart';
import '../../data/messaging_repository.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/conversations_cubit.dart';
import 'thread_page.dart';

/// S10 — Messages. Le seul écran partagé par les TROIS profils.
///
/// Les fils viennent de `chat_conversations`. Plus aucune donnée de
/// démonstration : ce qui s'affiche ici existe en base.
///
/// L'état vide change selon le rôle, parce que « aucun message » ne veut pas
/// dire la même chose pour un chercheur (personne à qui écrire encore) et
/// pour un propriétaire (personne ne s'intéresse à son bien). L'issue
/// proposée diffère donc aussi.
///
/// Le statut de l'interlocuteur est TOUJOURS affiché en clair — « Bailleur »,
/// « Agent EAZYRENT ». Jamais un pseudonyme nu : sur un marché où l'arnaque
/// est la crainte n°1, savoir à qui on parle fait partie du produit.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({required this.role, super.key});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ConversationsCubit(getIt<MessagingRepository>())..load(),
      child: _ConversationsView(role: role),
    );
  }
}

class _ConversationsView extends StatelessWidget {
  const _ConversationsView({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: BlocBuilder<ConversationsCubit, ConversationsState>(
              builder: (context, state) => switch (state) {
                ConversationsLoading() => const _Skeleton(),
                ConversationsEmpty() => _Empty(role: role),
                ConversationsError(:final failure) => _Error(
                  message: failure.userMessage,
                  onRetry: context.read<ConversationsCubit>().load,
                ),
                ConversationsReady(:final items) => RefreshIndicator(
                  onRefresh: context.read<ConversationsCubit>().refresh,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.md,
                          Space.xs,
                          Space.md,
                          Space.sm,
                        ),
                        child: Text(
                          'Messages',
                          style: AppText.titleL.copyWith(color: p.inkStrong),
                        ),
                      ),
                      for (final c in items) _ConversationRow(conversation: c),
                    ],
                  ),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = conversation;

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ThreadScreen(conversation: c),
          ),
        );
        // Au retour, l'aperçu et le compteur de non-lus ont changé.
        if (context.mounted) await context.read<ConversationsCubit>().refresh();
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: Touch.target(p.isHighContrast) + 24,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: p.surfaceSunken,
              backgroundImage: c.otherAvatarUrl == null
                  ? null
                  : NetworkImage(c.otherAvatarUrl!),
              child: c.otherAvatarUrl != null
                  ? null
                  : Icon(Icons.person_outline, color: p.inkMuted, size: 20),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.otherName,
                          style: AppText.bodyL.copyWith(
                            color: p.inkStrong,
                            fontWeight: c.unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        c.whenLabel(),
                        style: AppText.caption.copyWith(color: p.inkMuted),
                      ),
                    ],
                  ),
                  // Le statut, toujours en clair. Jamais un pseudonyme nu.
                  Text(
                    c.listingLabel == null
                        ? c.badge
                        : '${c.badge} · ${c.listingLabel}',
                    style: AppText.label.copyWith(color: p.success),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Space.xxs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage.isEmpty
                              ? 'Conversation ouverte'
                              : c.lastMessage,
                          style: AppText.bodyM.copyWith(
                            color: c.unread ? p.inkBase : p.inkMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (c.unread) ...[
                        const SizedBox(width: Space.xs),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: p.action,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Trois lignes grises aux DIMENSIONS RÉELLES des conversations : quand
    // les données arrivent, rien ne saute.
    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Row(
              children: [
                CircleAvatar(radius: 22, backgroundColor: p.surfaceSunken),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 140, color: p.surfaceSunken),
                      const SizedBox(height: Space.xs),
                      Container(
                        height: 12,
                        width: double.infinity,
                        color: p.surfaceSunken,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// « Toujours une action. » Et l'action dépend du rôle : un chercheur sans
/// message doit aller chercher, un propriétaire sans message doit rendre son
/// bien plus visible.
class _Empty extends StatelessWidget {
  const _Empty({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (title, body, action) = switch (role) {
      UserRole.tenant => (
        'Aucun message pour l\'instant.',
        'Quand tu demandes un rendez-vous, la conversation apparaît ici.',
        'Aller chercher un logement',
      ),
      UserRole.owner => (
        'Personne ne t\'a encore écrit.',
        'Les demandes arrivent quand ton bien est vu. Une Visite Vérifiée '
            'attire des visiteurs qui savent déjà ce qu\'ils viennent voir.',
        'Voir mes biens',
      ),
      UserRole.broker => (
        'Aucun message pour l\'instant.',
        'Un agent EAZYRENT t\'écrit ici quand il vérifie un bien que tu as '
            'apporté.',
        'Apporter un bien',
      ),
    };

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.titleM.copyWith(color: p.inkStrong)),
          const SizedBox(height: Space.sm),
          Text(body, style: AppText.bodyL.copyWith(color: p.inkMuted)),
          const SizedBox(height: Space.lg),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, Touch.target(p.isHighContrast)),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppText.bodyL.copyWith(color: p.inkStrong)),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              minimumSize: Size(0, Touch.target(p.isHighContrast)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
