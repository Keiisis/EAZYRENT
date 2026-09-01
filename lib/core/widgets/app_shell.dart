import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/account.dart';
import '../progression/user_stage.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// La coque de navigation — UX_CORE_SPEC.md §5.
///
/// QUATRE onglets au maximum, jamais cinq. Et surtout : les onglets
/// APPARAISSENT selon le palier (règle 10). Ce n'est pas de la décoration —
/// c'est le module `core/progression` rendu visible.
///
/// Au premier lancement (P0), l'utilisateur n'a que « Chercher » et « Moi ».
/// « Ma liste » n'a aucun sens avant qu'il ait quelque chose à y mettre, et
/// « Messages » avant qu'il ait quelqu'un à qui écrire. Un onglet vide est
/// une promesse non tenue ; un onglet absent n'est rien du tout.
///
/// AUCUN onglet grisé. Une fonction verrouillée n'existe pas à l'écran.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.role,
    required this.stage,
    required this.search,
    required this.shortlist,
    required this.messages,
    required this.me,
    required this.ownerHome,
    required this.brokerHome,
    super.key,
  });

  /// Chaque profil a SA navigation. Un propriétaire n'a pas d'onglet
  /// « Chercher » : il ne cherche pas, il surveille. Un démarcheur n'a pas
  /// de « Ma liste » : il n'accumule pas des biens pour lui.
  final UserRole role;

  final UserStage stage;
  final Widget search;
  final Widget shortlist;
  final Widget messages;
  final Widget me;
  final Widget ownerHome;
  final Widget brokerHome;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// Les onglets visibles, selon le RÔLE d'abord, le palier ensuite.
  List<_Tab> _tabs() => switch (widget.role) {
    UserRole.owner => [
      _Tab(
        icon: Icons.home_work_outlined,
        activeIcon: Icons.home_work,
        label: 'Mes biens',
        page: widget.ownerHome,
      ),
      _Tab(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
        page: widget.messages,
      ),
      _Tab(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Moi',
        page: widget.me,
      ),
    ],
    UserRole.broker => [
      _Tab(
        icon: Icons.handshake_outlined,
        activeIcon: Icons.handshake,
        label: 'Mes apports',
        page: widget.brokerHome,
      ),
      _Tab(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
        page: widget.messages,
      ),
      _Tab(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Moi',
        page: widget.me,
      ),
    ],
    UserRole.tenant => _tenantTabs(),
  };

  /// Le locataire est le seul dont la navigation grandit avec le palier.
  List<_Tab> _tenantTabs() => [
    _Tab(
      icon: Icons.search,
      activeIcon: Icons.search,
      label: 'Chercher',
      page: widget.search,
    ),
    // P1 — un tour terminé : il a enfin quelque chose à garder.
    if (widget.stage >= UserStage.p1Eveille)
      _Tab(
        icon: Icons.star_border,
        activeIcon: Icons.star,
        label: 'Ma liste',
        page: widget.shortlist,
      ),
    // P2 — chasseur : il compare, donc il va vouloir écrire.
    if (widget.stage >= UserStage.p2Chasseur)
      _Tab(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
        page: widget.messages,
      ),
    _Tab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Moi',
      page: widget.me,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tabs = _tabs();
    // Le palier peut baisser le nombre d'onglets entre deux builds :
    // on ne laisse jamais l'index pointer dans le vide.
    final index = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: IndexedStack(
        index: index,
        children: [for (final t in tabs) t.page],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: p.surfaceRaised,
        indicatorColor: p.action.withValues(alpha: 0.12),
        // Les libellés restent toujours visibles : une icône seule est
        // ambiguë, et elle est muette pour les lecteurs d'écran.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: Touch.target(p.isHighContrast) + 24,
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon, color: p.inkMuted),
              selectedIcon: Icon(t.activeIcon, color: p.action),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;
}
