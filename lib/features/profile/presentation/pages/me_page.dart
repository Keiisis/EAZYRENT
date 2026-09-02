import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/progression/user_stage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../alerts/presentation/pages/notification_center_page.dart';
import '../../../alerts/presentation/pages/notification_settings_page.dart';
import '../../../auth/domain/entities/account.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../broker/presentation/pages/commissions_page.dart';
import '../../../kyc/presentation/pages/kyc_page.dart';
import '../../../owner/presentation/pages/earnings_page.dart';
import '../../../passes/presentation/pages/passes_page.dart';
import '../../../passes/presentation/pages/payment_history_page.dart';
import '../../../shortlist/presentation/bloc/shortlist_cubit.dart';
import '../../../support/presentation/pages/data_rights_page.dart';
import '../../../support/presentation/pages/help_page.dart';
import '../../../support/presentation/pages/legal_page.dart';
import '../../../tenancy/presentation/pages/my_home_page.dart';
import '../../../tenancy/presentation/pages/receipts_page.dart';
import 'referral_page.dart';
import 'settings_page.dart';

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
    final theme = getIt<ThemeController>();
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
                // AUCUNE PASTILLE DE SOLDE ICI. `shortlist.state
                // .purchasedPasses` est un compteur de session, remis à zéro
                // à chaque lancement : afficher « 0 pass » à quelqu'un qui en
                // a trois, c'est lui faire croire qu'on les a pris. Le vrai
                // solde vit dans `PassesScreen`, qui interroge la base.
                _Row(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Mes passes et crédits',
                  onTap: () => _go(context, const PassesScreen()),
                ),
                _Row(
                  icon: Icons.history,
                  label: 'Historique de paiements',
                  onTap: () => _go(context, const PaymentHistoryScreen()),
                ),
              ],

              // ── Ce qui le fait revenir ─────────────────────────────────
              _SectionTitle('Mes alertes'),
              // Le centre de notifications est commun aux TROIS profils : une
              // bannière balayée sur un téléphone partagé est perdue partout
              // ailleurs.
              _Row(
                icon: Icons.inbox_outlined,
                label: 'Notifications',
                onTap: () => _go(context, const NotificationCenterScreen()),
              ),
              _Row(
                icon: Icons.notifications_none,
                label: 'Alertes et recherches',
                trailing: _pill(context, 'Aucune'),
                onTap: () => _go(context, const AlertsScreen()),
              ),
              _Row(
                icon: Icons.tune,
                label: 'Réglages de notification',
                onTap: () => _go(context, const NotificationSettingsScreen()),
              ),

              // ── Parrainage : la croissance ne se cache pas dans l'aide ─
              _Row(
                icon: Icons.card_giftcard_outlined,
                label: 'Parrainer un proche',
                subtitle: 'Offre une visite 360, reçois-en une',
                onTap: () => _go(context, const ReferralScreen()),
              ),

              // ── Contexte d'usage : jamais enterré ──────────────────────
              _SectionTitle('Affichage et données'),
              _Row(
                icon: Icons.tune_rounded,
                label: "Tous les réglages d'affichage",
                subtitle: 'Plein Soleil, Mode Léger, qualité des visites',
                onTap: () => _go(context, const SettingsScreen()),
              ),
              // Branchées sur le contrôleur RÉEL, plus sur un état local :
              // basculer ici change vraiment les couleurs et la taille des
              // cibles tactiles de toute l'application.
              _ToggleRow(
                icon: Icons.wb_sunny_outlined,
                label: 'Mode Plein Soleil',
                subtitle: 'Contraste maximal pour lire dehors',
                value: theme.isSunlight,
                onChanged: theme.toggleSunlight,
              ),
              _ToggleRow(
                icon: Icons.data_saver_on,
                label: 'Mode Léger',
                subtitle: 'Moins de données. Activé hors Wi-Fi.',
                value: theme.liteData,
                onChanged: (v) => theme.liteData = v,
              ),

              // ── Locataire installé : l'onglet change de métier ─────────
              if (stage >= UserStage.p4Locataire) ...[
                _SectionTitle('Mon logement'),
                _Row(
                  icon: Icons.payments_outlined,
                  label: 'Payer mon loyer',
                  onTap: () => _go(context, const MyHomeScreen()),
                ),
                _Row(
                  icon: Icons.receipt_long,
                  label: 'Mes quittances',
                  onTap: () => _go(context, const ReceiptsScreen()),
                ),
                _Row(
                  icon: Icons.assignment_outlined,
                  label: 'Mon bail',
                  onTap: () => _go(context, const MyHomeScreen()),
                ),
              ],

              // ── L'argent, selon le rôle ────────────────────────────────
              if (account?.role == UserRole.owner)
                _Row(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Mes encaissements',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OwnerEarningsScreen(),
                    ),
                  ),
                ),
              if (account?.role == UserRole.broker)
                _Row(
                  icon: Icons.payments_outlined,
                  label: 'Mes commissions',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CommissionsScreen(),
                    ),
                  ),
                ),

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
              _Row(
                icon: Icons.help_outline,
                label: 'Aide et litige',
                onTap: () => _go(context, const HelpScreen()),
              ),
              _Row(
                icon: Icons.description_outlined,
                label: 'Conditions',
                onTap: () =>
                    _go(context, const LegalScreen(doc: LegalDoc.terms)),
              ),
              _Row(
                icon: Icons.shield_outlined,
                label: 'Politique de données',
                onTap: () =>
                    _go(context, const LegalScreen(doc: LegalDoc.privacy)),
              ),
              // L'export et la suppression ne sont pas enterrés dans un
              // sous-menu : une sortie facile est ce qui rend l'entrée sans
              // risque.
              _Row(
                icon: Icons.folder_open_outlined,
                label: 'Mes données',
                subtitle: 'Export et suppression de compte',
                onTap: () => _go(context, const DataRightsScreen()),
              ),

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

  /// Un seul point de navigation : une ligne de « Moi » ouvre un écran, elle
  /// ne fait jamais rien.
  void _go(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

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

/// Une bascule d'affichage. L'état est local jusqu'à ce que E0.1 branche le
/// `ThemeController` — mais l'interrupteur BOUGE dès maintenant. Un
/// interrupteur qui ne réagit pas au doigt se lit comme une application
/// cassée, pas comme une fonction à venir.
///
/// Toute la ligne est tactile, pas seulement l'interrupteur : viser un
/// rectangle de 32 dp sur un écran de 5 pouces, une main occupée, échoue.
/// Une bascule d'affichage, pilotée depuis l'extérieur.
///
/// Elle avait un état LOCAL : l'interrupteur bougeait sous le doigt et rien
/// ne changeait à l'écran. C'était la définition même d'un réglage décoratif.
/// Elle reflète désormais `ThemeController`, qui est la seule vérité.
///
/// Toute la ligne est tactile, pas seulement l'interrupteur : viser un
/// rectangle de 32 dp sur un écran de 5 pouces, une main occupée, échoue.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _Row(
    icon: icon,
    label: label,
    subtitle: subtitle,
    trailing: Switch(value: value, onChanged: onChanged),
    onTap: () => onChanged(!value),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;

  /// Obligatoire. Une ligne sans destination est une promesse non tenue :
  /// le compilateur l'interdit désormais.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
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
