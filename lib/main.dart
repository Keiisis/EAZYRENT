// Bootstrap : DI → thème → routeur. Rien d'autre.
//
// P2 — aucune session n'est exigée au démarrage. Si une recherche existe, on
// ouvre le feed depuis le cache et on rafraîchit en arrière-plan : on ne
// repasse jamais par l'onboarding (UI_SCREENS_SPEC.md S00).
//
// Aucun splash animé. Un splash de 2 s est 2 s volées à quelqu'un qui cherche
// un toit.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android-first, portrait uniquement : l'app se tient à une main, debout.
  // Seule la visionneuse 360 déverrouille l'orientation, et elle le fait
  // localement.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await configureDependencies();

  runApp(const EazyrentApp());
}
