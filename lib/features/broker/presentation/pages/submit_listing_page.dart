import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';

/// D2 — Apporter un bien.
///
/// UN SEUL écran défilant. Le démarcheur saisit DEBOUT, DANS LA RUE, souvent
/// devant le portail du bien. Un assistant en cinq étapes n'y survit pas.
///
/// Trois décisions qui viennent du terrain :
///   · Le MONTANT est dans le bouton d'envoi. C'est ce qui motive le geste.
///   · La NOTE VOCALE est aussi grosse que les autres champs : parler est
///     plus rapide que taper sur un Tecno, une main occupée.
///   · On demande le contact du propriétaire, pas une description léchée.
///     Ce qu'on achète à l'apporteur, c'est l'accès — pas la rédaction.
class SubmitListingScreen extends StatefulWidget {
  const SubmitListingScreen({super.key});

  @override
  State<SubmitListingScreen> createState() => _SubmitListingScreenState();
}

class _SubmitListingScreenState extends State<SubmitListingScreen> {
  static const _neighborhoods = [
    'Fidjrossè',
    'Cadjèhoun',
    'Agla',
    'Godomey',
    'Kpota',
    'Akpakpa',
    'Vèdoko',
    'Sainte-Rita',
  ];
  static const _types = ['Chambre', 'Chambre-salon', '2 ch-salon', 'Boutique'];
  static const _reward = 1000;
  static const _minPhotos = 3;

  String? _neighborhood;
  String? _type;
  int _advanceMonths = 2;
  int _photos = 0;
  bool _recording = false;
  bool _hasVoiceNote = false;
  final _rent = TextEditingController();
  final _ownerPhone = TextEditingController();

  int get _rentValue =>
      int.tryParse(_rent.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
  int get _ownerDigits => _ownerPhone.text.replaceAll(RegExp(r'\D'), '').length;

  bool get _canSubmit =>
      _type != null &&
      _neighborhood != null &&
      _rentValue >= 5000 &&
      _photos >= _minPhotos &&
      (_ownerDigits == 8 || _ownerDigits == 10);

  /// Une seule raison à la fois, la première qui bloque.
  String? get _blockedReason {
    if (_type == null) return 'Choisis le type de bien';
    if (_neighborhood == null) return 'Choisis le quartier';
    if (_rentValue < 5000) return 'Entre le loyer demandé';
    if (_photos < _minPhotos) {
      return 'Ajoute au moins $_minPhotos photos ($_photos/$_minPhotos)';
    }
    if (_ownerDigits != 8 && _ownerDigits != 10) {
      return 'Entre le numéro du propriétaire';
    }
    return null;
  }

  @override
  void dispose() {
    _rent.dispose();
    _ownerPhone.dispose();
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
          'Apporter un bien',
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
                140,
              ),
              children: [
                _Label('Type de bien'),
                _Chips(
                  options: _types,
                  selected: _type,
                  onSelect: (v) => setState(() => _type = v),
                ),

                const SizedBox(height: Space.lg),
                _Label('Quartier'),
                _Chips(
                  options: _neighborhoods,
                  selected: _neighborhood,
                  onSelect: (v) => setState(() => _neighborhood = v),
                ),

                const SizedBox(height: Space.lg),
                _Label('Loyer demandé'),
                TextField(
                  controller: _rent,
                  keyboardType: TextInputType.number,
                  style: AppText.amount.copyWith(color: p.inkStrong),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    suffixText: 'F /mois',
                    hintText: '35000',
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: Space.lg),
                _Label('Avance demandée'),
                _Chips(
                  options: const ['1', '2', '3', '6', '12'],
                  selected: '$_advanceMonths',
                  onSelect: (v) =>
                      setState(() => _advanceMonths = int.parse(v)),
                ),

                const SizedBox(height: Space.lg),
                _Label('Photos'),
                _PhotoStrip(
                  count: _photos,
                  minimum: _minPhotos,
                  onAdd: () => setState(() => _photos++),
                ),

                const SizedBox(height: Space.lg),
                _Label('Contact du propriétaire'),
                TextField(
                  controller: _ownerPhone,
                  keyboardType: TextInputType.phone,
                  style: AppText.amount.copyWith(color: p.inkStrong),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Numéro',
                    prefixText: '+229  ',
                    prefixStyle: AppText.amount.copyWith(color: p.inkMuted),
                    hintText: '97 12 34 56',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Un agent EAZYRENT appellera pour vérifier. '
                  'Le propriétaire ne verra pas ton numéro.',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),

                const SizedBox(height: Space.lg),
                _Label('Note vocale · facultatif'),
                _VoiceNote(
                  recording: _recording,
                  hasNote: _hasVoiceNote,
                  onToggle: () => setState(() {
                    if (_recording) {
                      _recording = false;
                      _hasVoiceNote = true;
                    } else {
                      _recording = true;
                    }
                  }),
                  onDelete: () => setState(() => _hasVoiceNote = false),
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
                  onPressed: _canSubmit ? () {} : null,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                  ),
                  // Le montant DANS le bouton : c'est lui qui motive l'envoi.
                  child: Text(
                    'Envoyer — ${MoneyFcfa.short(_reward)} si vérifié',
                  ),
                ),
              ),
              if (_blockedReason != null) ...[
                const SizedBox(height: Space.xs),
                Text(
                  _blockedReason!,
                  style: AppText.caption.copyWith(color: p.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Text(
        text.toUpperCase(),
        style: AppText.label.copyWith(color: p.inkMuted),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String? selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final o in options)
          InkWell(
            onTap: () => onSelect(o),
            borderRadius: const BorderRadius.all(Radii.pill),
            child: Container(
              constraints: BoxConstraints(
                minHeight: Touch.target(p.isHighContrast),
              ),
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: o == selected
                    ? p.action.withValues(alpha: 0.10)
                    : p.surfaceRaised,
                border: Border.all(
                  color: o == selected ? p.action : p.lineHair,
                  width: o == selected ? 2 : 1,
                ),
                borderRadius: const BorderRadius.all(Radii.pill),
              ),
              child: Text(
                o,
                style: AppText.bodyM.copyWith(
                  color: o == selected ? p.action : p.inkBase,
                  fontWeight: o == selected ? FontWeight.w600 : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.count,
    required this.minimum,
    required this.onAdd,
  });

  final int count;
  final int minimum;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enough = count >= minimum;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              InkWell(
                onTap: onAdd,
                borderRadius: const BorderRadius.all(Radii.input),
                child: Container(
                  width: 88,
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    border: Border.all(color: p.lineStrong),
                    borderRadius: const BorderRadius.all(Radii.input),
                  ),
                  child: Icon(Icons.add_a_photo_outlined, color: p.inkMuted),
                ),
              ),
              for (var i = 0; i < count; i++)
                Padding(
                  padding: const EdgeInsets.only(left: Space.xs),
                  child: Container(
                    width: 88,
                    decoration: BoxDecoration(
                      color: p.surfaceSunken,
                      borderRadius: const BorderRadius.all(Radii.input),
                    ),
                    child: Icon(Icons.image_outlined, color: p.inkFaint),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.xxs),
        Row(
          children: [
            Icon(
              enough ? Icons.check_circle : Icons.info_outline,
              size: 14,
              color: enough ? p.success : p.inkMuted,
            ),
            const SizedBox(width: Space.xxs),
            Text(
              enough
                  ? '$count photos — c\'est bon'
                  : '$count / $minimum photos minimum',
              style: AppText.label.copyWith(
                color: enough ? p.success : p.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bouton vocal de la MÊME taille que les autres champs. Sur ce marché,
/// parler est plus rapide que taper — le vocal n'est pas un raccourci
/// secondaire, c'est le mode d'entrée principal pour beaucoup.
class _VoiceNote extends StatelessWidget {
  const _VoiceNote({
    required this.recording,
    required this.hasNote,
    required this.onToggle,
    required this.onDelete,
  });

  final bool recording;
  final bool hasNote;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (hasNote) {
      return Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: const BorderRadius.all(Radii.input),
        ),
        child: Row(
          children: [
            Icon(Icons.play_arrow, color: p.action),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                'Note vocale · 0:12',
                style: AppText.bodyL.copyWith(color: p.inkStrong),
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Supprimer la note',
              icon: Icon(Icons.delete_outline, color: p.inkMuted),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onToggle,
      borderRadius: const BorderRadius.all(Radii.input),
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: recording ? p.danger.withValues(alpha: 0.08) : p.surfaceRaised,
          border: Border.all(
            color: recording ? p.danger : p.lineHair,
            width: recording ? 2 : 1,
          ),
          borderRadius: const BorderRadius.all(Radii.input),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              recording ? Icons.stop_circle_outlined : Icons.mic_none,
              color: recording ? p.danger : p.inkBase,
            ),
            const SizedBox(width: Space.xs),
            Text(
              recording
                  ? 'Enregistrement… touche pour arrêter'
                  : 'Décris le bien à la voix',
              style: AppText.bodyL.copyWith(
                color: recording ? p.danger : p.inkBase,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
