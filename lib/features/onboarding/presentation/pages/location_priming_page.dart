import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// A06b — La demande de position, au démarrage.
///
/// La spec d'origine interdisait toute permission avant le premier écran.
/// La demande au lancement a été explicitement demandée : les deux se
/// concilient exactement ici, et d'une seule façon.
///
/// ANDROID NE REDONNE JAMAIS UNE PERMISSION REFUSÉE. Un dialogue système
/// présenté sec, avant que l'utilisateur ait vu à quoi sert l'application,
/// se fait refuser — et la position est perdue POUR TOUJOURS, pas jusqu'à
/// demain. Cet écran est donc un filtre : il n'envoie au dialogue système que
/// les gens qui ont déjà dit oui ici, où un refus ne coûte rien et reste
/// réversible.
///
/// Trois choses écrites AVANT le dialogue, parce que ce sont les trois
/// questions que se pose quelqu'un à qui on demande sa position :
///   · à quoi ça sert — un temps de trajet réel, pas une distance à vol
///     d'oiseau ;
///   · ce qu'on en garde — le quartier, jamais le trajet ;
///   · ce qui se passe si on refuse — l'application marche quand même.
class LocationPrimingScreen extends StatefulWidget {
  const LocationPrimingScreen({required this.onDone, super.key});

  /// Appelé dans TOUS les cas — accepté, refusé, ignoré. Cet écran ne peut
  /// pas être un mur : personne ne doit rester coincé devant une permission.
  final VoidCallback onDone;

  @override
  State<LocationPrimingScreen> createState() => _LocationPrimingScreenState();
}

class _LocationPrimingScreenState extends State<LocationPrimingScreen> {
  bool _asking = false;

  Future<void> _ask() async {
    if (_asking) return;
    setState(() => _asking = true);
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
    } catch (_) {
      // Un échec de la couche système ne bloque personne.
    } finally {
      if (mounted) widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  Icon(Icons.near_me_outlined, size: 48, color: p.action),
                  const SizedBox(height: Space.lg),
                  Text(
                    'Combien de temps pour y aller ?',
                    style: AppText.displayM.copyWith(color: p.inkStrong),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Avec ta position, chaque bien affiche le temps réel du '
                    'trajet — en zem, à pied, à vélo ou en voiture — et on te '
                    'guide jusqu\'au portail.',
                    style: AppText.bodyL.copyWith(color: p.inkMuted),
                  ),

                  const SizedBox(height: Space.lg),
                  _Point(
                    icon: Icons.timer_outlined,
                    text:
                        'Le temps de trajet par les rues, pas à vol '
                        'd\'oiseau.',
                  ),
                  _Point(
                    icon: Icons.shield_outlined,
                    text: 'On garde le quartier, jamais tes déplacements.',
                  ),
                  _Point(
                    icon: Icons.toggle_off_outlined,
                    text:
                        'Tu peux refuser : l\'application marche quand '
                        'même, tu choisis tes quartiers à la main.',
                  ),

                  const Spacer(),

                  FilledButton(
                    onPressed: _asking ? null : _ask,
                    style: FilledButton.styleFrom(
                      minimumSize: Size(
                        double.infinity,
                        Touch.target(p.isHighContrast) + 8,
                      ),
                    ),
                    child: const Text('Autoriser ma position'),
                  ),
                  TextButton(
                    onPressed: _asking ? null : widget.onDone,
                    style: TextButton.styleFrom(
                      minimumSize: Size(
                        double.infinity,
                        Touch.target(p.isHighContrast),
                      ),
                      foregroundColor: p.inkMuted,
                    ),
                    // Pas « Non merci » : la porte reste ouverte. On pourra
                    // redemander plus tard, au moment où la position rend un
                    // service visible — « Autour de moi », « Y aller ».
                    child: const Text('Plus tard'),
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

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: p.inkMuted),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(text, style: AppText.bodyL.copyWith(color: p.inkBase)),
          ),
        ],
      ),
    );
  }
}
