import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../data/owner_repository.dart';
import '../bloc/owner_cubit.dart';

/// C6 — Encaissements.
///
/// Le dernier maillon du parcours propriétaire : publier → être vu → recevoir
/// une demande → encaisser. Sans cet écran, le bailleur ne sait pas si son
/// loyer est arrivé, et il retourne aux espèces.
///
/// LA COMMISSION EST AFFICHÉE EN CLAIR, ligne par ligne, juste sous le loyer
/// qu'elle prélève. La cacher dans un net global serait le meilleur moyen de
/// perdre la confiance d'un bailleur béninois — habitué à des intermédiaires
/// dont il ne comprend jamais les prélèvements.
///
/// LES CHIFFRES VIENNENT DE `rent_payments`, par la jointure du bail. Ils
/// étaient inventés : un relevé faux est pire qu'absent, parce qu'on compte
/// dessus.
class OwnerEarningsScreen extends StatelessWidget {
  const OwnerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EarningsCubit(getIt<OwnerRepository>())..load(),
      child: const _EarningsView(),
    );
  }
}

class _EarningsView extends StatelessWidget {
  const _EarningsView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Encaissements',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: BlocBuilder<EarningsCubit, EarningsState>(
              builder: (context, state) => switch (state) {
                EarningsLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                EarningsError(:final failure) => _Error(
                  message: failure.userMessage,
                  onRetry: context.read<EarningsCubit>().load,
                ),
                EarningsReady(:final earnings) =>
                  earnings.movements.isEmpty
                      ? const _Empty()
                      : RefreshIndicator(
                          onRefresh: context.read<EarningsCubit>().load,
                          child: _Body(earnings: earnings),
                        ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.earnings});

  final OwnerEarnings earnings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Text(
          MoneyFcfa.short(earnings.receivedThisMonth),
          style: AppText.displayL.copyWith(
            color: p.inkStrong,
            fontFeatures: Fonts.tabular,
          ),
        ),
        Text(
          'nets reçus ce mois-ci',
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          'Commission déduite. Le détail est ci-dessous, ligne par ligne.',
          style: AppText.caption.copyWith(color: p.inkMuted),
        ),

        const SizedBox(height: Space.lg),
        Text('MOUVEMENTS', style: AppText.label.copyWith(color: p.inkMuted)),
        const SizedBox(height: Space.xs),
        for (final m in earnings.movements) _MovementRow(movement: m),

        const SizedBox(height: Space.lg),
        OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, Touch.target(p.isHighContrast)),
          ),
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Exporter mes états'),
        ),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final OwnerMovement movement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = movement;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.label,
                  style: AppText.bodyL.copyWith(
                    // La commission est visible mais discrète : on ne la
                    // cache pas, on ne la met pas en avant non plus.
                    color: m.isFee ? p.inkMuted : p.inkStrong,
                  ),
                ),
                Text(
                  _date(m.paidAt),
                  style: AppText.caption.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
          Text(
            '${m.amountFcfa < 0 ? '−' : ''}'
            '${MoneyFcfa.short(m.amountFcfa.abs())}',
            style: AppText.bodyL.copyWith(
              color: m.isFee ? p.inkMuted : p.success,
              fontWeight: FontWeight.w600,
              fontFeatures: Fonts.tabular,
            ),
          ),
          if (!m.isFee) ...[
            const SizedBox(width: Space.xs),
            Icon(Icons.check_circle, size: 16, color: p.success),
          ],
        ],
      ),
    );
  }

  String _date(DateTime d) {
    const mois = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final l = d.toLocal();
    return '${l.day} ${mois[l.month - 1]}';
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucun loyer encaissé pour l\'instant.',
            style: AppText.titleM.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Les loyers apparaîtront ici dès qu\'un locataire paiera depuis '
            'l\'application. La quittance part au même moment, de son côté.',
            style: AppText.bodyL.copyWith(color: p.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppText.bodyL.copyWith(color: p.inkStrong)),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              minimumSize: Size(0, Touch.target(p.isHighContrast)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
