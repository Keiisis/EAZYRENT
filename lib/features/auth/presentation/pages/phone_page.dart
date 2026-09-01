import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/auth_repository.dart';
import '../../domain/entities/account.dart';
import '../bloc/auth_cubit.dart';

/// A2 / A4 — Identité.
///
/// DEUX champs, et ils ne servent pas à la même chose. C'est dit à l'écran :
/// un utilisateur à qui on demande deux coordonnées sans expliquer pourquoi
/// soupçonne — à raison, sur ce marché — qu'on constitue un fichier.
///
///   · L'E-MAIL reçoit le code. C'est le canal technique.
///     Le SMS aurait été meilleur ici : il est lu, l'e-mail beaucoup moins.
///     Mais les passerelles SMS béninoises sont payantes dès le premier envoi.
///     Arbitrage de budget, pas de conception — à rebasculer plus tard.
///
///   · LE NUMÉRO est l'identité produit. C'est par lui que passeront les
///     rappels de visite, les échéances de loyer et les quittances, sur
///     WhatsApp — le canal réellement lu ici.
///
/// Toujours pas de mot de passe, pas de nom : le nom viendra quand il servira.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({required this.role, this.isSignIn = false, super.key});

  final UserRole role;

  /// Connexion : plus dépouillé. Quelqu'un qui revient sait ce qu'il fait,
  /// et son numéro est déjà connu — on ne le redemande pas.
  final bool isSignIn;

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _accepted = false;

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  bool get _phoneOk => widget.isSignIn || PhoneBj.isValid(_digits);
  bool get _emailOk => EmailCheck.isValid(_email.text);
  bool get _canSubmit => _emailOk && _phoneOk && (widget.isSignIn || _accepted);

  /// Un bouton désactivé affiche TOUJOURS sa raison — et une seule à la fois,
  /// la première qui bloque. Lister trois reproches d'un coup décourage.
  String? get _blockedReason {
    if (!_emailOk) return 'Entre une adresse e-mail valide';
    if (!_phoneOk) return 'Entre ton numéro à 8 ou 10 chiffres';
    if (!widget.isSignIn && !_accepted) {
      return 'Accepte les conditions pour continuer';
    }
    return null;
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isSignIn
                        ? 'Content de te revoir'
                        : 'On fait connaissance',
                    style: AppText.titleL.copyWith(color: p.inkStrong),
                  ),

                  if (!widget.isSignIn) ...[
                    const SizedBox(height: Space.xs),
                    Row(
                      children: [
                        Text(
                          widget.role.entryLabel,
                          style: AppText.bodyM.copyWith(color: p.inkMuted),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('changer'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: Space.lg),

                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autofocus: true,
                    style: AppText.bodyL.copyWith(color: p.inkStrong),
                    decoration: const InputDecoration(
                      labelText: 'Ton e-mail',
                      hintText: 'nom@exemple.com',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    "C'est là qu'arrive ton code.",
                    style: AppText.bodyM.copyWith(color: p.inkMuted),
                  ),

                  if (!widget.isSignIn) ...[
                    const SizedBox(height: Space.lg),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      style: AppText.amount.copyWith(color: p.inkStrong),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                        _GroupByTwo(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Ton numéro',
                        prefixText: '${PhoneBj.prefix}  ',
                        prefixStyle: AppText.amount.copyWith(color: p.inkMuted),
                        hintText: '97 12 34 56',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: Space.xxs),
                    // On dit POURQUOI on demande le numéro. Sans raison
                    // affichée, la demande est perçue comme du fichage — et
                    // sur ce marché ce soupçon est fondé.
                    Text(
                      'Il sert à te joindre pour les visites et les quittances. '
                      'On ne le montre pas aux autres utilisateurs.',
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),

                    const SizedBox(height: Space.md),
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

                  const SizedBox(height: Space.xl),

                  FilledButton(
                    onPressed: _canSubmit && !cubit.busy
                        ? () => context.read<AuthCubit>().sendOtp(
                            email: _email.text,
                            phoneDigits: _digits,
                            intendedRole: widget.role,
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
