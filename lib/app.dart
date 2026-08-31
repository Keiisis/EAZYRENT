import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';

enum AppThemeMode { light, dark, sunlight }

class EazyrentApp extends StatefulWidget {
  const EazyrentApp({super.key});

  @override
  State<EazyrentApp> createState() => _EazyrentAppState();
}

class _EazyrentAppState extends State<EazyrentApp> {
  // Fixe jusqu'à ce que E0.1 branche ThemeController (clair / sombre /
  // Plein Soleil proposé par le capteur de luminosité).
  final AppThemeMode _mode = AppThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EAZYRENT',
      debugShowCheckedModeBanner: false,

      theme: switch (_mode) {
        AppThemeMode.light => AppTheme.light(),
        AppThemeMode.dark => AppTheme.dark(),
        AppThemeMode.sunlight => AppTheme.sunlight(),
      },

      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // L'application doit rester utilisable jusqu'à textScaleFactor 2,0.
      // On borne le bas, jamais le haut : rapetisser le texte de quelqu'un qui
      // l'a agrandi exprès, c'est décider à sa place.
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(minScaleFactor: 1.0, child: child!),

      home: const _Placeholder(),
    );
  }
}

/// Remplacé par le routeur en story E0.1. Présent pour que `flutter run`
/// produise quelque chose de vérifiable dès le premier commit.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Center(
        child: Text(
          'EAZYRENT',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(color: p.inkStrong),
        ),
      ),
    );
  }
}
