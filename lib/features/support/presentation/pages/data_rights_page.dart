import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import 'legal_page.dart';

/// S23 — Mes données : export et suppression de compte.
///
/// Obligation légale (loi n° 2017-20, APDP), mais aussi décision produit :
/// une sortie facile est ce qui rend l'entrée sans risque. Une application
/// dont on ne sait pas sortir se télécharge moins.
///
/// Trois choses tenues ici :
///   · L'EXPORT EST AU-DESSUS DE LA SUPPRESSION. Beaucoup de gens qui
///     cliquent « supprimer » veulent en réalité récupérer leurs quittances.
///   · CE QUI SURVIT À LA SUPPRESSION EST ÉCRIT AVANT de confirmer, pas dans
///     un e-mail après coup.
///   · LA SUPPRESSION N'EST PAS EN ROUGE VIF DÈS L'OUVERTURE. La couleur de
///     danger apparaît sur la confirmation, là où elle informe, pas à
///     l'arrivée, où elle ne fait qu'effrayer.
class DataRightsScreen extends StatelessWidget {
  const DataRightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Mes données',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(Space.md),
              children: [
                Text(
                  'Récupérer mes données',
                  style: AppText.titleM.copyWith(color: p.inkStrong),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Tes recherches, tes biens gardés, tes messages, tes '
                  'paiements et tes quittances, dans un fichier lisible. '
                  'Envoyé par e-mail sous 24 h.',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.sm),
                FilledButton.icon(
                  onPressed: () => _confirmExport(context),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                  ),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Demander mon export'),
                ),

                const SizedBox(height: Space.xl),
                Divider(color: p.lineHair),
                const SizedBox(height: Space.md),

                Text(
                  'Fermer mon compte',
                  style: AppText.titleM.copyWith(color: p.inkStrong),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Ce qui disparaît sous 30 jours : ton profil, tes '
                  'recherches, tes biens gardés, tes messages, tes alertes, '
                  'et les biens que tu as publiés.',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.sm),
                Container(
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: const BorderRadius.all(Radii.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ce qui reste malgré tout',
                        style: AppText.bodyL.copyWith(
                          color: p.inkStrong,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Space.xxs),
                      Text(
                        '· Les preuves de paiement, 10 ans — obligation '
                        'comptable.\n'
                        '· Un bail en cours et ses quittances, jusqu\'à son '
                        'terme.\n'
                        '· Les crédits de visite non utilisés sont perdus, '
                        'sans remboursement.',
                        style: AppText.bodyM.copyWith(color: p.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.sm),
                OutlinedButton(
                  onPressed: () => _confirmDeletion(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast)),
                    foregroundColor: p.danger,
                    side: BorderSide(color: p.lineStrong),
                  ),
                  child: const Text('Fermer mon compte'),
                ),

                const SizedBox(height: Space.lg),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalScreen(doc: LegalDoc.privacy),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast)),
                  ),
                  child: const Text('Lire la politique de données'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmExport(BuildContext context) {
    final p = context.palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: p.surfaceOverlay,
        content: Text(
          'Export demandé. Il arrive par e-mail sous 24 h.',
          style: AppText.bodyL.copyWith(color: p.inkStrong),
        ),
      ),
    );
  }

  /// La confirmation demande d'écrire un mot. Une case à cocher se coche par
  /// réflexe ; écrire « SUPPRIMER » demande une seconde d'attention, ce qui
  /// est exactement la durée qui manque à un geste regretté.
  Future<void> _confirmDeletion(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _DeletionDialog(),
    );
  }
}

class _DeletionDialog extends StatefulWidget {
  const _DeletionDialog();

  @override
  State<_DeletionDialog> createState() => _DeletionDialogState();
}

class _DeletionDialogState extends State<_DeletionDialog> {
  final _controller = TextEditingController();
  static const _word = 'SUPPRIMER';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ok = _controller.text.trim().toUpperCase() == _word;

    return AlertDialog(
      backgroundColor: p.surfaceOverlay,
      title: Text(
        'Fermer définitivement ?',
        style: AppText.titleM.copyWith(color: p.inkStrong),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Écris $_word pour confirmer. Cette action ne s\'annule pas.',
            style: AppText.bodyL.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: _word),
            style: AppText.bodyL.copyWith(color: p.inkStrong),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: ok
              ? () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: p.surfaceOverlay,
                      content: Text(
                        'Compte fermé. Effacement sous 30 jours.',
                        style: AppText.bodyL.copyWith(color: p.inkStrong),
                      ),
                    ),
                  );
                }
              : null,
          style: FilledButton.styleFrom(backgroundColor: p.danger),
          child: const Text('Fermer mon compte'),
        ),
      ],
    );
  }
}
