import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/domain/entities/account.dart';
import 'thread_page.dart';

/// S10 — Messages. Le seul écran partagé par les TROIS profils.
///
/// L'état vide change selon le rôle, parce que « aucun message » ne veut pas
/// dire la même chose pour un chercheur (personne à qui écrire encore) et
/// pour un propriétaire (personne ne s'intéresse à son bien). L'issue
/// proposée diffère donc aussi.
///
/// Le statut de l'interlocuteur est TOUJOURS affiché en clair — « Bailleur
/// vérifié », « Agent EAZYRENT ». Jamais un pseudonyme nu : sur un marché où
/// l'arnaque est la crainte n°1, savoir à qui on parle fait partie du produit.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({required this.role, super.key});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Démonstration tant que le module messaging n'a pas sa couche data.
    final demo = switch (role) {
      UserRole.tenant => const [
        _Conversation(
          name: 'Mensah A.',
          badge: 'Bailleur vérifié',
          about: 'Chambre-salon Fidjrossè',
          preview: 'Oui le bien est toujours libre, tu peux passer samedi.',
          when: '10:24',
          unread: true,
        ),
        _Conversation(
          name: 'Rachid',
          badge: 'Agent EAZYRENT',
          about: 'Visite 360 · Godomey',
          preview: 'Le tour est en ligne depuis ce matin.',
          when: 'hier',
          unread: false,
        ),
      ],
      UserRole.owner => const [
        _Conversation(
          name: 'Koffi A.',
          badge: 'A visité en 360°',
          about: 'Chambre-salon Fidjrossè',
          preview: "Bonjour, l'avance est-elle négociable ?",
          when: '09:02',
          unread: true,
        ),
      ],
      UserRole.broker => const [
        _Conversation(
          name: 'Rachid',
          badge: 'Agent EAZYRENT',
          about: 'Villa Cadjèhoun',
          preview: 'On passe vérifier le bien demain matin.',
          when: '08:15',
          unread: false,
        ),
      ],
    };

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: demo.isEmpty
                ? _Empty(role: role)
                : ListView(
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
                      for (final c in demo) _ConversationRow(conversation: c),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Conversation {
  const _Conversation({
    required this.name,
    required this.badge,
    required this.about,
    required this.preview,
    required this.when,
    required this.unread,
  });

  final String name;
  final String badge;
  final String about;
  final String preview;
  final String when;
  final bool unread;
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final _Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = conversation;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ThreadScreen(name: c.name, badge: c.badge, about: c.about),
        ),
      ),
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
              child: Icon(Icons.person_outline, color: p.inkMuted, size: 20),
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
                          c.name,
                          style: AppText.bodyL.copyWith(
                            color: p.inkStrong,
                            fontWeight: c.unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        c.when,
                        style: AppText.caption.copyWith(color: p.inkMuted),
                      ),
                    ],
                  ),
                  // Le statut, toujours en clair. Jamais un pseudonyme nu.
                  Text(
                    '${c.badge} · ${c.about}',
                    style: AppText.label.copyWith(color: p.success),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Space.xxs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.preview,
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
