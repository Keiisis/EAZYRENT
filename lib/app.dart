import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/moments/moment.dart';
import 'core/progression/stage_resolver.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/app_shell.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/entities/account.dart';
import 'features/auth/presentation/auth_flow.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/broker/presentation/pages/broker_home_page.dart';
import 'features/listing/domain/repositories/listing_repository.dart';
import 'features/messaging/presentation/pages/conversations_page.dart';
import 'features/owner/presentation/pages/owner_dashboard_page.dart';
import 'features/profile/presentation/pages/me_page.dart';
import 'features/search/presentation/bloc/feed_cubit.dart';
import 'features/search/presentation/pages/feed_page.dart';
import 'features/shortlist/presentation/bloc/shortlist_cubit.dart';
import 'features/shortlist/presentation/pages/shortlist_page.dart';

class EazyrentApp extends StatelessWidget {
  const EazyrentApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Le thème est reconstruit à chaque changement du contrôleur. C'est ce
    // qui rend le Mode Plein Soleil RÉEL : avant, l'interrupteur bougeait et
    // l'écran ne changeait pas.
    return ListenableBuilder(
      listenable: getIt<ThemeController>(),
      builder: (context, _) => _buildApp(getIt<ThemeController>().mode),
    );
  }

  Widget _buildApp(AppThemeMode mode) {
    return MaterialApp(
      title: 'EAZYRENT',
      debugShowCheckedModeBanner: false,

      theme: switch (mode) {
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
        child: AuthFlow(onEnterApp: (account) => _Root(account: account)),
      ),
    );
  }
}

/// La coque écoute le palier : garder un bien fait apparaître « Ma liste »,
/// acheter un pass fait apparaître « Messages ». La règle 10 est visible.
class _Root extends StatelessWidget {
  const _Root({this.account});

  /// `null` = anonyme. Un anonyme est forcement un chercheur : les deux
  /// autres profils ont du s'identifier pour arriver ici.
  final Account? account;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShortlistCubit, ShortlistState>(
      builder: (context, _) => AppShell(
        role: account?.role ?? UserRole.tenant,
        ownerHome: const OwnerDashboardScreen(),
        brokerHome: const BrokerHomeScreen(),
        stage: context.read<ShortlistCubit>().stage,
        search: const FeedScreen(),
        shortlist: const ShortlistScreen(),
        messages: ConversationsScreen(role: account?.role ?? UserRole.tenant),
        me: const MeScreen(),
      ),
    );
  }
}
