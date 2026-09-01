import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import 'submit_listing_page.dart';

/// D1 — Accueil apporteur.
///
/// Le démarcheur ne vient pas chercher un logement : il vient voir combien il
/// a gagné. Le montant est donc la première chose à l'écran, en très gros, et
/// le barème reste visible en permanence — pas caché dans une FAQ.
///
/// C'est le rôle qui alimente le stock. Sans biens apportés, le feed est vide
/// et tout le reste du produit ne sert à rien.
class BrokerHomeScreen extends StatelessWidget {
  const BrokerHomeScreen({super.key});

  static const perListing = 1000;
  static const perRented = 3000;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Démonstration tant que le module broker n'a pas sa couche data.
    const submissions = [
      _Submission('Chambre-salon', 'Fidjrossè', _SubStatus.published, 1000),
      _Submission('Villa', 'Cadjèhoun', _SubStatus.pending, 0),
      _Submission('Studio', 'Agla', _SubStatus.rejected, 0),
    ];

    final earned = submissions.fold<int>(0, (s, x) => s + x.earnedFcfa);
    final published = submissions
        .where((s) => s.status == _SubStatus.published)
        .length;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                Space.md,
                96,
              ),
              children: [
                // Le gain d'abord. C'est la seule chose qui l'intéresse.
                Text(
                  MoneyFcfa.short(earned),
                  style: AppText.displayL.copyWith(color: p.inkStrong),
                ),
                Text(
                  'gagnés ce mois-ci',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  '$published bien${published > 1 ? 's' : ''} publié'
                  '${published > 1 ? 's' : ''} · '
                  '${submissions.length} apporté${submissions.length > 1 ? 's' : ''}',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),

                const SizedBox(height: Space.lg),
                _Scale(),

                const SizedBox(height: Space.lg),
                Text(
                  'MES APPORTS',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                for (final s in submissions) _SubmissionRow(submission: s),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SubmitListingScreen()),
        ),
        backgroundColor: p.actionFill,
        foregroundColor: p.actionOnFill,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Apporter un bien'),
      ),
    );
  }
}

enum _SubStatus { pending, published, rejected }

class _Submission {
  const _Submission(this.type, this.neighborhood, this.status, this.earnedFcfa);
  final String type;
  final String neighborhood;
  final _SubStatus status;
  final int earnedFcfa;
}

/// Le barème reste visible en permanence. Un apporteur qui doit chercher
/// combien il gagne est un apporteur qui arrête d'apporter.
class _Scale extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: const BorderRadius.all(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScaleLine(
            amount: BrokerHomeScreen.perListing,
            text: 'par bien vérifié et publié',
          ),
          const SizedBox(height: Space.xxs),
          _ScaleLine(
            amount: BrokerHomeScreen.perRented,
            text: 'de plus si le bien est loué via l\'app',
          ),
        ],
      ),
    );
  }
}

class _ScaleLine extends StatelessWidget {
  const _ScaleLine({required this.amount, required this.text});

  final int amount;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          MoneyFcfa.short(amount),
          style: AppText.bodyL.copyWith(
            color: p.success,
            fontWeight: FontWeight.w700,
            fontFeatures: Fonts.tabular,
          ),
        ),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Text(text, style: AppText.bodyM.copyWith(color: p.inkBase)),
        ),
      ],
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({required this.submission});

  final _Submission submission;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (icon, color, label) = switch (submission.status) {
      _SubStatus.published => (Icons.check_circle, p.success, 'Publié'),
      _SubStatus.pending => (Icons.hourglass_empty, p.warn, 'En vérification'),
      _SubStatus.rejected => (Icons.cancel_outlined, p.inkMuted, 'Refusé'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          border: Border.all(color: p.lineHair),
          borderRadius: const BorderRadius.all(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${submission.type} · ${submission.neighborhood}',
                    style: AppText.bodyL.copyWith(color: p.inkStrong),
                  ),
                ),
                if (submission.earnedFcfa > 0)
                  Text(
                    '+${MoneyFcfa.short(submission.earnedFcfa)}',
                    style: AppText.bodyL.copyWith(
                      color: p.success,
                      fontWeight: FontWeight.w700,
                      fontFeatures: Fonts.tabular,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.xxs),
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: Space.xxs),
                Text(label, style: AppText.label.copyWith(color: color)),
              ],
            ),

            // Un motif de refus FLOU fait perdre un apporteur. Or c'est lui
            // qui alimente le stock : on écrit la raison en clair, sans
            // jugement, et on dit ce qui reste possible.
            if (submission.status == _SubStatus.rejected) ...[
              const SizedBox(height: Space.xs),
              Text(
                'Ce bien était déjà dans l\'application, apporté par quelqu\'un '
                "d'autre le 2 mars. Rien n'est retenu contre toi.",
                style: AppText.bodyM.copyWith(color: p.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
