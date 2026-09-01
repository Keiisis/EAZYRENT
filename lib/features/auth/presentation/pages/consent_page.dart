import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../bloc/auth_cubit.dart';

/// A6 — Consentement et données personnelles.
///
/// Obligation de la loi n°2017-20 (Code du numérique) et de l'APDP. Sans cet
/// écran, l'application n'est pas publiable en conformité.
///
/// TON : factuel, pas rassurant à l'excès. Sur ce marché, la méfiance vis-à-vis
/// de la revente des numéros est FONDÉE — les démarcheurs aspirent les fichiers.
/// La traiter frontalement est ce qui crée la confiance ; la contourner par des
/// formules apaisantes ne trompe personne.
///
/// Trois blocs courts, pas un pavé juridique. Le pavé existe, il est derrière
/// les deux liens.
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Space.xl),
                  Text(
                    'Ce qu\'on fait de tes données',
                    style: AppText.titleL.copyWith(color: p.inkStrong),
                  ),
                  const SizedBox(height: Space.lg),

                  const _Block(
                    icon: Icons.phone_android,
                    text:
                        'Ton numéro sert à te connecter et à te prévenir. '
                        'On ne le vend pas, et on ne le montre pas aux autres '
                        'utilisateurs.',
                  ),
                  const _Block(
                    icon: Icons.place_outlined,
                    text:
                        'Ta position sert à te montrer les biens proches. '
                        'Tu peux refuser : l\'application reste utilisable.',
                  ),
                  const _Block(
                    icon: Icons.folder_outlined,
                    text: 'Tes recherches restent sur ton téléphone.',
                  ),

                  const SizedBox(height: Space.md),
                  Wrap(
                    spacing: Space.md,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text("Conditions d'utilisation"),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Politique de données'),
                      ),
                    ],
                  ),

                  const Spacer(),

                  FilledButton(
                    onPressed: () => context.read<AuthCubit>().acceptTerms(),
                    style: FilledButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                    ),
                    child: const Text("J'ai compris"),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Tu peux supprimer ton compte à tout moment, '
                    'dans Moi → Réglages.',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: p.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: p.inkBase),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(text, style: AppText.bodyL.copyWith(color: p.inkBase)),
          ),
        ],
      ),
    );
  }
}
