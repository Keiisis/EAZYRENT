import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/presentation/pages/report_listing_page.dart';
import 'request_tour_page.dart';
import 'visit_requests_page.dart';

/// P02 — Mon annonce, et la preuve de la demande.
///
/// Le tableau de bord liste les biens ; sans cet écran, un bailleur ne
/// pouvait pas ouvrir le sien — donc ni corriger un prix, ni le retirer
/// quand il est loué. Un bien loué qui reste en ligne est ce qui détruit la
/// fraîcheur du parc, c'est-à-dire le produit.
///
/// LA PREUVE DE DEMANDE EST EN HAUT, avant les réglages. Un bailleur ouvre
/// son annonce pour savoir si elle marche, pas pour administrer un
/// formulaire. Le chiffre est réel — vues, demandes de RDV — et aucune
/// statistique comparative n'est affichée tant qu'elle n'est pas mesurée.
///
/// « MARQUER COMME LOUÉ » est l'action la mieux placée après la preuve. La
/// mettre en bas, en petit, reviendrait à préférer un catalogue gonflé à un
/// catalogue vrai.
class MyListingScreen extends StatefulWidget {
  const MyListingScreen({
    required this.title,
    required this.rentFcfa,
    required this.views,
    required this.requests,
    required this.hasTour,
    super.key,
  });

  final String title;
  final int rentFcfa;
  final int views;
  final int requests;
  final bool hasTour;

  @override
  State<MyListingScreen> createState() => _MyListingScreenState();
}

class _MyListingScreenState extends State<MyListingScreen> {
  bool _online = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Mon annonce',
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
                  widget.title,
                  style: AppText.titleL.copyWith(color: p.inkStrong),
                ),
                Text(
                  '${MoneyFcfa.short(widget.rentFcfa)} par mois',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),

                const SizedBox(height: Space.md),
                Row(
                  children: [
                    _Stat(
                      value: '${widget.views}',
                      label: 'vues cette semaine',
                      tone: p.inkStrong,
                    ),
                    const SizedBox(width: Space.sm),
                    _Stat(
                      value: '${widget.requests}',
                      label: widget.requests > 1
                          ? 'demandes de visite'
                          : 'demande de visite',
                      tone: widget.requests > 0 ? p.success : p.inkMuted,
                    ),
                  ],
                ),

                // L'offre de tournage n'arrive qu'ici, et qu'après la preuve.
                if (!widget.hasTour && widget.views > 0) ...[
                  const SizedBox(height: Space.md),
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
                          '${widget.views} personnes ont vu ton bien sans '
                          'pouvoir entrer.',
                          style: AppText.bodyL.copyWith(color: p.inkBase),
                        ),
                        const SizedBox(height: Space.xs),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RequestTourScreen(
                                listingTitle: widget.title,
                                views: widget.views,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(
                              0,
                              Touch.target(p.isHighContrast),
                            ),
                            foregroundColor: p.action,
                            side: BorderSide(color: p.action),
                          ),
                          child: const Text(
                            'Ajouter une Visite Vérifiée — 5 000 F',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: Space.lg),

                // L'action qui tient la fraîcheur du parc, juste après la
                // preuve — jamais reléguée en bas.
                _Action(
                  icon: _online
                      ? Icons.check_circle_outline
                      : Icons.visibility_off,
                  label: _online ? 'Marquer comme loué' : 'Remettre en ligne',
                  subtitle: _online
                      ? 'Le bien sort des résultats tout de suite.'
                      : 'Le bien redevient visible.',
                  onTap: () => setState(() => _online = !_online),
                ),
                _Action(
                  icon: Icons.event_note_outlined,
                  label: 'Voir les demandes de visite',
                  subtitle: '${widget.requests} en attente de réponse',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const VisitRequestsScreen(),
                    ),
                  ),
                ),
                _Action(
                  icon: Icons.edit_outlined,
                  label: 'Corriger le prix ou la description',
                  subtitle: 'Un prix affiché doit être le prix demandé.',
                  onTap: () {},
                ),
                _Action(
                  icon: Icons.photo_library_outlined,
                  label: 'Changer les photos',
                  onTap: () {},
                ),
                _Action(
                  icon: Icons.flag_outlined,
                  label: 'Signaler un problème sur ce bien',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ReportListingScreen(listingTitle: widget.title),
                    ),
                  ),
                ),

                if (!_online) ...[
                  const SizedBox(height: Space.md),
                  Container(
                    padding: const EdgeInsets.all(Space.sm),
                    decoration: BoxDecoration(
                      color: p.surfaceSunken,
                      borderRadius: const BorderRadius.all(Radii.card),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_off, size: 18, color: p.inkMuted),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Text(
                            'Ce bien n\'apparaît plus dans les recherches. '
                            'Personne ne se déplacera pour rien.',
                            style: AppText.bodyM.copyWith(color: p.inkBase),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.tone});

  final String value;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          border: Border.all(color: p.lineHair, width: p.borderWidth),
          borderRadius: const BorderRadius.all(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.amount.copyWith(color: tone)),
            Text(label, style: AppText.bodyM.copyWith(color: p.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: Touch.target(p.isHighContrast)),
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
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
            Icon(Icons.chevron_right, size: 20, color: p.inkFaint),
          ],
        ),
      ),
    );
  }
}
