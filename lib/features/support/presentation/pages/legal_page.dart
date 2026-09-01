import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

enum LegalDoc { terms, privacy }

/// Conditions d'utilisation et politique de données.
///
/// Le texte est écrit en phrases courtes, pas en clauses. Un document que
/// personne ne lit n'informe personne — et la loi n° 2017-20 (code du
/// numérique, APDP) demande une information « claire et accessible », pas
/// exhaustive et illisible.
///
/// Chaque section dit d'abord CE QU'ON FAIT, ensuite pourquoi. L'ordre
/// inverse — le juridique d'abord — est celui qu'on utilise quand on préfère
/// ne pas être lu.
class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.doc, super.key});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final terms = doc == LegalDoc.terms;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      appBar: AppBar(
        backgroundColor: p.surfaceBase,
        title: Text(
          terms ? 'Conditions' : 'Politique de données',
          style: AppText.titleM.copyWith(color: p.inkStrong),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(Space.md),
              children: [
                Text(
                  'Dernière mise à jour : 1er septembre 2026',
                  style: AppText.caption.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Space.md),
                for (final s in terms ? _terms : _privacy) _Section(section: s),
                const SizedBox(height: Space.lg),
                Text(
                  terms
                      ? 'EAZYRENT met en relation. Le bail est conclu entre le '
                            'bailleur et le locataire, sous le régime de la loi '
                            'n° 2018-12 portant régime des baux à usage '
                            'd\'habitation.'
                      : 'Responsable de traitement : EAZYRENT, Cotonou, Bénin. '
                            'Autorité de contrôle : APDP (loi n° 2017-20).',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Sec {
  const _Sec(this.title, this.body);
  final String title;
  final String body;
}

const _terms = [
  _Sec(
    'Ce que fait EAZYRENT',
    'Nous publions des biens à louer, nous vérifions certains d\'entre eux sur '
        'place, et nous vendons l\'accès à ces visites vérifiées. Nous ne '
        'sommes ni bailleur ni agence : nous ne signons aucun bail.',
  ),
  _Sec(
    'Ce qu\'une Visite Vérifiée garantit',
    'Qu\'un agent s\'est rendu sur place à la date affichée, a filmé les '
        'pièces en 360° et a constaté que le bien était libre ce jour-là. '
        'Elle ne garantit pas qu\'il le soit encore la semaine suivante — '
        'c\'est pourquoi la date de vérification est écrite sur chaque bien.',
  ),
  _Sec(
    'Ce qu\'on te demande',
    'Des annonces sincères si tu publies : un prix affiché doit être le prix '
        'demandé sur place. Une annonce trompeuse est retirée, et le compte '
        'qui l\'a publiée peut être fermé.',
  ),
  _Sec(
    'Les paiements',
    'Les visites s\'achètent par Mobile Money (MTN MoMo, Moov Flooz, Celtiis '
        'Cash). Un crédit est débité à l\'ouverture de la visite, pas à '
        'l\'achat. Un paiement passé qui n\'ouvre rien est remboursé sous '
        '48 h.',
  ),
  _Sec(
    'Ce que nous ne demanderons jamais',
    'Aucun agent EAZYRENT ne demande de frais de dossier, de caution ni '
        'd\'avance par transfert Mobile Money direct. Si quelqu\'un le fait '
        'en notre nom, signale-le depuis Aide et litige.',
  ),
  _Sec(
    'Fermer son compte',
    'À tout moment, depuis Moi. Les biens que tu as publiés sont retirés, et '
        'tes données sont effacées sous 30 jours — sauf les preuves de '
        'paiement, que la comptabilité impose de conserver.',
  ),
];

const _privacy = [
  _Sec(
    'Ce que nous gardons',
    'Ton numéro de téléphone et ton adresse e-mail pour te connecter et te '
        'prévenir. Tes recherches et tes biens gardés pour te proposer ce qui '
        'te correspond. Tes paiements pour t\'en donner la trace.',
  ),
  _Sec(
    'Ton point d\'ancrage',
    'Le lieu où tu vas tous les jours sert à calculer un temps de trajet. '
        'Nous n\'en gardons que le quartier, jamais une position précise, et '
        'jamais l\'historique de tes déplacements.',
  ),
  _Sec(
    'Ce que nous ne faisons pas',
    'Nous ne vendons ni ne louons tes données. Nous ne transmettons ton '
        'numéro à un bailleur qu\'au moment où TU écris ou demandes un '
        'rendez-vous — jamais avant.',
  ),
  _Sec(
    'Où sont les données',
    'Sur des serveurs hébergés en Europe, chiffrées au repos et en transit. '
        'Les paiements transitent par des prestataires agréés BCEAO ; nous ne '
        'stockons aucune donnée de compte Mobile Money.',
  ),
  _Sec(
    'Tes droits',
    'Accès, rectification, effacement, portabilité. Ils s\'exercent depuis '
        'Moi → Mes données, sans passer par un formulaire ni attendre une '
        'réponse. L\'export arrive par e-mail sous 24 h.',
  ),
  _Sec(
    'Combien de temps',
    'Compte actif : tant que tu l\'utilises. Compte fermé : 30 jours, puis '
        'effacement. Preuves de paiement : 10 ans, obligation comptable.',
  ),
];

class _Section extends StatelessWidget {
  const _Section({required this.section});

  final _Sec section;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppText.titleM.copyWith(color: p.inkStrong),
          ),
          const SizedBox(height: Space.xxs),
          Text(section.body, style: AppText.bodyL.copyWith(color: p.inkBase)),
        ],
      ),
    );
  }
}
