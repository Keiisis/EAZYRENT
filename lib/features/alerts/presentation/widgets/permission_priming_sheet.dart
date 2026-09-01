import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// A06 — Amorce de permission.
///
/// Android ne redemande plus une permission refusée. Un dialogue système
/// présenté à froid, sans que l'utilisateur sache ce qu'il va recevoir, se
/// fait refuser — et le canal est perdu DÉFINITIVEMENT, pas jusqu'à demain.
///
/// D'où cette feuille, qui n'est pas une politesse mais un filtre : elle ne
/// laisse arriver au dialogue système que les gens qui ont déjà dit oui. Un
/// refus ici ne coûte rien, il est réversible ; un refus là-bas est
/// définitif.
///
/// Trois choses écrites en clair AVANT le dialogue :
///   · CE QU'ON ENVERRA — un exemple réel, pas une catégorie abstraite ;
///   · COMBIEN — le plafond de deux par jour, parce que c'est la crainte ;
///   · QUAND ON SE TAIRA — les heures de silence.
///
/// « Plus tard » n'est pas grisé et n'est pas un piège : la personne peut
/// créer son alerte sans notification et la recevoir en ouvrant l'app.
class PermissionPrimingSheet extends StatelessWidget {
  const PermissionPrimingSheet({
    required this.quartier,
    required this.onAccept,
    super.key,
  });

  final String quartier;
  final VoidCallback onAccept;

  /// Retourne `true` si l'utilisateur accepte que le dialogue SYSTÈME
  /// s'ouvre. `false` ou `null` : on ne le montre pas, et rien n'est perdu.
  static Future<bool?> show(
    BuildContext context, {
    required String quartier,
    required VoidCallback onAccept,
  }) => showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) =>
        PermissionPrimingSheet(quartier: quartier, onAccept: onAccept),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: const BorderRadius.vertical(top: Radii.sheet),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'On te prévient quand un bien sort',
                style: AppText.titleL.copyWith(color: p.inkStrong),
              ),
              const SizedBox(height: Space.xs),
              Text(
                'À $quartier, les biens partent en quelques jours. Celui qui '
                'appelle en premier visite en premier.',
                style: AppText.bodyL.copyWith(color: p.inkMuted),
              ),

              const SizedBox(height: Space.lg),
              // L'exemple réel. Une catégorie abstraite (« notifications
              // marketing ») ne se refuse pas pour les mêmes raisons qu'un
              // message qu'on peut lire.
              Container(
                padding: const EdgeInsets.all(Space.sm),
                decoration: BoxDecoration(
                  color: p.surfaceSunken,
                  borderRadius: const BorderRadius.all(Radii.card),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notifications_active, size: 20, color: p.action),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EAZYRENT · maintenant',
                            style: AppText.caption.copyWith(color: p.inkMuted),
                          ),
                          Text(
                            '2 chambres-salon à $quartier, entrée sous '
                            '90 000 F',
                            style: AppText.bodyL.copyWith(color: p.inkStrong),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Space.md),
              _Rule(
                icon: Icons.filter_2,
                text: 'Deux par jour au maximum. Jamais plus.',
              ),
              _Rule(
                icon: Icons.bedtime_outlined,
                text: 'Rien entre 21 h et 7 h.',
              ),
              _Rule(
                icon: Icons.block,
                text: 'Rien à dire, rien envoyé. Pas de rappel pour rien.',
              ),

              const SizedBox(height: Space.lg),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onAccept();
                },
                style: FilledButton.styleFrom(
                  minimumSize: Size(
                    double.infinity,
                    Touch.target(p.isHighContrast) + 8,
                  ),
                ),
                child: const Text('Me prévenir'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: Size(
                    double.infinity,
                    Touch.target(p.isHighContrast),
                  ),
                  foregroundColor: p.inkMuted,
                ),
                // Pas « Non merci » : la personne garde son alerte, elle la
                // consultera en ouvrant l'application. Rien n'est perdu, et
                // la porte reste ouverte pour redemander plus tard.
                child: const Text('Plus tard — je regarderai dans l\'app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Row(
        children: [
          Icon(icon, size: 17, color: p.inkMuted),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(text, style: AppText.bodyM.copyWith(color: p.inkBase)),
          ),
        ],
      ),
    );
  }
}
