-- =========================================================================
-- MIGRATION_GEO.sql — position exacte d'un bien, sa PROVENANCE, et la photo
-- du portail.
--
-- À exécuter dans l'éditeur SQL Supabase. Idempotent : réexécutable sans
-- risque.
--
-- POURQUOI CE N'EST PAS « juste deux colonnes de plus »
--
-- `listings.latitude` / `longitude` existaient déjà, mais rien ne disait D'OÙ
-- venait le point. Or une épingle posée au doigt depuis un bureau et un relevé
-- GPS pris devant le portail produisent la même paire de nombres, et n'ont
-- pas la même valeur. Les confondre revient à vendre une vérification qu'on
-- n'a pas faite — c'est-à-dire à casser la seule chose que ce produit vend.
-- =========================================================================

-- 1. PROVENANCE ------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'location_source_enum')
  THEN
    CREATE TYPE location_source_enum AS ENUM (
      'gps_onsite',   -- relevé sur place, devant le portail
      'manual_pin',   -- épingle déplacée à la main sur la carte
      'geocoded'      -- déduit d'une adresse, le moins fiable
    );
  END IF;
END $$;

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS location_source location_source_enum,
  -- Précision du relevé, en mètres, telle que rendue par le GPS. Au-delà de
  -- 40 m l'application refuse d'enregistrer : c'est déjà la largeur d'un pâté
  -- de maisons à Fidjrossè, donc de quoi envoyer quelqu'un dans la rue d'à
  -- côté.
  ADD COLUMN IF NOT EXISTS location_accuracy_m REAL,
  ADD COLUMN IF NOT EXISTS location_captured_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS location_captured_by UUID REFERENCES public.profiles(id);

-- 2. PHOTO DU PORTAIL ------------------------------------------------------
--
-- Ce n'est pas une photo de plus dans `listing_media`. Elle a un rôle unique :
-- reconnaître l'entrée en arrivant, dans des quartiers où les rues n'ont
-- souvent ni nom ni numéro. Elle mérite donc sa colonne, pas une ligne
-- perdue dans une galerie triée par `display_order`.
ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS gate_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS gate_photo_captured_at TIMESTAMPTZ,
  -- Coordonnées du téléphone AU MOMENT DU DÉCLENCHEMENT. Si elles s'écartent
  -- de plus de 100 m de la position déclarée du bien, la photo n'a pas été
  -- prise devant ce portail — et ça se vérifie sans se déplacer.
  ADD COLUMN IF NOT EXISTS gate_photo_latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS gate_photo_longitude DOUBLE PRECISION;

-- 3. CE QU'ON PEUT AFFIRMER ------------------------------------------------
--
-- Colonne calculée : un bien est « localisé de façon fiable » quand le relevé
-- a été fait sur place ET qu'il est assez précis. Toute autre combinaison est
-- utilisable mais ne doit jamais porter le badge de vérification.
ALTER TABLE public.listings
  DROP COLUMN IF EXISTS has_verified_location;

ALTER TABLE public.listings
  ADD COLUMN has_verified_location BOOLEAN
  GENERATED ALWAYS AS (
    location_source = 'gps_onsite'
    AND location_accuracy_m IS NOT NULL
    AND location_accuracy_m <= 40
  ) STORED;

-- 4. INDEX -----------------------------------------------------------------
-- Les recherches « autour de moi » passent par location_geom (PostGIS, déjà
-- indexé par le trigger existant). Cet index-ci sert au filtre « seulement
-- les biens dont la position est vérifiée ».
CREATE INDEX IF NOT EXISTS idx_listings_verified_location
  ON public.listings (has_verified_location)
  WHERE has_verified_location = TRUE;

-- 5. LECTURE PUBLIQUE ------------------------------------------------------
--
-- La position et sa provenance sont PUBLIQUES par conception, comme la
-- fraîcheur : c'est la preuve que le produit vend. Une donnée de confiance
-- cachée derrière une authentification ne convainc personne.
--
-- ⚠️ Ne JAMAIS étendre cette logique à `virtual_tour_scenes` : les panoramas
-- restent derrière l'Edge Function (CONSTITUTION P4).

COMMENT ON COLUMN public.listings.location_source IS
  'D''où vient le point. gps_onsite = relevé devant le portail. '
  'Ne jamais présenter manual_pin ou geocoded comme une vérification.';

COMMENT ON COLUMN public.listings.gate_photo_url IS
  'Photo du portail, prise à la caméra sur place. Sert à reconnaître '
  'l''entrée : ici beaucoup de rues n''ont ni nom ni numéro.';
