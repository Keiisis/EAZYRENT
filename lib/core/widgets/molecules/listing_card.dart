import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../features/listing/domain/entities/listing.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../utils/money_fcfa.dart';

/// Le composant le plus vu de l'application (UI_SCREENS_SPEC.md §9.1).
///
/// CONTRAINTE STRUCTURANTE : hauteur fixe à [Sizes.listingCardHeight]. C'est
/// elle qui permet 4 biens sur un écran de 6,1 pouces — et elle autorise un
/// `itemExtent` fixe, donc aucun saut de mise en page au chargement.
///
/// ORDRE DE LECTURE IMPOSÉ : prix → type et quartier → fraîcheur →
/// coût d'entrée → trajet. La photo est en dernier dans la hiérarchie : elle
/// sert à disqualifier vite, pas à décider.
class ListingCard extends StatelessWidget {
  const ListingCard({
    required this.listing,
    required this.onTap,
    this.onSave,
    this.isSaved = false,
    super.key,
  });

  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback? onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label:
          '${listing.propertyType} à ${listing.locationLabel}, '
          '${MoneyFcfa.short(listing.monthlyRentFcfa)} par mois. '
          '${listing.freshness.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radii.card),
        child: SizedBox(
          height: Sizes.listingCardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(listing: listing, palette: p),
              const SizedBox(width: Space.sm),
              Expanded(
                child: _Body(listing: listing, palette: p),
              ),
              _SaveButton(isSaved: isSaved, onSave: onSave, palette: p),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.listing, required this.palette});

  final Listing listing;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Sizes.listingThumbWidth,
      height: Sizes.listingCardHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radii.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (listing.mainImageUrl != null)
              CachedNetworkImage(
                imageUrl: listing.mainImageUrl!,
                fit: BoxFit.cover,
                // Un bien sans photo affiche un aplat avec le type en toutes
                // lettres — jamais une icône d'image cassée (état `partial`).
                errorWidget: (_, _, _) =>
                    _NoPhoto(listing: listing, palette: palette),
                placeholder: (_, _) => ColoredBox(color: palette.surfaceSunken),
              )
            else
              _NoPhoto(listing: listing, palette: palette),

            if (listing.hasVerifiedTour)
              Positioned(
                left: Space.xs,
                bottom: Space.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Accents.infoVivid,
                    borderRadius: const BorderRadius.all(Radii.chip),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '360',
                      style: TextStyle(
                        fontFamily: Fonts.body,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Color(0xFF0B0F19),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoPhoto extends StatelessWidget {
  const _NoPhoto({required this.listing, required this.palette});

  final Listing listing;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: palette.surfaceSunken,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xs),
        child: Text(
          listing.propertyType,
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: palette.inkMuted),
        ),
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.listing, required this.palette});

  final Listing listing;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final freshColor = switch (listing.freshness.tone) {
      FreshnessTone.ok => palette.success,
      FreshnessTone.warn => palette.warn,
      FreshnessTone.stale => palette.inkMuted,
    };
    // La couleur ne porte jamais seule l'information : couleur + icône + mot.
    final freshIcon = switch (listing.freshness.tone) {
      FreshnessTone.ok => Icons.check_circle,
      FreshnessTone.warn => Icons.schedule,
      FreshnessTone.stale => Icons.help_outline,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Le prix — l'élément le plus visible.
        Text.rich(
          TextSpan(
            text: MoneyFcfa.short(listing.monthlyRentFcfa),
            style: AppText.amount.copyWith(color: palette.inkStrong),
            children: [
              TextSpan(
                text: ' /mois',
                style: AppText.bodyM.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 2. Type et quartier.
        Text(
          '${listing.propertyType} · ${listing.locationLabel}',
          style: AppText.bodyM.copyWith(color: palette.inkBase),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 3. Fraîcheur — la promesse du produit, sur la carte.
        Row(
          children: [
            Icon(freshIcon, size: 13, color: freshColor),
            const SizedBox(width: Space.xxs),
            Expanded(
              child: Text(
                listing.freshness.label,
                style: AppText.label.copyWith(color: freshColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // 4. Le coût d'entrée — le chiffre qui élimine 80 % des biens.
        if (listing.totalMoveInCostFcfa != null)
          Text(
            'Entrée : ${MoneyFcfa.short(listing.totalMoveInCostFcfa!)}'
            '${listing.advanceMonths != null ? " · ${listing.advanceMonths} mois av." : ""}',
            style: AppText.bodyM.copyWith(
              color: palette.inkStrong,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

        // 5. Trajet — n'apparaît que si le point d'ancrage est renseigné.
        if (listing.commuteMinutes != null)
          Text(
            '~${listing.commuteMinutes} min de ton travail',
            style: AppText.label.copyWith(color: palette.inkMuted),
            maxLines: 1,
          ),

        if (listing.isSponsored)
          Text(
            'Sponsorisé',
            style: AppText.caption.copyWith(color: palette.inkMuted),
          ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaved,
    required this.onSave,
    required this.palette,
  });

  final bool isSaved;
  final VoidCallback? onSave;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final target = Touch.target(palette.isHighContrast);
    return SizedBox(
      width: target,
      height: Sizes.listingCardHeight,
      child: IconButton(
        onPressed: onSave,
        iconSize: 22,
        // Étiquette sémantique obligatoire : une icône seule est muette
        // pour TalkBack (UI_DESIGN_SYSTEM §11).
        tooltip: isSaved ? 'Retirer de ma liste' : 'Garder ce bien',
        icon: Icon(
          isSaved ? Icons.favorite : Icons.favorite_border,
          color: isSaved ? palette.action : palette.inkMuted,
        ),
      ),
    );
  }
}
