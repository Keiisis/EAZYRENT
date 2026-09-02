import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/theme_controller.dart';

/// A05 — Affichage et connexion.
///
/// Deux réglages qui n'existent que parce que le produit est utilisé DEHORS,
/// sur un forfait compté :
///
///   · PLEIN SOLEIL — contraste maximal, ombres supprimées, cibles tactiles
///     portées de 48 à 56 dp. Ce n'est pas un thème sombre inversé, c'est un
///     mode de lecture pour un écran de téléphone à midi sur la voie.
///   · MODE LÉGER — les tours 360 passent de ~6 Mo à ~1,2 Mo par pièce. Sur
///     un forfait à la journée, c'est la différence entre visiter cinq biens
///     et en visiter un.
///
/// CHAQUE RÉGLAGE PORTE SON COÛT EN MÉGAOCTETS. « Qualité standard » ne veut
/// rien dire ; « ~1,2 Mo par pièce filmée » se compare à ce qu'il reste sur
/// le forfait.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeController get _theme => getIt<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: _theme,
      builder: (context, _) => Scaffold(
        backgroundColor: p.surfaceBase,
        appBar: AppBar(
          backgroundColor: p.surfaceBase,
          title: Text(
            'Affichage et connexion',
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
                    'Adapté à la rue et aux petits forfaits.',
                    style: AppText.bodyL.copyWith(color: p.inkMuted),
                  ),

                  const SizedBox(height: Space.lg),
                  Text(
                    'APPARENCE',
                    style: AppText.label.copyWith(color: p.inkMuted),
                  ),
                  const SizedBox(height: Space.xs),

                  // QUATRE CHOIX EXCLUSIFS, pas deux interrupteurs.
                  //
                  // Le mode sombre existait dans la palette depuis le début et
                  // n'était atteignable par personne : `AppTheme.dark()` était
                  // construit, jamais choisi. Un interrupteur « Plein Soleil »
                  // seul laissait donc un tiers du travail invisible.
                  _ThemeOption(
                    icon: Icons.brightness_auto,
                    title: 'Comme le téléphone',
                    subtitle: 'Suit le réglage Android, clair ou sombre.',
                    value: AppThemeMode.system,
                    current: _theme.mode,
                    onPick: (m) => _theme.mode = m,
                  ),
                  _ThemeOption(
                    icon: Icons.light_mode_outlined,
                    title: 'Clair',
                    subtitle: 'Le mode par défaut, en intérieur.',
                    value: AppThemeMode.light,
                    current: _theme.mode,
                    onPick: (m) => _theme.mode = m,
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode_outlined,
                    title: 'Sombre',
                    subtitle:
                        'Moins de lumière le soir, et moins de batterie sur '
                        'les écrans AMOLED.',
                    value: AppThemeMode.dark,
                    current: _theme.mode,
                    onPick: (m) => _theme.mode = m,
                  ),
                  _ThemeOption(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Plein Soleil',
                    subtitle:
                        'Bordures épaissies, ombres supprimées, boutons à '
                        '56 dp. Pour lire à midi sur la voie.',
                    value: AppThemeMode.sunlight,
                    current: _theme.mode,
                    onPick: (m) => _theme.mode = m,
                    note: _theme.autoSunlight
                        ? "S'active tout seul au-delà de 8 000 lux — la "
                              "luminosité d'une rue à midi, pas celle d'un "
                              'bureau.'
                        : null,
                  ),

                  const SizedBox(height: Space.lg),
                  Text(
                    'DONNÉES',
                    style: AppText.label.copyWith(color: p.inkMuted),
                  ),
                  const SizedBox(height: Space.xs),
                  _Block(
                    icon: Icons.data_saver_on,
                    title: 'Mode Léger',
                    body:
                        'Compresse les visites 360 : moins de 1,5 Mo par '
                        'visite au lieu de 8 Mo.',
                    value: _theme.liteData,
                    onChanged: (v) => _theme.liteData = v,
                  ),

                  _Block(
                    icon: Icons.brightness_auto,
                    title: 'Bascule automatique',
                    body:
                        'Laisser le capteur de luminosité allumer le Plein '
                        'Soleil. Il ne l\'éteint jamais tout seul : une carte '
                        'qui repâlit pendant qu\'on la lit dehors, parce '
                        'qu\'un nuage est passé, est pire que tout.',
                    value: _theme.autoSunlight,
                    onChanged: (v) => _theme.autoSunlight = v,
                  ),

                  const SizedBox(height: Space.lg),
                  Text(
                    'QUALITÉ DES VISITES 360',
                    style: AppText.label.copyWith(color: p.inkMuted),
                  ),
                  const SizedBox(height: Space.xs),
                  _QualityOption(
                    title: 'Standard',
                    subtitle: 'Optimisé 3G/4G · ~1,2 Mo par pièce filmée',
                    recommended: true,
                    selected: _theme.tourQuality == TourQuality.standard,
                    onTap: () => _theme.tourQuality = TourQuality.standard,
                  ),
                  _QualityOption(
                    title: 'Ultra HD',
                    subtitle: 'Wi-Fi uniquement · ~6 Mo par pièce filmée',
                    recommended: false,
                    selected: _theme.tourQuality == TourQuality.ultra,
                    onTap: () => _theme.tourQuality = TourQuality.ultra,
                  ),

                  const SizedBox(height: Space.lg),
                  Container(
                    padding: const EdgeInsets.all(Space.sm),
                    decoration: BoxDecoration(
                      color: p.surfaceSunken,
                      borderRadius: const BorderRadius.all(Radii.card),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_download_outlined,
                          size: 20,
                          color: p.inkBase,
                        ),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Visites gardées hors-ligne',
                                style: AppText.bodyL.copyWith(
                                  color: p.inkStrong,
                                ),
                              ),
                              Text(
                                '4 visites prêtes sans connexion · 24 Mo',
                                style: AppText.bodyM.copyWith(
                                  color: p.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            minimumSize: Size(
                              0,
                              Touch.target(p.isHighContrast),
                            ),
                            foregroundColor: p.inkMuted,
                          ),
                          child: const Text('Vider'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    'Une visite payée reste lisible hors connexion. Vider ne '
                    'consomme aucun crédit : elle se retéléchargera.',
                    style: AppText.caption.copyWith(color: p.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: InkWell(
        // Toute la ligne bascule, pas seulement l'interrupteur : viser un
        // rectangle de 32 dp debout, une main occupée, échoue.
        onTap: () => onChanged(!value),
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            border: Border.all(color: value ? p.action : p.lineHair),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: value ? p.action : p.inkBase),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: AppText.bodyL.copyWith(
                        color: p.inkStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(value: value, onChanged: onChanged),
                ],
              ),
              const SizedBox(height: Space.xxs),
              Text(body, style: AppText.bodyM.copyWith(color: p.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.title,
    required this.subtitle,
    required this.recommended,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          constraints: BoxConstraints(
            minHeight: Touch.target(p.isHighContrast),
          ),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            border: Border.all(
              color: selected ? p.action : p.lineHair,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? p.action : p.inkFaint,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppText.bodyL.copyWith(color: p.inkStrong),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: Space.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.surfaceSunken,
                              borderRadius: const BorderRadius.all(Radii.pill),
                            ),
                            child: Text(
                              'Recommandé',
                              style: AppText.caption.copyWith(color: p.success),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Le coût en mégaoctets EST l'information. « Standard »
                    // seul ne se compare à rien.
                    Text(
                      subtitle,
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un mode d'affichage, exclusif des autres.
///
/// Des interrupteurs indépendants laissaient exprimer « sombre ET Plein
/// Soleil », qui n'a aucun sens : ce sont deux façons opposées de traiter la
/// lumière. Un choix unique rend l'état impossible plutôt que de le corriger
/// après coup.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.current,
    required this.onPick,
    this.note,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppThemeMode value;
  final AppThemeMode current;
  final ValueChanged<AppThemeMode> onPick;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = value == current;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: InkWell(
        onTap: () => onPick(value),
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          constraints: BoxConstraints(
            minHeight: Touch.target(p.isHighContrast),
          ),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            border: Border.all(
              color: on ? p.action : p.lineHair,
              width: on ? p.borderWidth + 0.5 : p.borderWidth,
            ),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                on ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: on ? p.action : p.inkFaint,
              ),
              const SizedBox(width: Space.sm),
              Icon(icon, size: 20, color: on ? p.action : p.inkBase),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.bodyL.copyWith(
                        color: p.inkStrong,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                    if (note != null && on) ...[
                      const SizedBox(height: Space.xxs),
                      Text(
                        note!,
                        style: AppText.caption.copyWith(color: p.info),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
