import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/tour_repository.dart';
import '../../domain/entities/tour_scene.dart';

/// S06 — La visionneuse 360, tour complet. LE cœur du produit.
///
/// POURQUOI CE N'EST PAS UN WEBVIEW.
/// La v1.0 prévoyait Photo Sphere Viewer + Three.js embarqués dans un
/// `flutter_inappwebview`. Trois raisons de ne pas le faire, et la troisième
/// suffit :
///   1. `assets/tour_engine/` est resté VIDE : le bundle JS n'a jamais été
///      livré. On aurait embarqué un moteur qu'on ne relit pas.
///   2. Aucune version publiée de `flutter_inappwebview` n'est compatible
///      AGP 9 — c'est ce qui bloquait cet écran depuis le début.
///   3. Un webview démarre une machine JavaScript et un compositeur séparé
///      pour afficher une sphère texturée. Sur un Mali-G52, c'est le poste de
///      perte d'images le plus cher du produit.
///
/// `panorama_viewer` rend la même sphère équirectangulaire en Dart, avec le
/// gyroscope, sans moteur JS et sans conflit de build.
///
/// LES PANORAMAS SONT ÉQUIRECTANGULAIRES 2:1, importés par l'administrateur.
/// Une image au mauvais rapport se déforme aux pôles sans lever d'erreur :
/// c'est pourquoi l'écran d'import la refuse plutôt que la visionneuse.
///
/// LE PAYWALL N'EST PAS ICI. Cet écran ne sait pas si l'utilisateur a payé :
/// il demande l'accès au serveur et affiche ce qu'on lui rend. Un refus 402
/// devient un message qui dit quoi faire (CONSTITUTION P4).
class TourViewerScreen extends StatefulWidget {
  const TourViewerScreen({
    required this.listingId,
    required this.listingLabel,
    super.key,
  });

  final String listingId;
  final String listingLabel;

  @override
  State<TourViewerScreen> createState() => _TourViewerScreenState();
}

class _TourViewerScreenState extends State<TourViewerScreen> {
  TourAccess? _access;
  Failure? _failure;
  int _index = 0;
  bool _gyro = false;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    // La visite est le seul écran du produit qui déverrouille l'orientation :
    // un panorama se regarde aussi en paysage, téléphone à l'horizontale.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _load();
  }

  @override
  void dispose() {
    // On rend le portrait à la sortie. Sans ça, tout le reste de
    // l'application hérite d'une orientation qu'elle n'a jamais demandée.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    final result = await getIt<TourRepository>().openTour(widget.listingId);
    if (!mounted) return;
    result.match(
      (f) => setState(() => _failure = f),
      (a) => setState(() {
        _access = a;
        _failure = null;
      }),
    );
  }

  TourScene? get _scene {
    final a = _access;
    if (a == null || a.scenes.isEmpty) return null;
    return a.scenes[_index.clamp(0, a.scenes.length - 1)];
  }

  void _goTo(String sceneId) {
    final scenes = _access?.scenes;
    if (scenes == null) return;
    final i = scenes.indexWhere((s) => s.id == sceneId);
    if (i >= 0) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      // Fond NOIR, pas `surfaceBase`. Une sphère photographique se regarde sur
      // du noir : tout le reste renvoie une teinte sur les bords de l'image.
      backgroundColor: Colors.black,
      body: _failure != null
          ? _Error(failure: _failure!, onRetry: _load)
          : _access == null
          ? const _Loading()
          : _viewer(context, p),
    );
  }

  Widget _viewer(BuildContext context, AppPalette p) {
    final access = _access!;
    final scene = _scene!;

    return Stack(
      children: [
        // Un geste sur l'image bascule l'habillage. Regarder une pièce sans
        // rien par-dessus est la moitié de ce qu'on vend.
        GestureDetector(
          onTap: () => setState(() => _chromeVisible = !_chromeVisible),
          child: PanoramaViewer(
            // La clé force la reconstruction complète au changement de pièce.
            // Sans elle, la nouvelle texture se pose sur l'ancienne caméra et
            // on arrive dans la chambre en regardant le plafond du salon.
            key: ValueKey(scene.id),
            animSpeed: 0,
            sensorControl: _gyro
                ? SensorControl.orientation
                : SensorControl.none,
            longitude: scene.initialYaw,
            latitude: scene.initialPitch,
            // Bornes verticales : on ne se retourne pas au-delà des pôles,
            // où l'image équirectangulaire s'écrase toujours.
            minLatitude: -80,
            maxLatitude: 80,
            hotspots: [
              for (final h in scene.hotspots)
                Hotspot(
                  longitude: h.longitude,
                  latitude: h.latitude,
                  width: 140,
                  height: 56,
                  widget: _DoorHotspot(
                    label: h.label,
                    onTap: () => _goTo(h.targetSceneId),
                  ),
                ),
            ],
            child: Image.network(
              scene.panoramaUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
            ),
          ),
        ),

        if (_chromeVisible) ...[
          _TopBar(
            scene: scene,
            index: _index,
            total: access.scenes.length,
            access: access,
            gyro: _gyro,
            onGyro: () => setState(() => _gyro = !_gyro),
          ),
          _RoomStrip(
            scenes: access.scenes,
            index: _index,
            onPick: (i) => setState(() => _index = i),
          ),
        ],
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.scene,
    required this.index,
    required this.total,
    required this.access,
    required this.gyro,
    required this.onGyro,
  });

  final TourScene scene;
  final int index;
  final int total;
  final TourAccess access;
  final bool gyro;
  final VoidCallback onGyro;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Row(
            children: [
              _Round(
                icon: Icons.close,
                tooltip: 'Fermer',
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm,
                    vertical: Space.xs,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xB30B0F19),
                    borderRadius: BorderRadius.all(Radii.pill),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        // La pièce est NOMMÉE, et le compteur dit où on en
                        // est. « Salon · 1/6 » évite de tourner en rond dans
                        // un logement qu'on ne connaît pas.
                        '${scene.name} · ${index + 1}/$total',
                        style: AppText.bodyL.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        // LA PROMESSE DU PRODUIT, dans la visite elle-même.
                        access.agentName == null
                            ? 'Filmé sur place'
                            : 'Filmé par ${access.agentName}',
                        style: AppText.caption.copyWith(
                          color: const Color(0xFF00E599),
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Space.xs),
              _Round(
                icon: gyro ? Icons.screen_rotation : Icons.threesixty,
                tooltip: gyro
                    ? 'Bouger avec le doigt'
                    : 'Bouger en tournant le téléphone',
                active: gyro,
                onTap: onGyro,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La bande des pièces. Elle remplace un menu : on voit d'un coup combien il
/// y a de pièces, et on saute directement dans celle qui décide — souvent la
/// douche ou la cuisine, jamais le salon.
class _RoomStrip extends StatelessWidget {
  const _RoomStrip({
    required this.scenes,
    required this.index,
    required this.onPick,
  });

  final List<TourScene> scenes;
  final int index;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            itemCount: scenes.length,
            itemBuilder: (_, i) {
              final on = i == index;
              return Padding(
                padding: const EdgeInsets.only(right: Space.xs, bottom: 8),
                child: InkWell(
                  onTap: () => onPick(i),
                  borderRadius: const BorderRadius.all(Radii.pill),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minWidth: 88),
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    decoration: BoxDecoration(
                      color: on ? Accents.actionFill : const Color(0xB30B0F19),
                      borderRadius: const BorderRadius.all(Radii.pill),
                    ),
                    child: Text(
                      scenes[i].name,
                      style: AppText.label.copyWith(
                        color: Colors.white,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Le point de passage, posé sur la porte qu'on voit. Il porte le nom de la
/// pièce où il mène : une pastille muette oblige à toucher pour savoir.
class _DoorHotspot extends StatelessWidget {
  const _DoorHotspot({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xCC0B0F19),
        borderRadius: const BorderRadius.all(Radii.pill),
        border: Border.all(color: Accents.infoVivid, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.door_front_door_outlined,
            size: 18,
            color: Accents.infoVivid,
          ),
          const SizedBox(width: Space.xs),
          Flexible(
            child: Text(
              label,
              style: AppText.label.copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: Touch.min,
        height: Touch.min,
        decoration: BoxDecoration(
          color: active ? Accents.infoVivid : const Color(0xB30B0F19),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: active ? const Color(0xFF0B0F19) : Colors.white,
          size: 20,
        ),
      ),
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Accents.infoVivid,
          ),
        ),
        SizedBox(height: Space.md),
        Text(
          'On ouvre la visite…',
          style: TextStyle(
            fontFamily: Fonts.body,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

/// Un écran noir muet est le pire résultat possible pour une visite payée.
/// L'erreur dit ce qui s'est passé ET ce qu'il advient du crédit.
class _Error extends StatelessWidget {
  const _Error({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 40),
          const SizedBox(height: Space.md),
          Text(
            failure.userMessage,
            style: const TextStyle(
              fontFamily: Fonts.body,
              fontSize: 18,
              height: 1.4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: Accents.infoVivid,
                  foregroundColor: const Color(0xFF0B0F19),
                  minimumSize: const Size(0, Touch.min),
                ),
                child: const Text('Réessayer'),
              ),
              const SizedBox(width: Space.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  minimumSize: const Size(0, Touch.min),
                ),
                child: const Text('Revenir'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
