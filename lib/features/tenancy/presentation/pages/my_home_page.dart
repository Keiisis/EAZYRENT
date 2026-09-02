import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/presentation/pages/report_listing_page.dart';
import 'receipts_page.dart';

/// S15 — Mon logement.
///
/// « L'écran qui porte la rétention longue durée (12 à 36 mois), et celui que
/// la v1.0 du produit laissait sortir du parcours après la signature. »
/// (UI_SCREENS_SPEC.md §S15)
///
/// Un produit de recherche perd son utilisateur le jour où il trouve. Cet
/// écran est ce qui transforme une transaction en abonnement de fait : la
/// quittance arrive IMMÉDIATEMENT après le paiement, et devient la preuve que
/// le paiement en espèces ne fournit pas.
class MyHomeScreen extends StatelessWidget {
  const MyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Démonstration tant que le module tenancy n'a pas sa couche data.
    const rent = 45000;
    const quartier = 'Fidjrossè';
    const dueDay = '5 mars';

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Mon logement',
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
                  'Chambre-salon · $quartier',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),

                const SizedBox(height: Space.md),
                Container(
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: p.surfaceRaised,
                    border: Border.all(color: p.lineHair, width: p.borderWidth),
                    borderRadius: const BorderRadius.all(Radii.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loyer de mars',
                        style: AppText.bodyL.copyWith(color: p.inkMuted),
                      ),
                      Text(
                        MoneyFcfa.short(rent),
                        style: AppText.displayL.copyWith(
                          color: p.inkStrong,
                          fontFeatures: Fonts.tabular,
                        ),
                      ),
                      const SizedBox(height: Space.xxs),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 15, color: p.warn),
                          const SizedBox(width: Space.xxs),
                          Text(
                            'À payer avant le $dueDay',
                            style: AppText.label.copyWith(color: p.warn),
                          ),
                        ],
                      ),

                      const SizedBox(height: Space.md),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          minimumSize: Size(
                            0,
                            Touch.target(p.isHighContrast) + 8,
                          ),
                        ),
                        child: const Text('Payer avec MTN MoMo'),
                      ),
                      const SizedBox(height: Space.xs),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, Touch.target(p.isHighContrast)),
                        ),
                        child: const Text('Payer autrement'),
                      ),
                      const SizedBox(height: Space.xs),
                      // La promesse qui rend le paiement en espèces coûteux.
                      Center(
                        child: Text(
                          'Quittance immédiate après paiement.',
                          style: AppText.caption.copyWith(color: p.success),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Space.lg),
                _Row(
                  icon: Icons.receipt_long,
                  label: 'Mes quittances',
                  trailing: '3 disponibles',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReceiptsScreen(),
                    ),
                  ),
                ),
                _Row(
                  icon: Icons.fact_check_outlined,
                  label: 'État des lieux',
                  trailing: 'signé le 12/01',
                  onTap: () {},
                ),
                _Row(
                  icon: Icons.assignment_outlined,
                  label: 'Mon bail',
                  trailing: 'PDF',
                  onTap: () {},
                ),
                _Row(
                  icon: Icons.chat_outlined,
                  label: 'Mon bailleur',
                  trailing: 'Message',
                  onTap: () {},
                ),
                _Row(
                  icon: Icons.build_outlined,
                  label: 'Signaler un problème',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportListingScreen(
                        listingTitle: 'Chambre-salon · Fidjrossè',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'Bail sous le régime de la loi n° 2018-12. Le préavis est de '
                  'un mois pour un bail à usage d\'habitation.',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;
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
              child: Text(
                label,
                style: AppText.bodyL.copyWith(color: p.inkStrong),
              ),
            ),
            if (trailing != null) ...[
              Text(trailing!, style: AppText.bodyM.copyWith(color: p.inkMuted)),
              const SizedBox(width: Space.xxs),
            ],
            Icon(Icons.chevron_right, size: 20, color: p.inkFaint),
          ],
        ),
      ),
    );
  }
}
