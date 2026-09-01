import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// C3 — Demandes de rendez-vous reçues.
///
/// L'écran le plus important du propriétaire : c'est là que son bien devient
/// une transaction.
///
/// LA MENTION QUI CHANGE TOUT : « A déjà visité ton bien en 360 ». Elle est
/// placée AVANT les boutons, parce qu'elle répond à la seule question que se
/// pose un bailleur béninois — est-ce que cette personne est sérieuse, ou
/// est-ce encore un curieux qui va me faire perdre une matinée ?
///
/// C'est aussi l'argument de vente de tout le produit, rendu concret : la
/// Visite Vérifiée filtre les visiteurs, elle ne fait pas que les attirer.
class VisitRequestsScreen extends StatelessWidget {
  const VisitRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Démonstration tant que le module owner n'a pas sa couche data.
    const demo = [
      _Request(
        name: 'Koffi A.',
        listing: 'Chambre-salon Fidjrossè',
        slot: 'samedi 14 mars, 15 h',
        hasSeenTour: true,
        isVerified: true,
      ),
      _Request(
        name: 'Bernadette H.',
        listing: 'Chambre-salon Fidjrossè',
        slot: 'dimanche 15 mars, 10 h',
        hasSeenTour: false,
        isVerified: false,
      ),
    ];

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Demandes de visite',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(Space.md),
              children: [for (final r in demo) _RequestCard(request: r)],
            ),
          ),
        ),
      ),
    );
  }
}

class _Request {
  const _Request({
    required this.name,
    required this.listing,
    required this.slot,
    required this.hasSeenTour,
    required this.isVerified,
  });

  final String name;
  final String listing;
  final String slot;
  final bool hasSeenTour;
  final bool isVerified;
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final _Request request;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          border: Border.all(color: p.lineHair),
          borderRadius: const BorderRadius.all(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: p.surfaceSunken,
                  child: Icon(
                    Icons.person_outline,
                    color: p.inkMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    request.name,
                    style: AppText.bodyL.copyWith(
                      color: p.inkStrong,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (request.isVerified)
                  Row(
                    children: [
                      Icon(Icons.verified, size: 15, color: p.success),
                      const SizedBox(width: 3),
                      Text(
                        'Vérifié',
                        style: AppText.label.copyWith(color: p.success),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: Space.xs),
            Text(
              request.listing,
              style: AppText.bodyM.copyWith(color: p.inkMuted),
            ),
            Text(
              'Demande : ${request.slot}',
              style: AppText.bodyL.copyWith(color: p.inkBase),
            ),

            const SizedBox(height: Space.sm),

            // LA ligne décisive, avant les boutons.
            if (request.hasSeenTour)
              Container(
                padding: const EdgeInsets.all(Space.xs),
                decoration: BoxDecoration(
                  color: p.success.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.all(Radii.input),
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline, size: 16, color: p.success),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(
                        'A déjà visité ton bien en 360°',
                        style: AppText.bodyM.copyWith(
                          color: p.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // On ne cache pas l'inverse : un visiteur qui n'a rien vu est
              // une information utile au propriétaire, pas un défaut à masquer.
              Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: p.inkMuted),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text(
                      "N'a pas encore vu le bien en 360°",
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast)),
                    ),
                    child: const Text('Autre créneau'),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast)),
                    ),
                    child: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
