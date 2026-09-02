import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/messaging_repository.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/thread_cubit.dart';

/// S10b — Une conversation, en temps réel.
///
/// Trois décisions viennent du terrain béninois, pas de la convention :
///
///   · LE BOUTON MICRO A LA MÊME TAILLE QUE L'ENVOI. Taper au clavier sur un
///     Tecno d'entrée de gamme, debout, une main sur un sac, est lent et
///     pénible. Parler ne l'est pas. Le vocal est déjà le mode dominant sur
///     WhatsApp ici — on n'introduit pas un usage, on cesse de le contrarier.
///
///   · L'ENVOI EST OPTIMISTE. Le message s'affiche avant la réponse du
///     serveur. Sur deux barres de réseau, attendre l'aller-retour fait
///     croire à un échec, et la personne retape.
///
///   · UN ÉCHEC NE FAIT PAS DISPARAÎTRE LE MESSAGE. Il le marque et propose
///     de réessayer d'un doigt.
class ThreadScreen extends StatelessWidget {
  const ThreadScreen({required this.conversation, super.key});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null) return const _MustSignIn();

    return BlocProvider(
      create: (_) =>
          ThreadCubit(getIt<MessagingRepository>(), conversation.id, me)
            ..load(),
      child: _ThreadView(conversation: conversation),
    );
  }
}

class _ThreadView extends StatefulWidget {
  const _ThreadView({required this.conversation});

  final Conversation conversation;

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _recording = false;

  /// Contextuelles au bien, jamais génériques. Elles évitent l'angoisse de la
  /// page blanche, qui est la première cause de conversation jamais démarrée.
  static const _suggestions = [
    'Le bien est-il toujours libre ?',
    "L'avance est-elle négociable ?",
    'Je peux visiter samedi ?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    context.read<ThreadCubit>().send(text);
    _controller.clear();
    // On descend APRÈS la construction : sauter avant que le message soit
    // dans la liste ne descend nulle part.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: Motion.base,
          curve: Motion.standard,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = widget.conversation;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.otherName,
              style: AppText.titleM.copyWith(color: p.inkStrong),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              c.listingLabel == null
                  ? c.badge
                  : '${c.badge} · ${c.listingLabel}',
              style: AppText.caption.copyWith(color: p.success),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: BlocBuilder<ThreadCubit, ThreadState>(
              builder: (context, state) => switch (state) {
                ThreadLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ThreadError(:final failure) => _ErrorBody(
                  message: failure.userMessage,
                  onRetry: context.read<ThreadCubit>().load,
                ),
                ThreadReady(:final messages, :final myId) => Column(
                  children: [
                    Expanded(
                      child: messages.isEmpty
                          ? _FirstMessage(name: c.otherName)
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.all(Space.md),
                              itemCount: messages.length,
                              itemBuilder: (_, i) => _Bubble(
                                message: messages[i],
                                mine: messages[i].senderId == myId,
                                onRetry: () => context
                                    .read<ThreadCubit>()
                                    .retry(messages[i]),
                              ),
                            ),
                    ),

                    // Les suggestions ne s'affichent que tant que la
                    // conversation est courte : passé les premiers échanges,
                    // elles deviennent du bruit.
                    if (messages.length <= 3)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.md,
                          ),
                          children: [
                            for (final s in _suggestions)
                              Padding(
                                padding: const EdgeInsets.only(right: Space.xs),
                                child: ActionChip(
                                  label: Text(s),
                                  onPressed: () => _send(s),
                                  backgroundColor: p.surfaceRaised,
                                  side: BorderSide(color: p.lineHair),
                                ),
                              ),
                          ],
                        ),
                      ),

                    _Composer(
                      controller: _controller,
                      recording: _recording,
                      onSend: () => _send(_controller.text),
                      onMic: () => setState(() => _recording = !_recording),
                    ),
                  ],
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.onRetry,
  });

  final ChatMessage message;
  final bool mine;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: Space.xxs),
            padding: const EdgeInsets.symmetric(
              horizontal: Space.sm,
              vertical: Space.xs,
            ),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              // Le message de l'utilisateur n'utilise PAS la couleur
              // d'action : le terracotta signale une action à faire, pas un
              // texte déjà écrit.
              color: mine ? p.surfaceSunken : p.surfaceRaised,
              border: mine ? null : Border.all(color: p.lineHair),
              borderRadius: const BorderRadius.all(Radii.card),
            ),
            child: Opacity(
              // Le message en attente est visible mais estompé : on voit
              // qu'il est parti sans croire qu'il est arrivé.
              opacity: message.pending ? 0.6 : 1,
              child: Text(
                message.text,
                style: AppText.bodyL.copyWith(color: p.inkBase),
              ),
            ),
          ),

          if (message.failed)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 14, color: p.danger),
                  const SizedBox(width: Space.xxs),
                  Text(
                    'Non envoyé',
                    style: AppText.caption.copyWith(color: p.danger),
                  ),
                  const SizedBox(width: Space.xs),
                  // Le texte n'est jamais perdu : on le renvoie tel quel.
                  InkWell(
                    onTap: onRetry,
                    child: Text(
                      'Réessayer',
                      style: AppText.caption.copyWith(
                        color: p.action,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FirstMessage extends StatelessWidget {
  const _FirstMessage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Text(
          'Écris à $name. Les questions les plus utiles sont juste en dessous.',
          textAlign: TextAlign.center,
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

class _MustSignIn extends StatelessWidget {
  const _MustSignIn();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(backgroundColor: p.surfaceBase),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Text(
            'Crée un compte pour écrire et garder tes échanges.',
            textAlign: TextAlign.center,
            style: AppText.bodyL.copyWith(color: p.inkMuted),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.recording,
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool recording;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final target = Touch.target(p.isHighContrast);

    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        boxShadow: Elevation.stickyBar,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: AppText.bodyL.copyWith(color: p.inkStrong),
              decoration: const InputDecoration(
                hintText: 'Écris un message',
                labelText: null,
              ),
            ),
          ),
          const SizedBox(width: Space.xs),

          // MÊME taille que l'envoi. Le vocal n'est pas un raccourci
          // secondaire : c'est le mode d'entrée principal pour beaucoup.
          _RoundAction(
            size: target,
            icon: recording ? Icons.stop : Icons.mic_none,
            tooltip: recording ? 'Arrêter' : 'Message vocal',
            background: recording ? p.danger : p.surfaceSunken,
            foreground: recording ? p.surfaceRaised : p.inkBase,
            onTap: onMic,
          ),
          const SizedBox(width: Space.xs),
          _RoundAction(
            size: target,
            icon: Icons.send,
            tooltip: 'Envoyer',
            background: p.actionFill,
            foreground: p.actionOnFill,
            onTap: onSend,
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: foreground, size: 20),
      ),
    ),
  );
}
