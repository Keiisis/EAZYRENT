import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../support/presentation/pages/help_page.dart';
import '../../domain/entities/account.dart';
import '../bloc/auth_cubit.dart';

/// A3 — Saisie du code.
///
/// Écran à fort taux d'échec : l'e-mail tombe en indésirables, le code expire,
/// on se trompe de chiffre. Chaque issue doit rester ouverte.
///
/// Le compte à rebours est PROLONGEABLE. Et au deuxième échec on rappelle de
/// regarder les indésirables : c'est de loin la premiere cause de « je n'ai
/// rien recu » avec un code par e-mail, bien avant l'adresse mal saisie.
class OtpScreen extends StatefulWidget {
  const OtpScreen({required this.state, super.key});

  final AwaitingOtp state;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _codeLength = 6;
  static const _resendSeconds = 45;

  final _controller = TextEditingController();
  Timer? _timer;
  int _remaining = _resendSeconds;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remaining = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cubit = context.watch<AuthCubit>();
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    final hasError = cubit.failure != null;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        leading: IconButton(
          onPressed: () => context.read<AuthCubit>().cancelOtp(),
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Entre le code',
                    style: AppText.titleL.copyWith(color: p.inkStrong),
                  ),
                  const SizedBox(height: Space.xs),
                  Row(
                    children: [
                      Text(
                        'Envoyé à ${widget.state.email}',
                        style: AppText.bodyM.copyWith(color: p.inkMuted),
                      ),
                      TextButton(
                        onPressed: () => context.read<AuthCubit>().cancelOtp(),
                        child: const Text('modifier'),
                      ),
                    ],
                  ),

                  const SizedBox(height: Space.lg),

                  _CodeBoxes(
                    code: code,
                    hasError: hasError,
                    length: _codeLength,
                  ),

                  // Champ réel, invisible : il capte la saisie et le
                  // remplissage automatique du SMS.
                  SizedBox(
                    height: 0,
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        maxLength: _codeLength,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (v) {
                          setState(() {});
                          if (v.length == _codeLength) {
                            _attempts++;
                            context.read<AuthCubit>().verify(v);
                          }
                        },
                      ),
                    ),
                  ),

                  if (hasError) ...[
                    const SizedBox(height: Space.sm),
                    Text(
                      cubit.failure!.userMessage,
                      textAlign: TextAlign.center,
                      style: AppText.bodyM.copyWith(color: p.danger),
                    ),
                  ],

                  const SizedBox(height: Space.lg),

                  if (_remaining > 0)
                    Text(
                      'Renvoyer le code dans 0:${_remaining.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    )
                  else
                    TextButton(
                      onPressed: () {
                        context.read<AuthCubit>().resend();
                        _startCountdown();
                      },
                      child: const Text('Renvoyer le code'),
                    ),

                  // Au deuxième échec, on donne la cause la plus probable
                  // plutôt que de répéter « réessaie ».
                  if (_attempts >= 2) ...[
                    const SizedBox(height: Space.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 15, color: p.inkMuted),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: Text(
                            'Regarde aussi tes indésirables : le code y tombe '
                            'souvent.',
                            style: AppText.bodyM.copyWith(color: p.inkMuted),
                          ),
                        ),
                      ],
                    ),
                    // A5 — la sortie de secours. Quelqu'un qui a changé de
                    // numéro ou perdu l'accès à sa boîte n'a AUCUN moyen de
                    // s'en sortir seul : sans cette porte, le compte est
                    // perdu et la personne aussi.
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: Size(0, Touch.target(p.isHighContrast)),
                        foregroundColor: p.inkMuted,
                      ),
                      child: const Text('Je n\'ai plus accès à cette adresse'),
                    ),
                  ],

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.code,
    required this.hasError,
    required this.length,
  });

  final String code;
  final bool hasError;
  final int length;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AspectRatio(
                aspectRatio: 0.78,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.surfaceRaised,
                    border: Border.all(
                      color: hasError
                          ? p.danger
                          : (i == code.length ? p.action : p.lineHair),
                      width: (hasError || i == code.length) ? 2 : 1,
                    ),
                    borderRadius: const BorderRadius.all(Radii.input),
                  ),
                  child: Text(
                    i < code.length ? code[i] : '',
                    style: AppText.amount.copyWith(color: p.inkStrong),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
