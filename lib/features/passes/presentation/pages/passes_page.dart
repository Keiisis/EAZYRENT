import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../data/passes_repository.dart';
import '../bloc/passes_cubit.dart';
import 'payment_history_page.dart';

/// S16 — Mes passes et crédits.
///
/// On vendait des crédits sans lieu pour les voir. Un crédit acheté qu'on ne
/// retrouve pas est un crédit perdu, et un remboursement demandé.
///
/// LE SOLDE VIENT DE LA BASE. Il affichait un chiffre de démonstration
/// pendant que le serveur en débitait un vrai : un compteur faux est pire
/// qu'absent, il fait croire à un vol.
///
/// Deux règles tenues ici :
///   · CE QUI RESTE EST AFFICHÉ AVANT CE QU'ON PEUT ACHETER. L'écran sert
///     d'abord à rassurer, ensuite à vendre. L'inverse serait une boutique
///     déguisée en compte.
///   · LA DATE D'EXPIRATION EST ÉCRITE, même lointaine. Un crédit qui expire
///     sans prévenir détruit plus de confiance que le montant qu'il
///     représente.
class PassesScreen extends StatelessWidget {
  const PassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PassesCubit(getIt<PassesRepository>())..load(),
      child: const _PassesView(),
    );
  }
}

class _PassesView extends StatelessWidget {
  const _PassesView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Mes passes et crédits',
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
                PassesReady(:final wallet) => RefreshIndicator(
                  onRefresh: context.read<PassesCubit>().load,
                  child: _Body(wallet: wallet),
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
  const _Body({required this.wallet});

  final CreditWallet wallet;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = wallet.remaining;

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: p.surfaceSunken,
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$n',
                style: AppText.displayL.copyWith(
                  color: n > 0 ? p.success : p.inkStrong,
                  fontFeatures: Fonts.tabular,
                ),
              ),
              Text(
                n > 1 ? 'visites 360 disponibles' : 'visite 360 disponible',
                style: AppText.bodyL.copyWith(color: p.inkMuted),
              ),
              if (n > 0) ...[
                const SizedBox(height: Space.xs),
                Text(
                  wallet.nextExpiry == null
                      ? 'Aucune expiration.'
                      : 'Le premier crédit expire le '
                            '${_date(wallet.nextExpiry!)}.',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
              ],
              if (wallet.unlockedListings > 0) ...[
                const SizedBox(height: Space.xs),
                Row(
                  children: [
                    Icon(Icons.lock_open, size: 15, color: p.success),
                    const SizedBox(width: Space.xxs),
                    Expanded(
                      child: Text(
                        // Les accès déjà ouverts sont PERMANENTS (§5.3) :
                        // le dire évite qu'on rachète un bien déjà débloqué.
                        '${wallet.unlockedListings} bien'
                        '${wallet.unlockedListings > 1 ? "s" : ""} déjà '
                        'débloqué${wallet.unlockedListings > 1 ? "s" : ""}, '
                        'pour toujours.',
                        style: AppText.label.copyWith(color: p.success),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: Space.lg),
        Text('RECHARGER', style: AppText.label.copyWith(color: p.inkMuted)),
        const SizedBox(height: Space.xs),

        // Les mêmes trois offres que le paywall, dans le même ordre, aux
        // mêmes prix que le catalogue serveur. Un prix qui change de place
        // entre deux écrans se lit comme un prix qui change.
        const _Offer(count: 1, price: 1000, note: 'Une visite'),
        const _Offer(
          count: 3,
          price: 2500,
          note: 'Trois visites · 833 F l\'unité',
          best: true,
        ),
        const _Offer(
          count: 7,
          price: 5000,
          note: 'Sept visites · 714 F l\'unité',
        ),

        const SizedBox(height: Space.lg),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PaymentHistoryScreen(),
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, Touch.target(p.isHighContrast)),
          ),
          icon: const Icon(Icons.history, size: 18),
          label: const Text('Historique de paiements'),
        ),

        const SizedBox(height: Space.md),
        Text(
          'Un crédit est débité au moment où la visite s\'ouvre, pas à '
          'l\'achat. Une visite interrompue par le réseau n\'est jamais '
          'recomptée.',
          style: AppText.bodyM.copyWith(color: p.inkMuted),
        ),
      ],
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
    return '${l.day} ${mois[l.month - 1]} ${l.year}';
  }
}

class _Offer extends StatelessWidget {
  const _Offer({
    required this.count,
    required this.price,
    required this.note,
    this.best = false,
  });

  final int count;
  final int price;
  final String note;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: InkWell(
        onTap: () {},
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          constraints: BoxConstraints(
            minHeight: Touch.target(p.isHighContrast) + 8,
          ),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            border: Border.all(
              color: best ? p.action : p.lineHair,
              width: best ? p.borderWidth + 0.5 : p.borderWidth,
            ),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$count visite${count > 1 ? 's' : ''} 360',
                          style: AppText.bodyL.copyWith(
                            color: p.inkStrong,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (best) ...[
                          const SizedBox(width: Space.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.action,
                              borderRadius: const BorderRadius.all(Radii.pill),
                            ),
                            child: Text(
                              'Le plus pris',
                              style: AppText.caption.copyWith(
                                color: p.actionOnFill,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      note,
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
              // Le montant est sur la ligne, pas caché derrière un tap.
              Text(
                MoneyFcfa.short(price),
                style: AppText.titleM.copyWith(
                  color: p.inkStrong,
                  fontFeatures: Fonts.tabular,
                ),
              ),
            ],
          ),
        ),
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
