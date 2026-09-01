import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// A04 — Numéro perdu, récupération de compte.
///
/// LE SCÉNARIO EST BANAL ICI, PAS EXCEPTIONNEL. On change de puce quand elle
/// est volée, quand le réseau ne passe plus dans un quartier, quand on trouve
/// un meilleur forfait. Sans cet écran, chaque changement de numéro efface
/// des visites payées, des crédits restants et des quittances de loyer — et
/// la personne n'a aucun recours.
///
/// DEUX PREUVES POSSIBLES, et le choix n'est pas décoratif :
///   · le NPI/CIP (ANIP) — pièce d'identité nationale, la plus forte ;
///   · l'ID d'une transaction Mobile Money récente — accessible à quelqu'un
///     qui n'a pas encore sa carte, et vérifiable de notre côté.
///
/// Offrir uniquement le NPI exclurait les personnes non encore enrôlées à
/// l'ANIP, c'est-à-dire une partie de ceux qui ont le plus besoin du produit.
///
/// AUCUNE RÉCUPÉRATION N'EST AUTOMATIQUE. Un transfert de compte donne accès
/// à des paiements : il est instruit par un humain. On l'écrit plutôt que de
/// laisser croire à un bouton magique.
class AccountRecoveryScreen extends StatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

enum _Proof { npi, momo }

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  final _old = TextEditingController();
  final _neu = TextEditingController();
  final _proofValue = TextEditingController();
  _Proof _proof = _Proof.npi;
  bool _sent = false;

  bool get _canSubmit =>
      _old.text.replaceAll(RegExp(r'\D'), '').length >= 8 &&
      _neu.text.replaceAll(RegExp(r'\D'), '').length >= 8 &&
      _proofValue.text.trim().length >= 6;

  @override
  void dispose() {
    _old.dispose();
    _neu.dispose();
    _proofValue.dispose();
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
          'Récupérer mon compte',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _sent ? _confirmation(context) : _form(context),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final p = context.palette;

    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Text(
          'Tu as changé ou perdu ta puce ?',
          style: AppText.titleL.copyWith(color: p.inkStrong),
        ),
        const SizedBox(height: Space.xxs),
        // On nomme CE QU'ON RÉCUPÈRE. « Récupérer votre compte » est abstrait ;
        // « tes visites payées et tes quittances » est la raison de remplir
        // le formulaire.
        Text(
          'Récupère tes visites 360 achetées, tes crédits restants et tes '
          'quittances de loyer sur ton nouveau numéro.',
          style: AppText.bodyL.copyWith(color: p.inkMuted),
        ),

        const SizedBox(height: Space.lg),
        _Phone(
          controller: _old,
          label: 'Ancien numéro enregistré',
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: Space.sm),
        _Phone(
          controller: _neu,
          label: 'Nouveau numéro (celui de maintenant)',
          onChanged: () => setState(() {}),
        ),

        const SizedBox(height: Space.lg),
        Text(
          'COMMENT ON VÉRIFIE QUE C\'EST TOI',
          style: AppText.label.copyWith(color: p.inkMuted),
        ),
        const SizedBox(height: Space.xs),
        _ProofOption(
          title: 'Numéro d\'identification (NPI / CIP)',
          subtitle:
              'Les 10 chiffres de ton Certificat d\'Identification '
              'Personnelle, délivré par l\'ANIP.',
          selected: _proof == _Proof.npi,
          onTap: () => setState(() {
            _proof = _Proof.npi;
            _proofValue.clear();
          }),
        ),
        _ProofOption(
          title: 'Dernier paiement Mobile Money',
          subtitle:
              'L\'identifiant de transaction reçu par SMS lors de ton '
              'dernier paiement EAZYRENT. Utile si tu n\'as pas encore ta '
              'carte ANIP.',
          selected: _proof == _Proof.momo,
          onTap: () => setState(() {
            _proof = _Proof.momo;
            _proofValue.clear();
          }),
        ),

        const SizedBox(height: Space.sm),
        TextField(
          controller: _proofValue,
          onChanged: (_) => setState(() {}),
          keyboardType: _proof == _Proof.npi
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: _proof == _Proof.npi
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ]
              : null,
          style: AppText.bodyL.copyWith(color: p.inkStrong),
          decoration: InputDecoration(
            labelText: _proof == _Proof.npi
                ? 'NPI à 10 chiffres'
                : 'Identifiant de transaction',
            hintText: _proof == _Proof.npi ? '0123456789' : 'MP2503…',
          ),
        ),

        const SizedBox(height: Space.lg),
        FilledButton(
          onPressed: _canSubmit ? () => setState(() => _sent = true) : null,
          style: FilledButton.styleFrom(
            minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
          ),
          child: const Text('Transférer mon compte'),
        ),
        const SizedBox(height: Space.xs),
        // On ne promet pas l'instantané. Un transfert donne accès à des
        // paiements : il est instruit par quelqu'un.
        Text(
          'Une personne vérifie la demande. Réponse sous 24 h, et ton ancien '
          'numéro est prévenu — c\'est ce qui empêche quelqu\'un d\'autre de '
          'prendre ton compte.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: p.inkMuted),
        ),

        const SizedBox(height: Space.md),
        OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, Touch.target(p.isHighContrast)),
          ),
          icon: const Icon(Icons.chat_outlined, size: 18),
          label: const Text('Écrire au support sur WhatsApp'),
        ),
      ],
    );
  }

  Widget _confirmation(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 48, color: p.success),
          const SizedBox(height: Space.md),
          Text(
            'Demande enregistrée.',
            style: AppText.titleL.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'On vérifie et on te répond sous 24 h sur ${_neu.text}. Tes '
            'visites payées et tes quittances restent intactes pendant ce '
            'temps.',
            style: AppText.bodyL.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
            ),
            child: const Text('C\'est noté'),
          ),
        ],
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      style: AppText.bodyL.copyWith(color: p.inkStrong),
      decoration: InputDecoration(
        labelText: label,
        // L'indicatif est FIXE et affiché, pas à saisir : +229 est le seul
        // pays servi, et le redemander à chaque champ est du travail rendu à
        // l'utilisateur pour rien.
        prefixText: '+229 ',
        prefixStyle: AppText.bodyL.copyWith(color: p.inkMuted),
      ),
    );
  }
}

class _ProofOption extends StatelessWidget {
  const _ProofOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radii.card),
        child: Container(
          constraints: BoxConstraints(
            minHeight: Touch.target(p.isHighContrast),
          ),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            border: Border.all(
              color: selected ? p.action : p.lineHair,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: const BorderRadius.all(Radii.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? p.action : p.inkFaint,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.bodyL.copyWith(color: p.inkStrong),
                    ),
                    Text(
                      subtitle,
                      style: AppText.bodyM.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
