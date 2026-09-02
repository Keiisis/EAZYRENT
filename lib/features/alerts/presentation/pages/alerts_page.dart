import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import 'anchor_point_page.dart';
import 'notification_settings_page.dart';

/// S17 — Mes alertes et recherches sauvegardées.
///
/// « L'alerte quartier est l'action à plus fort rendement de rétention — sans
/// écran de gestion, elle est irrévocable ou invisible. »
/// (SCREEN_ROLE_MATRIX.md, écran manquant n°17)
///
/// Une alerte porte TROIS choses en clair : ce qu'elle surveille, ce qu'elle
/// a rapporté, et comment l'éteindre. Une alerte qu'on ne sait pas éteindre
/// se désinstalle avec l'application.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _alerts = <_Alert>[
    _Alert(
      quartier: 'Fidjrossè',
      maxEntry: 90000,
      type: 'Chambre-salon',
      found: 4,
      on: true,
    ),
    _Alert(
      quartier: 'Godomey',
      maxEntry: 120000,
      type: 'Studio',
      found: 0,
      on: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Alertes et recherches',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
        actions: [
          IconButton(
            tooltip: 'Réglages de notification',
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
                if (_alerts.isEmpty)
                  Text(
                    'Aucune alerte pour l\'instant. Depuis une recherche, '
                    '« Me prévenir » crée une alerte sur ces critères.',
                    style: AppText.bodyL.copyWith(color: p.inkMuted),
                  ),

                for (var i = 0; i < _alerts.length; i++)
                  _AlertCard(
                    alert: _alerts[i],
                    onToggle: (v) => setState(() => _alerts[i].on = v),
                    onDelete: () => setState(() => _alerts.removeAt(i)),
                  ),

                const SizedBox(height: Space.lg),

                // Le point d'ancrage vit ici : c'est lui qui donne son sens au
                // temps de trajet affiché sur chaque annonce. Le ranger dans
                // un réglage lointain le rendrait invisible.
                _Tile(
                  icon: Icons.my_location,
                  title: 'Mon point d\'ancrage',
                  body:
                      'Cotonou · Ganhi — le temps de trajet de chaque bien '
                      'est calculé depuis ce point.',
                  action: 'Modifier',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AnchorPointScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: Space.md),
                Text(
                  'Deux notifications de contenu par jour au maximum, jamais '
                  'entre 21 h et 7 h. Une alerte sans nouveau bien ne '
                  'notifie pas.',
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

class _Alert {
  _Alert({
    required this.quartier,
    required this.maxEntry,
    required this.type,
    required this.found,
    required this.on,
  });

  final String quartier;
  final int maxEntry;
  final String type;
  final int found;
  bool on;
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onToggle,
    required this.onDelete,
  });

  final _Alert alert;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = alert;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        border: Border.all(color: p.lineHair, width: p.borderWidth),
        borderRadius: const BorderRadius.all(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${a.type} · ${a.quartier}',
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(value: a.on, onChanged: onToggle),
            ],
          ),
          // Le critère décisif rappelé en clair : c'est le coût d'entrée qui
          // fait accepter ou refuser un bien ici, pas le loyer.
          Text(
            'Coût d\'entrée jusqu\'à ${MoneyFcfa.short(a.maxEntry)}',
            style: AppText.bodyM.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Icon(
                a.found > 0 ? Icons.check_circle : Icons.hourglass_empty,
                size: 15,
                color: a.found > 0 ? p.success : p.inkMuted,
              ),
              const SizedBox(width: Space.xxs),
              Expanded(
                child: Text(
                  a.found > 0
                      ? '${a.found} biens trouvés depuis la création'
                      : 'Aucun bien pour l\'instant — on cherche encore',
                  style: AppText.label.copyWith(
                    color: a.found > 0 ? p.success : p.inkMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  minimumSize: Size(0, Touch.target(p.isHighContrast)),
                  foregroundColor: p.inkMuted,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: const BorderRadius.all(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: p.inkBase),
              const SizedBox(width: Space.xs),
              Text(title, style: AppText.bodyL.copyWith(color: p.inkStrong)),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(body, style: AppText.bodyM.copyWith(color: p.inkMuted)),
          const SizedBox(height: Space.xs),
          OutlinedButton(
            onPressed: onTap,
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
