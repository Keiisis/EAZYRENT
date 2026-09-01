// Configuration par environnement — APP_STRUCTURE.md §4 (`core/config/`).
//
// CONSTITUTION P11 : aucun secret ici. La clé Supabase déclarée est la clé
// PUBLIABLE (`sb_publishable_…`), conçue pour être embarquée dans un client :
// elle se retrouve de toute façon dans l'APK, qui est décompilable. Elle ne
// protège rien par elle-même — c'est la RLS qui protège, côté serveur.
//
// ⛔ Ne JAMAIS placer ici une clé `sb_secret_…` ni `service_role` : elles
// contournent la RLS et donneraient à quiconque décompile l'APK un accès
// complet en lecture et en écriture.
//
// Les valeurs sont surchargeables au build sans toucher au code :
//   flutter build apk --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_KEY=…
// C'est ce qui permet à la CI de viser staging ou prod avec le même source.

enum Flavor { dev, staging, prod }

abstract final class AppConfig {
  static const String _flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// Un nom inconnu retombe sur `dev` : un build mal paramétré ne doit jamais
  /// se retrouver en production par accident.
  static Flavor get flavor => switch (_flavorName) {
    'prod' => Flavor.prod,
    'staging' => Flavor.staging,
    _ => Flavor.dev,
  };

  /// Un seul projet Supabase pour les deux surfaces — mobile et web.
  /// Deux projets distincts donneraient deux bases de données : un bien publié
  /// depuis l'app serait invisible sur le site, et inversement.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nwavznnpvxgvigxbnscv.supabase.co',
  );

  /// Clé publiable. Publique par conception. Voir l'en-tête de ce fichier.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_cMQ3eXYyGIkZVmHq2DEESw_oPGyqkQc',
  );

  /// Stockage objet des panoramas. Vide tant que la décision R2 n'est pas prise
  /// (voir la discussion sur la saturation : egress gratuit chez Cloudflare R2,
  /// poste qui dépasse le stockage en coût dès l'année 1).
  static const String mediaBaseUrl = String.fromEnvironment('MEDIA_BASE_URL');

  static bool get isProd => flavor == Flavor.prod;

  /// Journalisation détaillée hors production uniquement.
  static bool get verboseLogs => flavor != Flavor.prod;
}
