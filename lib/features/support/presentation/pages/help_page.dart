import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// S22 — Aide, litige, signalement d'annonce.
///
/// Promis par le PRD §3, jamais dessiné.
///
/// Ordre imposé : LE LITIGE D'ABORD, la FAQ ensuite. Quelqu'un qui ouvre
/// « Aide » après avoir payé 1 000 F pour rien ne cherche pas à lire un
/// article — il cherche quelqu'un. Enterrer le contact sous vingt questions
/// fréquentes est la façon la plus efficace de transformer un incident en
/// avis à une étoile.
///
/// Le canal WhatsApp est en premier parce que c'est celui que les gens
/// utilisent déjà, et qu'il laisse une trace des deux côtés.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Aide et litige',
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
                        'Un problème maintenant ?',
                        style: AppText.titleM.copyWith(color: p.inkStrong),
                      ),
                      const SizedBox(height: Space.xxs),
                      Text(
                        'Paiement débité sans rien reçu, bien qui ne '
                        'correspond pas, personne qui demande de l\'argent '
                        'hors de l\'application : écris-nous, on répond sous '
                        '2 h entre 8 h et 20 h.',
                        style: AppText.bodyL.copyWith(color: p.inkMuted),
                      ),
                      const SizedBox(height: Space.md),
                      FilledButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          minimumSize: Size(
                            0,
                            Touch.target(p.isHighContrast) + 8,
                          ),
                        ),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Écrire sur WhatsApp'),
                      ),
                      const SizedBox(height: Space.xs),
                      OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, Touch.target(p.isHighContrast)),
                        ),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Appeler +229 01 40 00 00 00'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'SIGNALER',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                const _Item(
                  icon: Icons.report_gmailerrorred_outlined,
                  title: 'Une annonce fausse ou trompeuse',
                  body:
                      'Photos qui ne sont pas du bien, prix différent sur '
                      'place, bien qui n\'existe pas.',
                ),
                const _Item(
                  icon: Icons.money_off,
                  title: 'On me demande de l\'argent en dehors de l\'app',
                  body:
                      'Aucun agent EAZYRENT ne demande jamais de frais de '
                      'dossier ni de caution par Mobile Money direct.',
                ),
                const _Item(
                  icon: Icons.person_off_outlined,
                  title: 'Un comportement déplacé',
                  body: 'Menaces, insultes, discrimination.',
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'QUESTIONS FRÉQUENTES',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                const _Faq(
                  q: 'J\'ai payé et la visite ne s\'ouvre pas',
                  a:
                      'Le crédit n\'est débité qu\'à l\'ouverture de la visite. '
                      'Si le paiement est passé sans rien ouvrir, il est '
                      'remboursé sous 48 h. Donne la référence qui figure '
                      'dans l\'historique de paiements.',
                ),
                const _Faq(
                  q: 'Le bien était déjà loué en arrivant',
                  a:
                      'Signale-le depuis la fiche du bien : le bien est retiré '
                      'des résultats et ta visite t\'est rendue.',
                ),
                const _Faq(
                  q: 'Que veut dire « Visite Vérifiée » ?',
                  a:
                      'Un agent EAZYRENT s\'est rendu sur place, a filmé les '
                      'pièces en 360° et a vérifié que le bien était libre à '
                      'cette date. La date de vérification est écrite sur '
                      'chaque annonce.',
                ),
                const _Faq(
                  q: 'Pourquoi le coût d\'entrée est-il si visible ?',
                  a:
                      'Parce que c\'est lui qui décide. Un loyer de 35 000 F '
                      'avec 6 mois d\'avance demande 245 000 F le jour de '
                      'l\'entrée : c\'est cette somme-là qu\'il faut pouvoir '
                      'sortir.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: () {},
      child: Container(
        constraints: BoxConstraints(minHeight: Touch.target(p.isHighContrast)),
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: p.inkBase),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.bodyL.copyWith(color: p.inkStrong),
                  ),
                  Text(body, style: AppText.bodyM.copyWith(color: p.inkMuted)),
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

class _Faq extends StatelessWidget {
  const _Faq({required this.q, required this.a});

  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: Space.sm),
        title: Text(q, style: AppText.bodyL.copyWith(color: p.inkStrong)),
        iconColor: p.inkMuted,
        collapsedIconColor: p.inkMuted,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(a, style: AppText.bodyM.copyWith(color: p.inkMuted)),
          ),
        ],
      ),
    );
  }
}
