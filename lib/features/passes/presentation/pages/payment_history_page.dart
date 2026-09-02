import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../data/passes_repository.dart';
import '../bloc/passes_cubit.dart';

/// S24 — Historique de paiements et reçus.
///
/// « On prend de l'argent sans en donner la trace. »
/// (SCREEN_ROLE_MATRIX.md, écran manquant n°24)
///
/// Sur un marché où le paiement mobile laisse un SMS opérateur mais rien du
/// côté du marchand, la trace côté marchand est le produit.
///
/// LES ÉCHECS SONT AFFICHÉS, PAS MASQUÉS. Ne montrer que les succès
/// reviendrait à nier ce qu'a vécu quelqu'un qui a vu un débit passer — et
/// c'est précisément dans ce cas-là qu'il vient chercher une référence.
class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // L'écran s'ouvre depuis « Mes passes » (cubit présent) ou depuis « Moi »
    // directement. On réutilise l'existant plutôt que d'en créer un second.
    final existing = context.read<PassesCubit?>();
    if (existing != null) return const _HistoryView();

    return BlocProvider(
      create: (_) => PassesCubit(getIt<PassesRepository>())..load(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Historique de paiements',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: BlocBuilder<PassesCubit, PassesState>(
              builder: (context, state) => switch (state) {
                PassesLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                PassesError(:final failure) => _Error(
                  message: failure.userMessage,
                  onRetry: context.read<PassesCubit>().load,
                ),
                PassesReady(:final history) =>
                  history.isEmpty
                      ? const _Empty()
                      : RefreshIndicator(
                          onRefresh: context.read<PassesCubit>().load,
                          child: ListView(
                            padding: const EdgeInsets.all(Space.md),
                            children: [
                              for (final r in history) _PaymentRow(record: r),
                              const SizedBox(height: Space.lg),
                              Text(
                                'Un paiement débité qui n\'a rien ouvert est '
                                'remboursé sous 48 h. Cite la référence au '
                                'support, elle suffit.',
                                style: AppText.bodyM.copyWith(
                                  color: p.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.record});

  final PaymentRecord record;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = record;

    final (statusLabel, statusTone, statusIcon) = switch (r.status) {
      'paid' => ('Payé', p.success, Icons.check_circle),
      'failed' => ('Échoué — non débité', p.danger, Icons.error_outline),
      'cancelled' => ('Annulé', p.inkMuted, Icons.cancel_outlined),
      _ => ('En attente', p.warn, Icons.schedule),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: Space.xs),
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
                  '${r.credits} visite${r.credits > 1 ? "s" : ""} 360',
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                MoneyFcfa.short(r.amountFcfa),
                style: AppText.bodyL.copyWith(
                  color: r.isPaid ? p.inkStrong : p.inkMuted,
                  fontWeight: FontWeight.w700,
                  fontFeatures: Fonts.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(
            '${r.providerLabel} · ${_when(r.createdAt)}',
            style: AppText.bodyM.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.xxs),
          Row(
            children: [
              Icon(statusIcon, size: 15, color: statusTone),
              const SizedBox(width: Space.xxs),
              Text(
                statusLabel,
                style: AppText.label.copyWith(color: statusTone),
              ),
              const Spacer(),
              // La référence est sélectionnable : elle sert à parler au
              // support, pas à décorer.
              SelectableText(
                r.reference,
                style: AppText.caption.copyWith(
                  color: p.inkMuted,
                  fontFeatures: Fonts.tabular,
                ),
              ),
            ],
          ),
          if (r.isPaid) ...[
            const SizedBox(height: Space.xs),
            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, Touch.target(p.isHighContrast)),
              ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Télécharger le reçu'),
            ),
          ],
        ],
      ),
    );
  }

  String _when(DateTime d) {
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
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '${l.day} ${mois[l.month - 1]}, ${hh}h$mm';
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
            'Aucun paiement pour l\'instant.',
            style: AppText.titleM.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Chaque achat de visite apparaîtra ici, avec sa référence.',
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
