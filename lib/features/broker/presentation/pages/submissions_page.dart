import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import 'submit_listing_page.dart';

/// D03 — Mes biens apportés.
///
/// L'écran qui manquait au démarcheur : il pouvait déposer un bien et voir son
/// solde, mais pas savoir ce que ses dépôts étaient devenus.
///
/// LE MOTIF D'UN REFUS EST ÉCRIT EN TOUTES LETTRES. « Refusé » seul fait
/// deux choses, et les deux sont mauvaises : le démarcheur redépose le même
/// bien — on retraite pour rien — ou il arrête d'apporter. « Ce bien était
/// déjà enregistré, apporté par un autre démarcheur le 2 août » lui apprend
/// quelque chose, et lui laisse envie de recommencer.
///
/// LES ONGLETS PORTENT LEUR NOMBRE. « En vérif » ne dit rien ; « En vérif (2) »
/// dit s'il faut regarder.
class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

enum _Status { verifying, published, rejected }

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  int _tab = 0;

  // Démonstration tant que le module broker n'a pas sa couche data.
  static const _all = [
    _Submission(
      title: 'Chambre-salon',
      quartier: 'Fidjrossè',
      rent: 35000,
      status: _Status.published,
      when: 'Publié le 8 août',
      earned: 1000,
      views: 23,
      requests: 2,
      hasTour: true,
    ),
    _Submission(
      title: 'Villa 2 chambres',
      quartier: 'Cadjèhoun',
      rent: 90000,
      status: _Status.verifying,
      when: 'Envoyé hier à 16h40 · résultat sous 24 h',
      detail: 'Agent en route',
    ),
    _Submission(
      title: 'Studio',
      quartier: 'Agla Hlazounto',
      rent: 25000,
      status: _Status.rejected,
      when: 'Refusé · doublon',
      detail:
          'Ce bien était déjà enregistré dans l\'application, apporté par un '
          'autre démarcheur le 2 août.',
    ),
  ];

  List<_Submission> get _shown => switch (_tab) {
    1 => _all.where((s) => s.status == _Status.verifying).toList(),
    2 => _all.where((s) => s.status == _Status.published).toList(),
    3 => _all.where((s) => s.status == _Status.rejected).toList(),
    _ => _all,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final counts = [
      _all.length,
      _all.where((s) => s.status == _Status.verifying).length,
      _all.where((s) => s.status == _Status.published).length,
      _all.where((s) => s.status == _Status.rejected).length,
    ];
    const labels = ['Tous', 'En vérif', 'Publiés', 'Refusés'];

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Mes apports',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: Space.xs,
                            top: Space.xs,
                            bottom: Space.xs,
                          ),
                          child: ChoiceChip(
                            label: Text('${labels[i]} (${counts[i]})'),
                            selected: _tab == i,
                            backgroundColor: p.surfaceRaised,
                            selectedColor: p.surfaceSunken,
                            side: BorderSide(
                              color: _tab == i ? p.action : p.lineHair,
                            ),
                            onSelected: (_) => setState(() => _tab = i),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: _shown.isEmpty
                      ? _Empty(tab: _tab)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            Space.md,
                            0,
                            Space.md,
                            96,
                          ),
                          children: [
                            for (final s in _shown) _SubmissionCard(item: s),
                          ],
                        ),
                ),
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
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
    );
  }
}

class _Submission {
  const _Submission({
    required this.title,
    required this.quartier,
    required this.rent,
    required this.status,
    required this.when,
    this.detail,
    this.earned,
    this.views,
    this.requests,
    this.hasTour = false,
  });

  final String title;
  final String quartier;
  final int rent;
  final _Status status;
  final String when;
  final String? detail;
  final int? earned;
  final int? views;
  final int? requests;
  final bool hasTour;
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.item});

  final _Submission item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (tone, icon) = switch (item.status) {
      _Status.published => (p.success, Icons.check_circle),
      _Status.verifying => (p.warn, Icons.schedule),
      _Status.rejected => (p.danger, Icons.cancel_outlined),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
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
              Icon(icon, size: 16, color: tone),
              const SizedBox(width: Space.xxs),
              Expanded(
                child: Text(
                  item.when,
                  style: AppText.label.copyWith(color: tone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Le gain est en vert, à droite, comme un crédit sur un relevé.
              if (item.earned != null)
                Text(
                  '+${MoneyFcfa.short(item.earned!)}',
                  style: AppText.bodyL.copyWith(
                    color: p.success,
                    fontWeight: FontWeight.w700,
                    fontFeatures: Fonts.tabular,
                  ),
                ),
            ],
          ),

          const SizedBox(height: Space.xxs),
          Text(
            '${item.title} · ${item.quartier}',
            style: AppText.bodyL.copyWith(
              color: p.inkStrong,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Loyer : ${MoneyFcfa.short(item.rent)}/mois',
            style: AppText.bodyM.copyWith(
              color: p.inkMuted,
              fontFeatures: Fonts.tabular,
            ),
          ),

          if (item.views != null) ...[
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Icon(Icons.visibility_outlined, size: 15, color: p.inkMuted),
                const SizedBox(width: Space.xxs),
                Text(
                  '${item.views} vues · ${item.requests} demandes',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
                if (item.hasTour) ...[
                  const SizedBox(width: Space.sm),
                  Icon(Icons.threesixty, size: 15, color: p.info),
                  const SizedBox(width: Space.xxs),
                  Text(
                    'Tournage fait',
                    style: AppText.label.copyWith(color: p.info),
                  ),
                ],
              ],
            ),
          ],

          // LE MOTIF, en clair. C'est la seule chose qui distingue un refus
          // dont on apprend quelque chose d'un refus qui fait partir.
          if (item.detail != null) ...[
            const SizedBox(height: Space.xs),
            Container(
              padding: const EdgeInsets.all(Space.xs),
              decoration: BoxDecoration(
                color: p.surfaceSunken,
                borderRadius: const BorderRadius.all(Radii.input),
              ),
              child: Text(
                item.detail!,
                style: AppText.bodyM.copyWith(color: p.inkBase),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.tab});

  final int tab;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = switch (tab) {
      1 => 'Aucun bien en vérification. Les agents passent sous 24 h.',
      2 => 'Aucun bien publié pour l\'instant.',
      3 => 'Aucun refus. C\'est bon signe.',
      _ => 'Tu n\'as encore apporté aucun bien.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),
      ),
    );
  }
}
