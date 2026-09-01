import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        if (_browsingAnonymously) return widget.onEnterApp(null);

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
