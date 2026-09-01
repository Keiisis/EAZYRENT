import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/auth_repository.dart';
import '../../domain/entities/account.dart';
import '../bloc/auth_cubit.dart';

/// A2 / A4 — Saisie du numéro.
///
/// UN SEUL champ. Pas de mot de passe, pas d'e-mail, pas de nom : le nom sera
/// demandé plus tard, quand il servira à quelque chose.
///
/// L'indicatif +229 est fixe et non modifiable — on ne demande pas à quelqu'un
/// de Cotonou de chercher son pays dans une liste de 200 entrées.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({required this.role, this.isSignIn = false, super.key});

  final UserRole role;

  /// Connexion : volontairement plus dépouillé que la création de compte.
  /// Quelqu'un qui revient sait ce qu'il fait.
  final bool isSignIn;

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  bool _accepted = false;

  String get _digits => _controller.text.replaceAll(RegExp(r'\D'), '');
  bool get _canSubmit =>
      PhoneBj.isValid(_digits) && (widget.isSignIn || _accepted);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Le bouton désactivé affiche TOUJOURS sa raison. Un bouton grisé muet est
  /// un cul-de-sac (UI_DESIGN_SYSTEM §7).
  String? get _blockedReason {
    if (!PhoneBj.isValid(_digits)) return 'Entre ton numéro à 8 ou 10 chiffres';
    if (!widget.isSignIn && !_accepted) {
      return 'Accepte les conditions pour continuer';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cubit = context.watch<AuthCubit>();

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(backgroundColor: p.surfaceBase),
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
                    widget.isSignIn
                        ? 'Content de te revoir'
                        : 'Ton numéro de téléphone',
                    style: AppText.titleL.copyWith(color: p.inkStrong),
                  ),

                  if (!widget.isSignIn) ...[
                    const SizedBox(height: Space.xs),
                    // Le profil choisi reste visible et modifiable.
                    Row(
                      children: [
                        Text(
                          widget.role.entryLabel,
                          style: AppText.bodyM.copyWith(color: p.inkMuted),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('changer'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: Space.lg),

                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: AppText.amount.copyWith(color: p.inkStrong),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                      _GroupByTwo(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Numéro',
                      prefixText: '${PhoneBj.prefix}  ',
                      prefixStyle: AppText.amount.copyWith(color: p.inkMuted),
                      hintText: '97 12 34 56',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: Space.xs),
                  Text(
                    'On t\'envoie un code par SMS.',
                    style: AppText.bodyM.copyWith(color: p.inkMuted),
                  ),

                  if (!widget.isSignIn) ...[
                    const SizedBox(height: Space.md),
                    // Case NON pré-cochée : un consentement pré-coché n'est
                    // pas un consentement (loi n°2017-20).
                    CheckboxListTile(
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "J'accepte les conditions et la politique de données",
                        style: AppText.bodyM.copyWith(color: p.inkBase),
                      ),
                    ),
                  ],

                  if (cubit.failure != null) ...[
                    const SizedBox(height: Space.sm),
                    Text(
                      cubit.failure!.userMessage,
                      style: AppText.bodyM.copyWith(color: p.danger),
                    ),
                  ],

                  const Spacer(),

                  FilledButton(
                    onPressed: _canSubmit && !cubit.busy
                        ? () => context.read<AuthCubit>().sendOtp(
                            _digits,
                            widget.role,
                          )
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                    ),
                    child: cubit.busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Recevoir mon code'),
                  ),

                  if (_blockedReason != null) ...[
                    const SizedBox(height: Space.xs),
                    Text(
                      _blockedReason!,
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(color: p.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Groupe les chiffres par deux pendant la frappe : « 97 12 34 56 ».
class _GroupByTwo extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue neu,
  ) {
    final formatted = PhoneBj.pretty(neu.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
