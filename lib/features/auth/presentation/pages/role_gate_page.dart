import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/account.dart';

/// A1 — L'aiguillage d'entrée. C'est ici que les trois profils se séparent.
///
/// TROIS choix, pas deux. Et une asymétrie assumée :
///
/// « Je cherche un logement » n'exige RIEN — pas de compte, pas de numéro.
/// Un chercheur qu'on force à s'inscrire avant de lui avoir rien montré est
/// un chercheur perdu (CONSTITUTION P2).
///
/// Les deux autres mènent à la création de compte, parce que leur première
/// action EST de donner quelque chose au système : publier un bien, apporter
/// une affaire. S'identifier n'y est pas ressenti comme un péage.
class RoleGateScreen extends StatelessWidget {
  const RoleGateScreen({
    required this.onBrowseAnonymously,
    required this.onPickRole,
    required this.onSignIn,
    super.key,
  });

  final VoidCallback onBrowseAnonymously;
  final void Function(UserRole) onPickRole;
  final VoidCallback onSignIn;

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
                  const Spacer(),

                  Text.rich(
                    TextSpan(
                      text: 'EAZY',
                      style: AppText.titleL.copyWith(color: p.inkStrong),
                      children: [
                        TextSpan(
                          text: 'RENT',
                          style: TextStyle(color: p.action),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.xl),

                  // La promesse nomme l'économie réalisée, pas la technologie.
                  Text(
                    'Arrête de payer le zem pour rien.',
                    style: AppText.displayM.copyWith(color: p.inkStrong),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Vois le logement en entier avant de te déplacer.',
                    style: AppText.bodyL.copyWith(color: p.inkBase),
                  ),

                  const SizedBox(height: Space.xxl),

                  _Choice(
                    icon: Icons.search,
                    label: UserRole.tenant.entryLabel,
                    hint: 'Sans compte',
                    emphasised: true,
                    onTap: onBrowseAnonymously,
                  ),
                  _Choice(
                    icon: Icons.home_work_outlined,
                    label: UserRole.owner.entryLabel,
                    onTap: () => onPickRole(UserRole.owner),
                  ),
                  _Choice(
                    icon: Icons.handshake_outlined,
                    label: UserRole.broker.entryLabel,
                    hint: 'Démarcheur',
                    onTap: () => onPickRole(UserRole.broker),
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: onSignIn,
                    child: const Text("J'ai déjà un compte"),
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

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
    this.emphasised = false,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final bool emphasised;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          constraints: BoxConstraints(
            minHeight: Touch.target(p.isHighContrast) + 16,
          ),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            border: Border.all(
              color: emphasised ? p.actionFill : p.lineHair,
              width: emphasised ? 2 : 1,
            ),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.action.withValues(alpha: 0.10),
                  borderRadius: const BorderRadius.all(Radii.input),
                ),
                child: Icon(icon, color: p.action, size: 22),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hint != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: const BorderRadius.all(Radii.pill),
                  ),
                  child: Text(
                    hint!,
                    style: AppText.caption.copyWith(color: p.inkMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
