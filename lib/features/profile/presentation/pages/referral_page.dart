import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';

/// B08 — Parrainage et partage.
///
/// La récompense est SYMÉTRIQUE : une visite offerte, une visite reçue. Un
/// parrainage où seul le parrain gagne se lit comme une exploitation de ses
/// proches, et personne ne l'envoie deux fois.
///
/// LE MESSAGE EST PRÉ-RÉDIGÉ ET VISIBLE AVANT L'ENVOI. Deux raisons, et la
/// seconde compte plus que la première :
///   · écrire soi-même un message de parrainage est un effort que presque
///     personne ne fournit ;
///   · surtout, le parrain doit VOIR ce qui partira en son nom. Un texte
///     envoyé à l'aveugle sur son propre WhatsApp est une trahison, même
///     quand le texte est bon.
///
/// La récompense n'arrive QU'À LA PREMIÈRE VISITE 360 du filleul, pas à
/// l'inscription. Récompenser l'inscription fabrique des comptes vides.
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  // Démonstration tant que le module croissance n'a pas sa couche data.
  static const _code = 'EAZY-229-AGAV';
  static const _link = 'eazyrent.bj/r/AGAV';
  static const _friends = 4;
  static const _earned = 3000;
  static const _toursWon = 3;

  static const _message =
      'Salut ! Si tu cherches une chambre ou un salon à Cotonou ou Calavi, '
      'ne paie plus 2 000 F de zem pour rien. Avec mon lien EAZYRENT tu '
      'visites les pièces en 360° pour 0 F : $_link';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Parrainer un proche',
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
                  'Offre une visite 360, reçois-en une.',
                  style: AppText.titleL.copyWith(color: p.inkStrong),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Dès qu\'un proche fait sa première visite 360 avec ton '
                  'lien, ton compte est rechargé d\'une visite. Sans limite '
                  'de temps.',
                  style: AppText.bodyL.copyWith(color: p.inkMuted),
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'TON LIEN ET TON CODE',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                Container(
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: p.surfaceRaised,
                    border: Border.all(color: p.lineHair),
                    borderRadius: const BorderRadius.all(Radii.card),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _code,
                          style: AppText.amount.copyWith(
                            color: p.inkStrong,
                            fontFeatures: Fonts.tabular,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copier le code',
                        onPressed: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: _code),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: p.surfaceOverlay,
                                content: Text(
                                  'Code copié.',
                                  style: AppText.bodyL.copyWith(
                                    color: p.inkStrong,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.copy, color: p.inkBase),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Space.sm),
                FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                  ),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Envoyer sur WhatsApp'),
                ),

                const SizedBox(height: Space.md),
                Text(
                  'CE QUI PARTIRA EN TON NOM',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                Container(
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: const BorderRadius.all(Radii.card),
                  ),
                  child: Text(
                    _message,
                    style: AppText.bodyM.copyWith(color: p.inkBase),
                  ),
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'TES RÉCOMPENSES',
                  style: AppText.label.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.xs),
                Row(
                  children: [
                    _Stat(value: '$_friends', label: 'amis inscrits'),
                    const SizedBox(width: Space.sm),
                    _Stat(
                      value: '+${MoneyFcfa.short(_earned)}',
                      label: 'visites gagnées ($_toursWon)',
                      tone: p.success,
                    ),
                  ],
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'Une visite est créditée à la PREMIÈRE visite 360 de ton '
                  'filleul, pas à son inscription. Récompenser une simple '
                  'inscription ne fabriquerait que des comptes vides.',
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.tone});

  final String value;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
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
            Text(
              value,
              style: AppText.displayM.copyWith(
                color: tone ?? p.inkStrong,
                fontFeatures: Fonts.tabular,
              ),
            ),
            Text(label, style: AppText.bodyM.copyWith(color: p.inkMuted)),
          ],
        ),
      ),
    );
  }
}
