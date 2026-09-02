import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../listing/presentation/pages/capture_location_page.dart';

/// C7 — Publier un bien.
///
/// UN SEUL écran défilant, pas un assistant en cinq étapes. Un propriétaire
/// saisit souvent debout, dans sa cour, sur un téléphone d'entrée de gamme :
/// chaque écran supplémentaire est une occasion d'abandonner.
///
/// Le COÛT TOTAL D'ENTRÉE se calcule en direct sous ses yeux. C'est le chiffre
/// que verra le chercheur, et le lui montrer pendant la saisie est ce qui
/// évite les annonces au prix affiché mais au coût d'entrée insoutenable.
class PublishListingScreen extends StatefulWidget {
  const PublishListingScreen({super.key});

  @override
  State<PublishListingScreen> createState() => _PublishListingScreenState();
}

class _PublishListingScreenState extends State<PublishListingScreen> {
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
  static const _types = [
    'Chambre',
    'Chambre-salon',
    '2 chambres-salon',
    'Appartement',
    'Boutique',
  ];

  String? _neighborhood;
  String? _type;
  final _rent = TextEditingController();
  int _advanceMonths = 2;
  bool _priceFirm = false;

  /// Facultative. Un bien sans position se loue ; un bien qu'on ne trouve
  /// pas ne se visite pas. On propose, on n'impose pas.
  CapturedLocation? _location;

  int get _rentValue =>
      int.tryParse(_rent.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  /// Avance + caution (1 mois) + frais (2 mois de pratique courante).
  int get _moveInCost =>
      _rentValue * _advanceMonths + _rentValue + _rentValue * 2;

  bool get _canPublish =>
      _neighborhood != null && _type != null && _rentValue >= 5000;

  String? get _blockedReason {
    if (_type == null) return 'Choisis le type de logement';
    if (_neighborhood == null) return 'Choisis le quartier';
    if (_rentValue < 5000) return 'Entre le loyer mensuel';
    return null;
  }

  @override
  void dispose() {
    _rent.dispose();
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
          'Publier un logement',
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
                _Label('Type de logement'),
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
                _Label('Loyer mensuel'),
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
                _Label("Mois d'avance demandés"),
                _Chips(
                  options: const ['1', '2', '3', '6', '12'],
                  selected: '$_advanceMonths',
                  onSelect: (v) =>
                      setState(() => _advanceMonths = int.parse(v)),
                ),

                // Encadré juridique SANS chiffre. La loi n°2018-12 encadre
                // l'avance, mais le plafond exact n'a PAS été confirmé par un
                // conseil juridique béninois (GATES.md G8). On informe de
                // l'existence de la règle ; on n'invente pas son contenu.
                const SizedBox(height: Space.sm),
                Container(
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: const BorderRadius.all(Radii.input),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.gavel_outlined, size: 16, color: p.inkMuted),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          "L'avance et la caution sont encadrées par la loi "
                          'n°2018-12 sur le bail d\'habitation.',
                          style: AppText.bodyM.copyWith(color: p.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Space.lg),
                _CostPreview(
                  rent: _rentValue,
                  advanceMonths: _advanceMonths,
                  total: _moveInCost,
                ),

                // La position exacte, AVANT « prix ferme ».
                //
                // Un bien sans position se loue quand même — c'est pour ça
                // qu'elle n'est pas obligatoire. Mais elle est proposée ici,
                // dans le flux, et pas reléguée dans un écran d'édition que
                // personne n'ouvre : un bailleur qui publie depuis chez lui
                // est PRÉCISÉMENT la personne bien placée pour relever.
                const SizedBox(height: Space.lg),
                _LocationRow(
                  captured: _location,
                  onCapture: () async {
                    final res = await Navigator.of(context)
                        .push<CapturedLocation>(
                          MaterialPageRoute<CapturedLocation>(
                            builder: (_) => CaptureLocationScreen(
                              initial: _location?.point,
                            ),
                          ),
                        );
                    if (res != null) setState(() => _location = res);
                  },
                ),

                const SizedBox(height: Space.md),
                SwitchListTile(
                  value: _priceFirm,
                  onChanged: (v) => setState(() => _priceFirm = v),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Prix ferme',
                    style: AppText.bodyL.copyWith(color: p.inkStrong),
                  ),
                  subtitle: Text(
                    "Tu t'engages sur ce montant. Les biens à prix ferme "
                    'reçoivent plus de demandes sérieuses.',
                    style: AppText.bodyM.copyWith(color: p.inkMuted),
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
          boxShadow: p.shadowBar,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canPublish ? () {} : null,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, Touch.target(p.isHighContrast) + 8),
                  ),
                  child: const Text('Publier — gratuit'),
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

/// Le chiffre que verra le chercheur, montré au propriétaire pendant qu'il
/// saisit. C'est ce qui évite les annonces au loyer attractif et au coût
/// d'entrée insoutenable — celles qui font perdre du temps aux deux parties.
class _CostPreview extends StatelessWidget {
  const _CostPreview({
    required this.rent,
    required this.advanceMonths,
    required this.total,
  });

  final int rent;
  final int advanceMonths;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (rent < 5000) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        border: Border.all(color: p.lineHair, width: p.borderWidth),
        borderRadius: const BorderRadius.all(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CE QUE LE LOCATAIRE DEVRA SORTIR',
            style: AppText.label.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.sm),
          _Line(
            label: 'Avance $advanceMonths mois',
            amount: rent * advanceMonths,
          ),
          _Line(label: 'Caution 1 mois', amount: rent),
          _Line(label: 'Frais', amount: rent * 2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Divider(color: p.lineHair, height: 1),
          ),
          _Line(label: 'Total', amount: total, strong: true),
          const SizedBox(height: Space.xs),
          Text(
            "C'est ce chiffre que voit le chercheur, avant même le loyer.",
            style: AppText.caption.copyWith(color: p.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.amount, this.strong = false});

  final String label;
  final int amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.bodyL.copyWith(
                color: strong ? p.inkStrong : p.inkMuted,
                fontWeight: strong ? FontWeight.w600 : null,
              ),
            ),
          ),
          Text(
            MoneyFcfa.short(amount),
            style: strong
                ? AppText.amount.copyWith(color: p.inkStrong)
                : AppText.bodyL.copyWith(
                    color: p.inkBase,
                    fontFeatures: Fonts.tabular,
                  ),
          ),
        ],
      ),
    );
  }
}

/// La ligne « position » du formulaire de publication.
///
/// Elle dit CE QU'ON A, pas ce qu'il faudrait avoir. Trois états, trois
/// phrases différentes : rien, épingle à la main, relevé sur place. Le
/// troisième est le seul qui donne droit au badge — et l'écart entre les
/// deux derniers est écrit, pas suggéré.
class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.captured, required this.onCapture});

  final CapturedLocation? captured;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = captured;

    final (icon, title, body, tone) = switch (c?.source) {
      null => (
        Icons.location_off_outlined,
        'Position non renseignée',
        'Sans elle, personne ne peut se faire guider jusqu\'au portail.',
        p.inkMuted,
      ),
      LocationSource.gpsOnsite => (
        Icons.gps_fixed,
        'Relevé sur place · ± ${c!.accuracyMeters?.round() ?? "?"} m',
        c.placeLabel ?? 'Position vérifiable.',
        p.success,
      ),
      LocationSource.manualPin => (
        Icons.push_pin_outlined,
        'Épingle placée à la main',
        'Utilisable, mais le bien ne portera pas le badge de position '
            'vérifiée.',
        p.warn,
      ),
      LocationSource.geocoded => (
        Icons.travel_explore,
        'Déduite de l\'adresse',
        'La moins fiable des trois.',
        p.warn,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: const BorderRadius.all(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: tone),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppText.bodyL.copyWith(
                    color: p.inkStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (c?.gatePhoto != null)
                Icon(Icons.photo_camera, size: 18, color: p.success),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Text(body, style: AppText.bodyM.copyWith(color: p.inkMuted)),
          const SizedBox(height: Space.xs),
          OutlinedButton.icon(
            onPressed: onCapture,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, Touch.target(p.isHighContrast)),
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: Text(c == null ? 'Placer le bien' : 'Corriger'),
          ),
        ],
      ),
    );
  }
}
