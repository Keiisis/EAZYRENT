import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../listing/domain/entities/listing.dart';
import '../widgets/paywall_sheet.dart';
import 'tour_viewer_page.dart';

/// S06a — La preview verrouillée.
///
/// « La preview gratuite est délibérément frustrante. Une pièce, 90° de
/// rotation, flou au-delà. Elle crée une boucle ouverte : on sait qu'il y a
/// quelque chose à voir et on ne peut pas le voir. C'est le moteur de
/// conversion. » (UX_CORE_SPEC.md §4.1)
///
/// C'est le SEUL verrou volontairement visible du produit. Partout ailleurs,
/// une fonction verrouillée n'existe simplement pas à l'écran.
class TourPreviewScreen extends StatefulWidget {
  const TourPreviewScreen({
    required this.listing,
    required this.roomsTotal,
    this.isFirstVisitFree = true,
    super.key,
  });

  final Listing listing;
  final int roomsTotal;

  /// La première Visite Vérifiée est offerte : on ne vend pas une expérience
  /// jamais vécue (E2.2, réciprocité).
  final bool isFirstVisitFree;

  @override
  State<TourPreviewScreen> createState() => _TourPreviewScreenState();
}

class _TourPreviewScreenState extends State<TourPreviewScreen> {
  /// Degrés explorés. Le flou commence au-delà de [_visibleDegrees].
  /// Paramétrable côté serveur à terme : c'est le réglage qui pilote
  /// directement le taux de conversion, il doit être instrumenté.
  static const double _visibleDegrees = 90;

  double _yaw = 0;
  bool _hintShown = true;

  @override
  Widget build(BuildContext context) {
    // Fond obsidienne : la visionneuse est le seul endroit où les couleurs
    // vives de la charte reprennent leurs droits.
    const dark = Color(0xFF0B0F19);

    return Scaffold(
      backgroundColor: dark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onHorizontalDragUpdate: (d) => setState(() {
              _yaw = (_yaw + d.delta.dx * 0.4).clamp(-180.0, 180.0);
              _hintShown = false;
            }),
            child: _BlurredPanorama(
              imageUrl: widget.listing.mainImageUrl,
              yaw: _yaw,
              visibleDegrees: _visibleDegrees,
            ),
          ),

          _Chrome(roomsTotal: widget.roomsTotal),

          if (_hintShown)
            const Align(alignment: Alignment(0, 0.15), child: _GyroHint()),

          Align(
            alignment: Alignment.bottomCenter,
            child: _Unlock(
              listing: widget.listing,
              roomsTotal: widget.roomsTotal,
              isFree: widget.isFirstVisitFree,
            ),
          ),
        ],
      ),
    );
  }
}

/// Le flou n'est PAS un cache posé par-dessus : c'est un dégradé appliqué au
/// rendu. On doit deviner qu'il y a quelque chose sans pouvoir le lire.
class _BlurredPanorama extends StatelessWidget {
  const _BlurredPanorama({
    required this.imageUrl,
    required this.yaw,
    required this.visibleDegrees,
  });

  final String? imageUrl;
  final double yaw;
  final double visibleDegrees;

  @override
  Widget build(BuildContext context) {
    // Fraction de l'écran restant nette, dérivée de l'angle autorisé.
    final clearFraction = (visibleDegrees / 360).clamp(0.15, 0.5);

    return ShaderMask(
      shaderCallback: (rect) => RadialGradient(
        center: Alignment(-yaw / 180, 0),
        radius: clearFraction * 2.2,
        colors: const [
          Colors.white,
          Colors.white,
          Color(0x33FFFFFF),
          Color(0x0DFFFFFF),
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              alignment: Alignment(-yaw / 180, 0),
            )
          : const ColoredBox(color: Color(0xFF141926)),
    );
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome({required this.roomsTotal});

  final int roomsTotal;

  @override
  Widget build(BuildContext context) {
    // Chrome minimal : une croix, une position. Le panorama occupe tout.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Fermer',
              icon: const Icon(Icons.close, color: Colors.white),
            ),
            const Spacer(),
            Text(
              'Salon · 1/$roomsTotal',
              style: AppText.label.copyWith(color: Colors.white),
            ),
            const SizedBox(width: Space.sm),
          ],
        ),
      ),
    );
  }
}

class _GyroHint extends StatelessWidget {
  const _GyroHint();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.screen_rotation_alt, color: Colors.white70, size: 18),
      const SizedBox(width: Space.xs),
      Text(
        'Tourne ton téléphone',
        style: AppText.bodyM.copyWith(color: Colors.white70),
      ),
    ],
  );
}

class _Unlock extends StatelessWidget {
  const _Unlock({
    required this.listing,
    required this.roomsTotal,
    required this.isFree,
  });

  final Listing listing;
  final int roomsTotal;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x000B0F19), Color(0xF20B0F19)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.xl,
            Space.md,
            Space.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tu vois 1 pièce sur $roomsTotal.',
                style: AppText.bodyL.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.sm),
              FilledButton(
                // Le paywall décide, puis on OUVRE. C'est le serveur qui
                // tranchera vraiment (Edge Function, CONSTITUTION P4) — cet
                // enchaînement ne fait qu'amener l'utilisateur devant la
                // porte, il ne l'ouvre pas lui-même.
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PaywallSheet(listing: listing),
                  );
                  await navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) => TourViewerScreen(
                        listingId: listing.id,
                        listingLabel:
                            '${listing.propertyType} · '
                            '${listing.neighborhood ?? listing.city}',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Accents.actionVivid,
                  // Sur terracotta vif, le label est OBSIDIENNE (5,79:1).
                  // Blanc sur terracotta = 3,31:1, échec des normes.
                  foregroundColor: const Color(0xFF0B0F19),
                  minimumSize: const Size(0, 56),
                ),
                child: Text(
                  isFree
                      ? 'Voir tout le logement — offert 🎁'
                      : 'Voir tout le logement',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
