import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// S21 — Réglages de notification, PAR TYPE.
///
/// Exigé par la règle UX 8, jamais dessiné jusqu'ici.
///
/// Un interrupteur global « notifications » produit toujours le même résultat :
/// une personne agacée par UN type coupe TOUT, et on ne peut plus la prévenir
/// que son loyer est dû. Le réglage par type est ce qui évite le tout ou rien.
///
/// Deux catégories, et elles ne se valent pas :
///   · le CONTENU se coupe librement ;
///   · le TRANSACTIONNEL (paiement, RDV, loyer, quittance) se règle de canal,
///     pas d'existence. On ne propose pas à quelqu'un de ne plus être prévenu
///     qu'un paiement a échoué : ce serait lui rendre un mauvais service au
///     nom de sa tranquillité.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _content = <String, bool>{
    'Nouveau bien dans mes alertes': true,
    'Un bien gardé vient de baisser de prix': true,
    'Un bien gardé n\'est plus libre': true,
    'Conseils pour chercher moins cher': false,
  };

  final _transactional = <String, String>{
    'Paiement et reçus': 'whatsapp',
    'Rendez-vous et rappels de visite': 'whatsapp',
    'Loyer et quittances': 'whatsapp',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Réglages de notification',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(Space.md),
              children: [
                Text(
                  'CE QUE TU VEUX SAVOIR',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                for (final e in _content.entries)
                  _SwitchRow(
                    label: e.key,
                    value: e.value,
                    onChanged: (v) => setState(() => _content[e.key] = v),
                  ),

                const SizedBox(height: Space.lg),
                Text(
                  'OÙ TE JOINDRE',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Paiement, rendez-vous et loyer arrivent toujours. Tu choisis '
                  'seulement par où.',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                for (final e in _transactional.entries)
                  _ChannelRow(
                    label: e.key,
                    value: e.value,
                    onChanged: (v) => setState(() => _transactional[e.key] = v),
                  ),

                const SizedBox(height: Space.lg),
                Container(
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
                          Icon(Icons.bedtime_outlined, size: 18, color: p.info),
                          const SizedBox(width: Space.xs),
                          Text(
                            'Silence de 21 h à 7 h',
                            style: AppText.bodyL.copyWith(color: p.inkStrong),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xxs),
                      Text(
                        'Deux notifications de contenu par jour au maximum. '
                        'Une alerte qui n\'apporte rien de neuf ne sonne pas.',
                        style: AppText.bodyM.copyWith(color: p.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: BoxConstraints(minHeight: Touch.target(p.isHighContrast)),
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.bodyL.copyWith(color: p.inkStrong),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// WhatsApp d'abord : c'est le canal lu ET archivé au Bénin. Le SMS reste
/// disponible parce qu'il passe sans data — ce qui arrive tous les jours.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  static const _channels = {
    'whatsapp': 'WhatsApp',
    'push': 'Notification',
    'sms': 'SMS',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.bodyL.copyWith(color: p.inkStrong)),
          const SizedBox(height: Space.xxs),
          Wrap(
            spacing: Space.xs,
            children: [
              for (final c in _channels.entries)
                ChoiceChip(
                  label: Text(c.value),
                  selected: value == c.key,
                  onSelected: (_) => onChanged(c.key),
                  backgroundColor: p.surfaceRaised,
                  selectedColor: p.surfaceSunken,
                  side: BorderSide(
                    color: value == c.key ? p.action : p.lineHair,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
