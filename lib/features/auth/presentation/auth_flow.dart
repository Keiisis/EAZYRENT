import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../onboarding/presentation/pages/onboarding_page.dart';
import '../../search/presentation/bloc/feed_cubit.dart';
import '../domain/entities/account.dart';
import 'bloc/auth_cubit.dart';
import 'pages/consent_page.dart';
import 'pages/otp_page.dart';
import 'pages/phone_page.dart';
import 'pages/role_gate_page.dart';

/// Orchestration de l'authentification.
///
/// CONSTITUTION P2 — l'anonyme n'est pas un état d'attente : c'est une issue.
/// Le chercheur qui touche « Je cherche un logement » entre dans l'application
/// et n'en ressort plus. Les deux autres profils traversent le tunnel.
///
/// La règle exacte, écrite ici pour qu'elle ne se perde pas : le locataire ne
/// crée pas de compte avant d'avoir REÇU quelque chose ; le propriétaire et le
/// démarcheur en créent un immédiatement, parce que leur première action est
/// de DONNER quelque chose au système.
class AuthFlow extends StatefulWidget {
  const AuthFlow({required this.onEnterApp, super.key});

  /// Appelé dès que l'utilisateur peut entrer : anonyme ou authentifié.
  final Widget Function(Account? account) onEnterApp;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  /// Vrai dès que l'utilisateur a choisi de naviguer sans compte.
  bool _browsingAnonymously = false;

  /// Étapes du chercheur anonyme : trois questions, puis une attente courte
  /// et nommée, puis le feed. Le propriétaire et le démarcheur ne les
  /// traversent pas — ils ne cherchent pas, ils déposent.
  _TenantEntry _entry = _TenantEntry.questions;
  String? _firstQuartier;

  /// Rôle visé pendant le tunnel. Sert au moment d'écrire `profiles.role`.
  UserRole _intendedRole = UserRole.tenant;
  bool _isSignIn = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Un compte valide court-circuite tout le tunnel.
        if (state is Authenticated) return widget.onEnterApp(state.account);
        if (state is NeedsConsent) return const ConsentScreen();
        if (state is AwaitingOtp) return OtpScreen(state: state);

        // L'anonyme a demande un compte depuis le feed : on ouvre le tunnel
        // par-dessus l'application, sans lui faire perdre sa navigation.
        if (state is SignUpRequested) {
          return const PhoneScreen(role: UserRole.tenant);
        }

        // Anonyme : soit il a déjà choisi de naviguer, soit on lui demande
        // ce qu'il vient faire.
        if (_browsingAnonymously) {
          return switch (_entry) {
            // RÈGLE UX 9. Sans ces trois questions, le premier écran du
            // produit est « tous les quartiers » : un catalogue, c'est-à-dire
            // exactement ce que la personne vient de quitter sur WhatsApp.
            _TenantEntry.questions => OnboardingScreen(
              onDone: (query) {
                context.read<FeedCubit>().load(query);
                setState(() {
                  _firstQuartier = query.neighborhoods.isEmpty
                      ? null
                      : query.neighborhoods.first;
                  _entry = _TenantEntry.handoff;
                });
              },
            ),
            _TenantEntry.handoff => OnboardingHandoff(
              quartier: _firstQuartier,
              onFinished: () => setState(() => _entry = _TenantEntry.feed),
            ),
            _TenantEntry.feed => widget.onEnterApp(null),
          };
        }

        if (_isSignIn || _intendedRole != UserRole.tenant) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                setState(() {
                  _isSignIn = false;
                  _intendedRole = UserRole.tenant;
                });
              }
            },
            child: PhoneScreen(role: _intendedRole, isSignIn: _isSignIn),
          );
        }

        return RoleGateScreen(
          onBrowseAnonymously: () =>
              setState(() => _browsingAnonymously = true),
          onPickRole: (role) => setState(() {
            _intendedRole = role;
            _isSignIn = false;
          }),
          onSignIn: () => setState(() => _isSignIn = true),
        );
      },
    );
  }
}

/// Les trois temps de l'entrée d'un chercheur. Un enum plutôt que deux
/// booléens : deux booléens autorisent l'état « attente ET feed », qui n'a
/// aucun sens et finit toujours par arriver.
enum _TenantEntry { questions, handoff, feed }
