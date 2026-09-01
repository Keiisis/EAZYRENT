import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/moments/moment.dart';
import 'core/progression/stage_resolver.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/design_tokens.dart';
import 'core/widgets/app_shell.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_flow.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/listing/domain/repositories/listing_repository.dart';
import 'features/search/presentation/bloc/feed_cubit.dart';
import 'features/search/presentation/pages/feed_page.dart';
import 'features/shortlist/presentation/bloc/shortlist_cubit.dart';
import 'features/shortlist/presentation/pages/shortlist_page.dart';

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

      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                FeedCubit(getIt<ListingRepository>())
                  ..load(const SearchQuery()),
          ),
          BlocProvider(
            create: (_) =>
                ShortlistCubit(getIt<MomentBus>(), getIt<StageResolver>()),
          ),
          BlocProvider(
            create: (_) => AuthCubit(getIt<AuthRepository>())..restore(),
          ),
        ],
        child: AuthFlow(onEnterApp: (_) => const _Root()),
      ),
    );
  }
}

/// La coque écoute le palier : garder un bien fait apparaître « Ma liste »,
/// acheter un pass fait apparaître « Messages ». La règle 10 est visible.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShortlistCubit, ShortlistState>(
      builder: (context, _) => AppShell(
        stage: context.read<ShortlistCubit>().stage,
        search: const FeedScreen(),
        shortlist: const ShortlistScreen(),
        messages: const _Placeholder(label: 'Messages'),
        me: const _Placeholder(label: 'Moi'),
      ),
    );
  }
}

/// Écrans pas encore construits. Ils ne prétendent pas exister : ils disent
/// ce qu'ils seront. Une coquille vide sans explication est pire qu'absente.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Text(
          '$label — à construire',
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),
      ),
    );
  }
}
