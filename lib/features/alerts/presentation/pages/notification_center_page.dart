import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import 'notification_settings_page.dart';

/// S20 — Centre de notifications.
///
/// « Une notification manquée est perdue à jamais. »
/// (SCREEN_ROLE_MATRIX.md, écran manquant n°20)
///
/// Le téléphone efface la bannière ; l'application, non. Sur des appareils
/// partagés — courant ici — la bannière est souvent balayée par quelqu'un
/// d'autre. Ce centre est le seul endroit où l'information survit.
///
/// CHAQUE LIGNE PORTE SON ACTION. Une notification qui raconte sans permettre
/// d'agir a coûté une interruption pour rien.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Démonstration tant que le module notifications n'a pas sa couche data.
    const items = [
      _Notif(
        icon: Icons.new_releases_outlined,
        title: '3 nouveaux biens à Fidjrossè',
        body: 'Coût d\'entrée sous 90 000 F, comme dans ton alerte.',
        when: 'il y a 2 h',
        action: 'Voir les biens',
        unread: true,
        transactional: false,
      ),
      _Notif(
        icon: Icons.event_available_outlined,
        title: 'Visite confirmée samedi 11 h',
        body: 'Chambre-salon Fidjrossè. Rappel J-1 à 18 h avec l\'itinéraire.',
        when: 'hier',
        action: 'Voir le rendez-vous',
        unread: true,
        transactional: true,
      ),
      _Notif(
        icon: Icons.price_change_outlined,
        title: 'Un bien gardé a baissé',
        body: 'Studio Godomey : 40 000 F → 35 000 F.',
        when: '2 mars',
        action: 'Ouvrir ma liste',
        unread: false,
        transactional: false,
      ),
    ];

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Notifications',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
        actions: [
          IconButton(
            tooltip: 'Réglages',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(Space.md),
              children: [
                for (final n in items) _NotifCard(notif: n),
                const SizedBox(height: Space.md),
                Text(
                  'Les notifications restent ici 30 jours, même effacées du '
                  'téléphone.',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Notif {
  const _Notif({
    required this.icon,
    required this.title,
    required this.body,
    required this.when,
    required this.action,
    required this.unread,
    required this.transactional,
  });

  final IconData icon;
  final String title;
  final String body;
  final String when;
  final String action;
  final bool unread;
  final bool transactional;
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notif});

  final _Notif notif;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = notif;
    // Le transactionnel se distingue par la couleur de son icône, jamais par
    // un fond alarmant : un loyer à payer n'est pas une erreur.
    final tint = n.transactional ? p.info : p.inkBase;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: n.unread ? p.surfaceRaised : p.surfaceBase,
        border: Border.all(color: n.unread ? p.lineStrong : p.lineHair),
        borderRadius: const BorderRadius.all(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(n.icon, size: 20, color: tint),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  n.title,
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: n.unread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Text(n.when, style: AppText.caption.copyWith(color: p.inkMuted)),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              n.body,
              style: AppText.bodyM.copyWith(color: p.inkMuted),
            ),
          ),
          const SizedBox(height: Space.xs),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, Touch.target(p.isHighContrast)),
              ),
              child: Text(n.action),
            ),
          ),
        ],
      ),
    );
  }
}
