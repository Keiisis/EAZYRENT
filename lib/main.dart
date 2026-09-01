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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait uniquement : l'app se tient à une main, debout, dehors.
  // Seule la visionneuse 360 déverrouille l'orientation, et elle le fait
  // localement.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Le jeton Mapbox, s'il existe. L'absence de `.env` n'est PAS une erreur :
  // la carte bascule alors sur OpenStreetMap, qui ne demande aucun jeton.
  // Faire échouer le démarrage sur un fichier de configuration manquant
  // reviendrait à empêcher quelqu'un de chercher un logement pour un défaut
  // qui n'est pas le sien.
  //
  // ⚠️ Ce `.env` est embarqué comme asset : il sort le jeton de git, pas de
  // l'APK. Voir l'en-tête de `.env.example`.
  try {
    await dotenv.load();
  } catch (_) {
    // Rien à faire : `MapCtrl` retombe sur OSM tout seul.
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    debug: AppConfig.verboseLogs,
    authOptions: const FlutterAuthClientOptions(
      // CONSTITUTION P2 — l'absence de session est un état de plein droit.
      // On restaure une session existante, on n'en exige jamais une.
      autoRefreshToken: true,
    ),
  );

  await configureDependencies();

  runApp(const EazyrentApp());
}

/// Point d'accès unique au client Supabase.
///
/// Réservé à la couche `data` des features (`*/data/datasources/`).
/// Un widget qui appelle ceci est un bug : la présentation ne parle jamais
/// à une source de données (APP_STRUCTURE.md §4).
SupabaseClient get supabase => Supabase.instance.client;
