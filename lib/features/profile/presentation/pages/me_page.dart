import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/progression/user_stage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/domain/entities/account.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../kyc/presentation/pages/kyc_page.dart';
import '../../../shortlist/presentation/bloc/shortlist_cubit.dart';

/// S12 — Moi.
///
/// « L'onglet Moi en P4 ne ressemble plus du tout à l'onglet Moi en P1. Ce
/// n'est pas un niveau gagné, c'est un outil qui apparaît quand on en a
/// besoin. » (UX_CORE_SPEC.md §10.2)
///
/// Rien n'est affiché en grisé. Une ligne absente ne se remarque pas ; une
/// ligne grisée qu'on ne peut pas toucher agace.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shortlist = context.watch<ShortlistCubit>();
    final auth = context.watch<AuthCubit>();
    final stage = shortlist.stage;
    final account = switch (auth.state) {
      Authenticated(:final account) => account,
      _ => null,
    };

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            children: [
              _Header(account: account, stage: stage),

              // ── Ce que l'utilisateur possède déjà ───────────────────────
              if (stage >= UserStage.p1Eveille) ...[
                _SectionTitle('Mes visites'),
                _Row(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Mes passes et crédits',
                  trailing: _pill(
                    context,
                    '${shortlist.state.purchasedPasses} pass',
                  ),
                ),
                _Row(icon: Icons.history, label: 'Historique de paiements'),
              ],

              // ── Ce qui le fait revenir ─────────────────────────────────
              _SectionTitle('Mes alertes'),
              _Row(
                icon: Icons.notifications_none,
                label: 'Alertes et recherches',
                trailing: _pill(context, 'Aucune'),
              ),
              _Row(icon: Icons.tune, label: 'Réglages de notification'),

              // ── Contexte d'usage : jamais enterré ──────────────────────
              _SectionTitle('Affichage et données'),
              _Row(
                icon: Icons.wb_sunny_outlined,
                label: 'Mode Plein Soleil',
                subtitle: 'Contraste maximal pour lire dehors',
                trailing: Switch(value: false, onChanged: (_) {}),
              ),
              _Row(
                icon: Icons.data_saver_on,
                label: 'Mode Léger',
                subtitle: 'Moins de données. Activé hors Wi-Fi.',
                trailing: Switch(value: true, onChanged: (_) {}),
              ),

              // ── Locataire installé : l'onglet change de métier ─────────
              if (stage >= UserStage.p4Locataire) ...[
                _SectionTitle('Mon logement'),
                _Row(icon: Icons.payments_outlined, label: 'Payer mon loyer'),
                _Row(icon: Icons.receipt_long, label: 'Mes quittances'),
                _Row(icon: Icons.assignment_outlined, label: 'Mon bail'),
              ],

              // ── Bailleur ───────────────────────────────────────────────
              if (stage >= UserStage.p5Bailleur) ...[
                _SectionTitle('Mes biens'),
                _Row(icon: Icons.home_work_outlined, label: 'Tableau de bord'),
                _Row(icon: Icons.add_home_outlined, label: 'Publier un bien'),
              ],

              // Le KYC n'existe que pour ceux qui recoivent de l'argent.
              // Le demander a un chercheur n'aurait aucun sens.
              if (account != null && account.role != UserRole.tenant) ...[
                _SectionTitle('Vérification'),
                _Row(
                  icon: Icons.badge_outlined,
                  label: 'Vérifier mon identité',
                  subtitle: account.role == UserRole.owner
                      ? 'Pièce, preuve sur le bien, compte de versement'
                      : 'Pièce et compte de versement',
                  trailing: _pill(context, 'À faire'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => KycScreen(role: account.role),
                    ),
                  ),
                ),
              ],

              _SectionTitle('Aide'),
              _Row(icon: Icons.help_outline, label: 'Aide et litige'),
              _Row(icon: Icons.description_outlined, label: 'Conditions'),
              _Row(icon: Icons.shield_outlined, label: 'Politique de données'),

              const SizedBox(height: Space.md),

              if (account != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  child: OutlinedButton(
                    onPressed: () => context.read<AuthCubit>().signOut(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast)),
                    ),
                    child: const Text('Me déconnecter'),
                  ),
                )
              else
                // L'anonyme n'est pas invité à s'inscrire « pour profiter de
                // toutes les fonctionnalités ». On lui dit ce qu'il gagne
                // concrètement, et ce qu'il perd sans compte.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  child: Container(
                    padding: const EdgeInsets.all(Space.md),
                    decoration: BoxDecoration(
                      color: p.surfaceSunken,
                      borderRadius: const BorderRadius.all(Radii.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu navigues sans compte',
                          style: AppText.bodyL.copyWith(
                            color: p.inkStrong,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Space.xxs),
                        Text(
                          'Ta liste disparaîtra si tu fermes l\'application. '
                          'Crée un compte pour la garder.',
                          style: AppText.bodyM.copyWith(color: p.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: Space.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: const BorderRadius.all(Radii.pill),
      ),
      child: Text(text, style: AppText.caption.copyWith(color: p.inkMuted)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.account, required this.stage});

  final Account? account;
  final UserStage stage;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.lg,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: p.surfaceSunken,
            child: Icon(Icons.person_outline, color: p.inkMuted),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account?.fullName?.isNotEmpty == true
                      ? account!.fullName!
                      : (account?.phone ?? 'Visiteur'),
                  style: AppText.titleM.copyWith(color: p.inkStrong),
                ),
                Text(
                  account == null ? 'Sans compte' : _roleLabel(account!.role),
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole r) => switch (r) {
    UserRole.tenant => 'Locataire',
    UserRole.broker => 'Démarcheur',
    UserRole.owner => 'Propriétaire',
  };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.lg,
        Space.md,
        Space.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppText.label.copyWith(color: p.inkMuted),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      // Les destinations sont branchées écran par écran, pas d'un bloc :
      // une ligne qui ne mène nulle part est pire qu'une ligne absente.
      onTap: onTap ?? () {},
      child: Container(
        constraints: BoxConstraints(minHeight: Touch.target(p.isHighContrast)),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: p.inkBase),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppText.bodyL.copyWith(color: p.inkStrong),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_right, size: 20, color: p.inkFaint),
          ],
        ),
      ),
    );
  }
}
