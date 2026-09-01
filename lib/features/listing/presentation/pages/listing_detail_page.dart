import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money_fcfa.dart';
import '../../../navigation/presentation/pages/navigation_page.dart';
import '../../../tour/presentation/pages/tour_preview_page.dart';
import '../../../visit/presentation/pages/booking_page.dart';
import '../../domain/entities/listing.dart';
import 'report_listing_page.dart';

/// S05 — Fiche de bien.
///
/// HIÉRARCHIE IMPOSÉE : le bloc « Ce que tu paies pour entrer » est le
/// DEUXIÈME de l'écran, avant les caractéristiques. C'est lui qui décide.
///
/// UN SEUL bouton terracotta : « Visiter en 360° ». « Demander RDV » est
/// secondaire — on visite d'abord, on se déplace ensuite. Toute la thèse du
/// produit tient dans cette hiérarchie de boutons.
class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({
    required this.listing,
    this.agentName,
    this.agentAvatarUrl,
    super.key,
  });

  final Listing listing;

  /// « Vérifié par Rachid » bat n'importe quel badge logotypé : on fait
  /// confiance à une personne, pas à un tampon.
  final String? agentName;
  final String? agentAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: CustomScrollView(
        slivers: [
          _Header(listing: listing),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              Space.md,
              Space.md,
              120,
            ),
            sliver: SliverList.list(
              children: [
                _Price(listing: listing),
                const SizedBox(height: Space.md),
                _Trust(
                  listing: listing,
                  agentName: agentName,
                  agentAvatarUrl: agentAvatarUrl,
                ),
                const SizedBox(height: Space.lg),
                _MoveInCost(listing: listing),
                const SizedBox(height: Space.lg),
                _Essentials(listing: listing),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(listing: listing),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: p.surfaceBase,
      leading: _RoundIcon(
        icon: Icons.arrow_back,
        tooltip: 'Retour',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        const _RoundIcon(
          icon: Icons.favorite_border,
          tooltip: 'Garder ce bien',
        ),
        // Le partage est de PREMIER RANG, pas dans un menu à trois points :
        // WhatsApp est le canal d'acquisition n°1 du produit.
        const _RoundIcon(icon: Icons.share, tooltip: 'Partager'),
        // « Y aller » n'apparaît QUE si le bien a des coordonnées : proposer
        // un guidage vers un point inconnu enverrait quelqu'un nulle part.
        if (listing.hasCoordinates)
          _RoundIcon(
            icon: Icons.near_me,
            tooltip: 'Y aller',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NavigationScreen(
                  destination: LatLng(listing.latitude!, listing.longitude!),
                  destinationLabel:
                      '${listing.propertyType} · '
                      '${listing.neighborhood ?? listing.city}',
                ),
              ),
            ),
          ),
        // « Plus libre ? » est une ACTION DE PREMIER RANG, pas un lien de
        // bas de page : c'est ce signalement qui tient la fraîcheur du parc.
        _RoundIcon(
          icon: Icons.flag_outlined,
          tooltip: 'Ce bien n\'est plus libre',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReportListingScreen(
                listingTitle:
                    '${listing.propertyType} · '
                    '${listing.neighborhood ?? listing.city}',
                tourWasPaid: listing.hasVerifiedTour,
              ),
            ),
          ),
        ),
        SizedBox(width: Space.xs),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (listing.mainImageUrl != null)
              CachedNetworkImage(
                imageUrl: listing.mainImageUrl!,
                fit: BoxFit.cover,
              )
            else
              ColoredBox(color: p.surfaceSunken),
            if (listing.hasVerifiedTour)
              Positioned(
                left: 0,
                right: 0,
                bottom: Space.md,
                child: Center(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TourPreviewScreen(listing: listing, roomsTotal: 6),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Accents.infoVivid,
                      foregroundColor: const Color(0xFF0B0F19),
                      minimumSize: const Size(0, Touch.min),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Visiter en 360°'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Space.xs),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed ?? () {},
        tooltip: tooltip,
        icon: Icon(icon, color: const Color(0xFF0B0F19), size: 20),
      ),
    ),
  );
}

class _Price extends StatelessWidget {
  const _Price({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: MoneyFcfa.short(listing.monthlyRentFcfa),
            style: AppText.displayM.copyWith(color: p.inkStrong),
            children: [
              TextSpan(
                text: ' /mois',
                style: AppText.bodyL.copyWith(color: p.inkMuted),
              ),
            ],
          ),
        ),
        Text(
          '${listing.propertyType} · ${listing.locationLabel}, ${listing.city}',
          style: AppText.bodyL.copyWith(color: p.inkBase),
        ),
      ],
    );
  }
}

/// Le bloc de confiance : un humain identifiable, avec son prénom et sa photo.
class _Trust extends StatelessWidget {
  const _Trust({
    required this.listing,
    required this.agentName,
    required this.agentAvatarUrl,
  });

  final Listing listing;
  final String? agentName;
  final String? agentAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (listing.freshness.tone) {
      FreshnessTone.ok => p.success,
      FreshnessTone.warn => p.warn,
      FreshnessTone.stale => p.inkMuted,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.verified, size: 18, color: color),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.freshness.label,
                style: AppText.bodyL.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (agentName != null)
                Text(
                  'par $agentName, agent EAZYRENT',
                  style: AppText.bodyM.copyWith(color: p.inkMuted),
                ),
            ],
          ),
        ),
        if (agentAvatarUrl != null)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: agentAvatarUrl!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }
}

/// Deuxième bloc de l'écran, avant les caractéristiques. Chiffres tabulaires,
/// alignés à droite, total en gras.
class _MoveInCost extends StatelessWidget {
  const _MoveInCost({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (listing.totalMoveInCostFcfa == null) return const SizedBox.shrink();

    final rent = listing.monthlyRentFcfa;
    final months = listing.advanceMonths ?? 0;
    final advance = rent * months;
    final deposit = rent;
    final fees = listing.totalMoveInCostFcfa! - advance - deposit;

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        border: Border.all(color: p.lineHair),
        borderRadius: const BorderRadius.all(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CE QUE TU PAIES POUR ENTRER',
            style: AppText.label.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.sm),
          if (months > 0) _Line(label: 'Avance $months mois', amount: advance),
          _Line(label: 'Caution 1 mois', amount: deposit),
          if (fees > 0) _Line(label: 'Frais', amount: fees),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Divider(color: p.lineHair, height: 1),
          ),
          _Line(
            label: 'Total',
            amount: listing.totalMoveInCostFcfa!,
            strong: true,
          ),
          if (listing.totalMoveInCostFcfa != null) ...[
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: p.inkMuted),
                const SizedBox(width: Space.xxs),
                Expanded(
                  child: Text(
                    'Prix ferme, engagement du propriétaire',
                    style: AppText.caption.copyWith(color: p.inkMuted),
                  ),
                ),
              ],
            ),
          ],
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
    final style = strong
        ? AppText.amount.copyWith(color: p.inkStrong)
        : AppText.bodyL.copyWith(color: p.inkBase, fontFeatures: Fonts.tabular);
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
          Text(MoneyFcfa.short(amount), style: style),
        ],
      ),
    );
  }
}

class _Essentials extends StatelessWidget {
  const _Essentials({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("L'ESSENTIEL", style: AppText.label.copyWith(color: p.inkMuted)),
        const SizedBox(height: Space.sm),
        if (listing.commuteMinutes != null)
          _Row(
            icon: Icons.directions_walk,
            text: '~${listing.commuteMinutes} min de ton travail',
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: p.inkBase),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(text, style: AppText.bodyL.copyWith(color: p.inkBase)),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.md,
      ),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        boxShadow: Elevation.stickyBar,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 4 contre 5, et non 1 contre 2.
            //
            // MESURÉ sur un écran de 384 dp : la barre dispose de 340 dp une
            // fois les marges retirées. À 1:2, « Demander RDV » recevait
            // 113 dp pour un libellé qui en demande 137 — il se coupait au
            // milieu du mot, en « Demande / r RDV ». À 4:5, il obtient
            // 151 dp et tient sur une ligne, sans que « Visiter en 360° »
            // cesse d'être le bouton dominant.
            Expanded(
              flex: 4,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BookingScreen(
                      listingTitle:
                          '${listing.propertyType} · '
                          '${listing.neighborhood ?? listing.city}',
                      // La phrase de succès change selon qu'on a vu le bien
                      // en 360 ou non : « tu sais déjà tout » ne se dit pas
                      // à quelqu'un qui n'a rien vu.
                      tourDone: listing.hasVerifiedTour,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, Touch.target(p.isHighContrast)),
                ),
                child: const Text('Demander RDV'),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              flex: 5,
              // LE seul bouton terracotta de l'écran.
              child: FilledButton.icon(
                onPressed: listing.hasVerifiedTour
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TourPreviewScreen(
                            listing: listing,
                            roomsTotal: 6,
                          ),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  listing.hasVerifiedTour
                      ? 'Visiter en 360°'
                      : 'Demander une visite 360',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
