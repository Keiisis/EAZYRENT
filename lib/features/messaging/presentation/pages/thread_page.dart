import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// S10b — Une conversation.
///
/// Deux décisions viennent du terrain béninois, pas de la convention :
///
///   · LE BOUTON MICRO A LA MÊME TAILLE QUE L'ENVOI. Taper au clavier sur un
///     Tecno d'entrée de gamme, debout, une main sur un sac, est lent et
///     pénible. Parler ne l'est pas. Le vocal est déjà le mode dominant sur
///     WhatsApp ici — on n'introduit pas un usage, on cesse de le contrarier.
///
///   · LES RÉPONSES SUGGÉRÉES évitent l'angoisse de la page blanche, qui est
///     la première cause de conversation jamais démarrée. Elles sont
///     contextuelles au bien, pas génériques.
class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    required this.name,
    required this.badge,
    required this.about,
    super.key,
  });

  final String name;
  final String badge;
  final String about;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _controller = TextEditingController();
  final _messages = <_Msg>[
    const _Msg('Bonjour, le bien de Fidjrossè est-il toujours libre ?', true),
    const _Msg(
      'Oui, il est toujours libre. Tu peux passer samedi après-midi.',
      false,
    ),
  ];
  bool _recording = false;

  static const _suggestions = [
    'Le bien est-il toujours libre ?',
    "L'avance est-elle négociable ?",
    'Je peux visiter samedi ?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Msg(text.trim(), true));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: AppText.titleM.copyWith(color: p.inkStrong),
            ),
            Text(
              '${widget.badge} · ${widget.about}',
              style: AppText.caption.copyWith(color: p.success),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(Space.md),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _Bubble(message: _messages[i]),
                  ),
                ),

                // Les suggestions ne s'affichent que tant que la conversation
                // est courte : passé les premiers échanges, elles deviennent
                // du bruit.
                if (_messages.length <= 3)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: Space.md),
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
          ),
        ),
      ),
    );
  }
}

class _Msg {
  const _Msg(this.text, this.mine);
  final String text;
  final bool mine;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _Msg message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mine = message.mine;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          // Le message de l'utilisateur n'utilise PAS la couleur d'action :
          // le terracotta signale une action à faire, pas un texte déjà écrit.
          color: mine ? p.surfaceSunken : p.surfaceRaised,
          border: mine ? null : Border.all(color: p.lineHair),
          borderRadius: const BorderRadius.all(Radii.card),
        ),
        child: Text(
          message.text,
          style: AppText.bodyL.copyWith(color: p.inkBase),
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
