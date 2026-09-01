import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/domain/entities/account.dart';

/// C5 / D5 — Vérification d'identité.
///
/// UN SEUL écran pour les deux rôles, avec une exigence différente — parce
/// que le risque n'est pas le même :
///
///   · PROPRIÉTAIRE — 3 étapes. Il encaisse l'argent d'un tiers et engage un
///     bien. On demande sa preuve sur le logement : CPF délivré par l'ANDF,
///     Titre Foncier ancien régime, ou mandat de gestion signé.
///
///   · DÉMARCHEUR — 2 étapes. Il ne reçoit pas de fonds de tiers, seulement
///     sa commission. Exiger de lui un titre foncier serait absurde et le
///     ferait fuir — or c'est lui qui alimente le stock.
///
/// Calibrer la friction sur le risque réel, pas sur un principe uniforme.
class KycScreen extends StatefulWidget {
  const KycScreen({required this.role, super.key});

  final UserRole role;

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  bool _idFront = false;
  bool _idBack = false;
  String? _proofType;
  bool _proofUploaded = false;
  final _payoutPhone = TextEditingController();
  final _payoutName = TextEditingController();

  bool get _needsProperty => widget.role == UserRole.owner;
  int get _steps => _needsProperty ? 3 : 2;

  bool get _idDone => _idFront && _idBack;
  bool get _proofDone =>
      !_needsProperty || (_proofType != null && _proofUploaded);
  bool get _payoutDone =>
      _payoutPhone.text.replaceAll(RegExp(r'\D'), '').length >= 8 &&
      _payoutName.text.trim().length >= 3;

  int get _done => [
    _idDone,
    if (_needsProperty) _proofDone,
    _payoutDone,
  ].where((x) => x).length;

  String? get _blockedReason {
    if (!_idDone) return 'Ajoute le recto et le verso de ta pièce';
    if (!_proofDone) return 'Ajoute ta preuve sur le bien';
    if (!_payoutDone) return 'Renseigne où recevoir ton argent';
    return null;
  }

  @override
  void dispose() {
    _payoutPhone.dispose();
    _payoutName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          'Vérification',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                Space.md,
                120,
              ),
              children: [
                _Progress(done: _done, total: _steps),
                const SizedBox(height: Space.lg),

                _Step(
                  index: 1,
                  title: 'Ton identité',
                  done: _idDone,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Drop(
                              label: 'Recto CNI',
                              filled: _idFront,
                              onTap: () => setState(() => _idFront = true),
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: _Drop(
                              label: 'Verso CNI',
                              filled: _idBack,
                              onTap: () => setState(() => _idBack = true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        'Photo nette, les 4 coins visibles.',
                        style: AppText.bodyM.copyWith(color: p.inkMuted),
                      ),
                    ],
                  ),
                ),

                if (_needsProperty)
                  _Step(
                    index: 2,
                    title: 'Ta preuve sur le bien',
                    done: _proofDone,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Référentiel foncier BÉNINOIS. Pas d'ACD : c'est un
                        // instrument ivoirien (AUDIT_COHERENCE_BENIN §2.2).
                        // RadioGroup : `groupValue` sur RadioListTile est
                        // déprécié depuis Flutter 3.32.
                        RadioGroup<String>(
                          groupValue: _proofType,
                          onChanged: (v) => setState(() => _proofType = v),
                          child: Column(
                            children: [
                              for (final o in const [
                                'Certificat de Propriété Foncière (ANDF)',
                                'Titre Foncier ancien régime',
                                'Mandat de gestion signé',
                              ])
                                RadioListTile<String>(
                                  value: o,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    o,
                                    style: AppText.bodyL.copyWith(
                                      color: p.inkBase,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_proofType != null) ...[
                          const SizedBox(height: Space.xs),
                          _Drop(
                            label: 'Ajouter le document',
                            filled: _proofUploaded,
                            onTap: () => setState(() => _proofUploaded = true),
                          ),
                        ],
                      ],
                    ),
                  ),

                _Step(
                  index: _needsProperty ? 3 : 2,
                  title: "Où on t'envoie l'argent",
                  done: _payoutDone,
                  child: Column(
                    children: [
                      TextField(
                        controller: _payoutPhone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: AppText.amount.copyWith(color: p.inkStrong),
                        decoration: InputDecoration(
                          labelText: 'Numéro Mobile Money',
                          prefixText: '+229  ',
                          prefixStyle: AppText.amount.copyWith(
                            color: p.inkMuted,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: Space.sm),
                      TextField(
                        controller: _payoutName,
                        style: AppText.bodyL.copyWith(color: p.inkStrong),
                        decoration: const InputDecoration(
                          labelText: 'Nom du titulaire du compte',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: Space.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Le nom doit correspondre à ta pièce, sinon le '
                          'virement sera rejeté par l\'opérateur.',
                          style: AppText.bodyM.copyWith(color: p.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Space.lg),
                Container(
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: const BorderRadius.all(Radii.input),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: p.inkMuted),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          'Tes documents sont chiffrés et visibles seulement '
                          'par toi et par EAZYRENT. Loi n°2017-20.',
                          style: AppText.bodyM.copyWith(color: p.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          boxShadow: Elevation.stickyBar,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _blockedReason == null ? () {} : null,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                  ),
                  child: const Text('Envoyer pour vérification'),
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                _blockedReason ?? 'Réponse sous 48 h',
                style: AppText.caption.copyWith(color: p.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < done ? p.success : p.lineHair,
                borderRadius: const BorderRadius.all(Radii.pill),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: Space.xxs),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.done,
    required this.child,
  });

  final int index;
  final String title;
  final bool done;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: done ? p.success : p.inkMuted,
              ),
              const SizedBox(width: Space.xs),
              Text(
                'Étape $index · $title',
                style: AppText.bodyL.copyWith(
                  color: p.inkStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          child,
        ],
      ),
    );
  }
}

class _Drop extends StatelessWidget {
  const _Drop({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radii.input),
      child: Container(
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? p.success.withValues(alpha: 0.06) : p.surfaceSunken,
          border: Border.all(
            color: filled ? p.success : p.lineStrong,
            width: filled ? 2 : 1,
          ),
          borderRadius: const BorderRadius.all(Radii.input),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filled ? Icons.check_circle : Icons.add_a_photo_outlined,
              color: filled ? p.success : p.inkMuted,
            ),
            const SizedBox(height: Space.xxs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.label.copyWith(
                color: filled ? p.success : p.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
