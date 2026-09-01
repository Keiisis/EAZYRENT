import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// Le moment où l'on demande le compte au chercheur — et le seul.
///
/// UX_CORE_SPEC.md §4.1 : « Le compte est demandé AU MOMENT où l'utilisateur
/// veut garder quelque chose. Il devient alors un service rendu, pas un
/// péage. »
///
/// Trois règles tenues ici :
///   1. On ne le demande qu'APRÈS le premier bien gardé. Jamais avant.
///   2. « Plus tard » est un vrai choix, pas un lien gris minuscule. Le bien
///      reste gardé quoi qu'il arrive — refuser ne punit pas.
///   3. On dit ce qu'il GAGNE, pas ce dont il est privé. « Retrouver ta
///      liste » est concret ; « profiter de toutes les fonctionnalités » ne
///      veut rien dire.
///
/// Et on ne le represente pas à chaque bien gardé : une fois refusé, on
/// attend le prochain palier. Insister transforme un service en harcèlement.
class SavePromptSheet extends StatelessWidget {
  const SavePromptSheet({
    required this.savedCount,
    required this.onCreateAccount,
    super.key,
  });

  final int savedCount;
  final VoidCallback onCreateAccount;

  /// Affiche la feuille et renvoie `true` si l'utilisateur choisit de créer
  /// un compte. Ne s'affiche jamais deux fois pour le même palier.
  static Future<void> show(
    BuildContext context, {
    required int savedCount,
    required VoidCallback onCreateAccount,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavePromptSheet(
        savedCount: savedCount,
        onCreateAccount: onCreateAccount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: p.surfaceOverlay,
        borderRadius: const BorderRadius.vertical(top: Radii.sheet),
        boxShadow: Elevation.sheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.lineStrong,
                    borderRadius: const BorderRadius.all(Radii.pill),
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),

              // La micro-victoire d'abord. Il vient de faire quelque chose,
              // on le lui confirme avant de lui demander quoi que ce soit.
              Row(
                children: [
                  Icon(Icons.favorite, color: p.action, size: 22),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text(
                      savedCount == 1
                          ? 'Bien gardé.'
                          : '$savedCount biens gardés.',
                      style: AppText.titleL.copyWith(color: p.inkStrong),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),

              Text(
                'Ton numéro pour retrouver ta liste',
                style: AppText.bodyL.copyWith(
                  color: p.inkStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Space.xxs),
              Text(
                'Sans compte, ta liste disparaît quand tu fermes '
                "l'application. C'est la seule raison de t'inscrire.",
                style: AppText.bodyL.copyWith(color: p.inkMuted),
              ),

              const SizedBox(height: Space.lg),

              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCreateAccount();
                },
                style: FilledButton.styleFrom(
                  minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                ),
                child: const Text('Garder ma liste'),
              ),
              const SizedBox(height: Space.xs),

              // « Plus tard » est un vrai bouton, pas un lien qu'on cache.
              // Le bien reste gardé : refuser ne coûte rien tout de suite.
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  minimumSize: Size(0, Touch.target(p.isHighContrast)),
                ),
                child: const Text('Plus tard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
