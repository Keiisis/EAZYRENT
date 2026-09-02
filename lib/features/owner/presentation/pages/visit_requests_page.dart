import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/owner_repository.dart';
import '../bloc/owner_cubit.dart';

/// C3 — Demandes de rendez-vous reçues.
///
/// L'écran où un bailleur gagne ou perd un locataire. Trois choses le
/// gouvernent :
///
///   · « A VISITÉ EN 360° » EST LE BADGE LE PLUS IMPORTANT DE L'ÉCRAN. Il
///     dit au bailleur que la personne a déjà vu son logement et vient quand
///     même : le déplacement n'est plus une découverte, c'est une
///     confirmation. C'est ce qui fait accepter.
///   · ACCEPTER ET REFUSER SONT DEUX BOUTONS, jamais un menu. Une réponse
///     qui demande deux gestes est une réponse qui n'arrive pas.
///   · UN REFUS N'EST PAS UNE FAUTE. Il ne porte pas de rouge d'alerte : un
///     bailleur qui a déjà loué doit pouvoir décliner sans se sentir jugé,
///     sinon il ne répond pas du tout — et le chercheur attend pour rien.
class VisitRequestsScreen extends StatelessWidget {
  const VisitRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // L'écran peut être ouvert depuis le tableau de bord (cubit déjà présent)
    // ou directement. On réutilise l'existant quand il y en a un, sinon on en
    // crée un : deux instances donneraient deux vérités sur les demandes.
    final existing = context.read<OwnerCubit?>();
    if (existing != null) return const _RequestsView();

    return BlocProvider(
      create: (_) => OwnerCubit(getIt<OwnerRepository>())..load(),
      child: const _RequestsView(),
    );
  }
}

class _RequestsView extends StatelessWidget {
  const _RequestsView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

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
            child: BlocBuilder<OwnerCubit, OwnerState>(
              builder: (context, state) => switch (state) {
                OwnerLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                OwnerError(:final failure) => _Error(
                  message: failure.userMessage,
                  onRetry: context.read<OwnerCubit>().load,
                ),
                OwnerEmpty() => const _Empty(),
                OwnerReady(:final requests) =>
                  requests.isEmpty
                      ? const _Empty()
                      : RefreshIndicator(
                          onRefresh: context.read<OwnerCubit>().load,
                          child: ListView(
                            padding: const EdgeInsets.all(Space.md),
                            children: [
                              for (final r in requests)
                                _RequestCard(request: r),
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final VisitRequest request;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = request;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
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
                  r.tenantName,
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(status: r.status),
            ],
          ),
          Text(
            r.listingLabel,
            style: AppText.bodyM.copyWith(color: p.inkMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: Space.xs),
          Row(
            children: [
              Icon(Icons.event, size: 15, color: p.inkBase),
              const SizedBox(width: Space.xxs),
              Text(
                _whenLabel(r.requestedAt),
                style: AppText.bodyL.copyWith(
                  color: p.inkStrong,
                  fontFeatures: Fonts.tabular,
                ),
              ),
            ],
          ),

          // LE badge. Il change la décision du bailleur.
          if (r.tenantHasSeenTour) ...[
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Icon(Icons.threesixty, size: 16, color: p.success),
                const SizedBox(width: Space.xxs),
                Expanded(
                  child: Text(
                    'A déjà visité ton bien en 360°.',
                    style: AppText.label.copyWith(color: p.success),
                  ),
                ),
              ],
            ),
          ],

          if (r.isPending) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                // Refuser d'abord, à gauche et en secondaire : la place
                // dominante revient à l'action qu'on souhaite encourager.
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.read<OwnerCubit>().answer(r.id, accept: false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast)),
                      // PAS de rouge : décliner n'est pas une faute.
                      foregroundColor: p.inkMuted,
                    ),
                    child: const Text('Pas disponible'),
                  ),
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () =>
                        context.read<OwnerCubit>().answer(r.id, accept: true),
                    style: FilledButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast)),
                    ),
                    child: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// « Samedi 14 mars à 11h ». Une date ISO ne se lit pas, et « dans 3 jours »
  /// oblige à ouvrir un calendrier pour savoir si on est libre.
  String _whenLabel(DateTime d) {
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
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
    return '${jours[l.weekday - 1]} ${l.day} ${mois[l.month - 1]} à ${hh}h';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, tone) = switch (status) {
      'confirmed' => ('Accepté', p.success),
      'cancelled' => ('Décliné', p.inkMuted),
      'completed' => ('Visité', p.info),
      _ => ('En attente', p.warn),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: const BorderRadius.all(Radii.pill),
      ),
      child: Text(label, style: AppText.caption.copyWith(color: tone)),
    );
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
            'Aucune demande pour l\'instant.',
            style: AppText.titleM.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Les demandes arrivent quand ton bien est vu. Une Visite Vérifiée '
            'attire des visiteurs qui savent déjà ce qu\'ils viennent voir.',
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
