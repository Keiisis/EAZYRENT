// RÈGLE UX 10 — « Rien n'est affiché en grisé. Une fonction verrouillée qu'on
// voit sans pouvoir l'utiliser produit de la frustration, pas du désir.
// Elle n'existe simplement pas à l'écran. » (UX_CORE_SPEC.md §10.2)
//
// Ce widget rend son enfant, ou RIEN. Il n'a volontairement aucun paramètre
// permettant d'afficher un état désactivé : l'API elle-même rend la faute
// impossible à commettre.

import 'package:flutter/widgets.dart';

import 'user_stage.dart';

class StageGate extends StatelessWidget {
  const StageGate({
    required this.min,
    required this.current,
    required this.child,
    super.key,
  });

  final UserStage min;
  final UserStage current;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (current >= min) return child;
    return const SizedBox.shrink();
  }
}

/// Seule exception documentée du produit : la preview 360 floutée.
/// C'est le seul verrou volontairement visible, parce que c'est celui qui
/// convertit (UX_CORE_SPEC.md §10.2). Elle ne passe donc pas par StageGate.
class DeliberateLock extends StatelessWidget {
  const DeliberateLock({required this.child, required this.reason, super.key});

  final Widget child;

  /// Motif écrit, lisible en revue. Un verrou visible sans motif est un bug.
  final String reason;

  @override
  Widget build(BuildContext context) => child;
}
