-- ============================================================================
-- EAZYRENT - Schéma de Base de Données PostgreSQL / Supabase
-- Version : 2.0.0 - Révisé après AUDIT_COHERENCE_BENIN.md
-- Marché : Bénin (Grand Nokoué)
-- Extensions requises : uuid-ossp, postgis
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 1. ENUMS
-- broker      = démarcheur partenaire (apporteur d'affaires) - cf. PRD 2.4
-- field_agent = agent de terrain EAZYRENT qui tourne les visites 360
CREATE TYPE user_role AS ENUM ('tenant', 'owner', 'agency', 'broker', 'field_agent', 'admin');
CREATE TYPE kyc_status_enum AS ENUM ('not_submitted', 'pending_review', 'verified', 'rejected');
CREATE TYPE listing_type_enum AS ENUM ('rent_long_term', 'rent_short_term', 'sale');
CREATE TYPE property_type_enum AS ENUM ('room', 'apartment', 'villa_house', 'land', 'commercial');
CREATE TYPE electricity_meter_enum AS ENUM ('prepaid_card', 'conventional_postpaid', 'shared_submeter', 'none');
CREATE TYPE water_supply_enum AS ENUM ('public_network_running', 'private_borehole', 'water_tower_tank', 'none');
CREATE TYPE escrow_status_enum AS ENUM ('pending_payment', 'held_in_escrow', 'released_to_owner', 'disputed', 'refunded_to_tenant');
CREATE TYPE inspection_type_enum AS ENUM ('check_in', 'check_out');

-- 2. PROFILES (Extends auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'tenant',
    full_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(30) UNIQUE NOT NULL,
    email VARCHAR(150),
    avatar_url TEXT,
    kyc_status kyc_status_enum NOT NULL DEFAULT 'not_submitted',
    id_card_url TEXT,
    property_title_url TEXT,
    is_phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    preferred_language VARCHAR(5) NOT NULL DEFAULT 'fr',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. AGENCIES (Informations professionnelles des agences)
CREATE TABLE public.agencies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    agency_name VARCHAR(200) NOT NULL,
    rccm_number VARCHAR(100) NOT NULL,
    tax_id_number VARCHAR(100),
    official_address TEXT NOT NULL,
    logo_url TEXT,
    commission_rate NUMERIC(5,2) DEFAULT 10.00,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. LISTINGS (Annonces Immobilières)
CREATE TABLE public.listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    agency_id UUID REFERENCES public.agencies(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    listing_type listing_type_enum NOT NULL DEFAULT 'rent_long_term',
    property_type property_type_enum NOT NULL,
    
    -- Tarifs (en FCFA / XOF)
    price_amount NUMERIC(12,2) NOT NULL,
    deposit_amount NUMERIC(12,2) DEFAULT 0,
    agency_fees NUMERIC(12,2) DEFAULT 0,
    
    -- Caractéristiques
    bedrooms_count INT DEFAULT 1,
    bathrooms_count INT DEFAULT 1,
    surface_sqm NUMERIC(8,2),
    
    -- Conditions financières affichées en clair (critère de tri n°1 au Bénin)
    advance_months INT DEFAULT 0,          -- Nombre de mois d'avance exigés par le bailleur
    total_move_in_cost NUMERIC(12,2),      -- avance + caution + frais, calculé et affiché
    is_price_firm BOOLEAN NOT NULL DEFAULT FALSE, -- Le bailleur s'engage sur le prix affiché

    -- Spécificités Bénin
    electricity_meter electricity_meter_enum NOT NULL DEFAULT 'prepaid_card', -- SBEE : compteur à carte / post-payé / sous-compteur partagé
    submeter_kwh_price NUMERIC(8,2),       -- Prix du kWh revendu si sous-compteur (source de litige majeure : à afficher)
    water_supply water_supply_enum NOT NULL DEFAULT 'public_network_running', -- SONEB / forage / château / aucun
    is_flood_prone BOOLEAN DEFAULT FALSE,  -- Zone inondable en saison des pluies (critère décisif Cotonou / Godomey)
    is_paved_access BOOLEAN DEFAULT FALSE, -- Voie bitumée vs latéritique
    has_generator BOOLEAN DEFAULT FALSE,
    has_security_guard BOOLEAN DEFAULT FALSE,
    has_air_conditioning BOOLEAN DEFAULT FALSE,
    has_water_heater BOOLEAN DEFAULT FALSE,
    is_furnished BOOLEAN DEFAULT FALSE,
    -- Référentiel foncier béninois (Code foncier et domanial 2013-01 mod. 2017) :
    -- 'cpf_andf' (Certificat de Propriété Foncière - seul titre définitif),
    -- 'titre_foncier_ancien', 'attestation_recasement', 'convention_vente', 'permis_habiter'
    land_title_type VARCHAR(100),

    -- Localisation & PostGIS
    address TEXT NOT NULL,
    neighborhood VARCHAR(150),
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'Bénin',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_geom GEOMETRY(Point, 4326),
    
    -- Médias
    virtual_tour_360_url TEXT,
    main_image_url TEXT,
    
    -- Statut
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. LISTING MEDIA (Photos et Vidéos standards)
CREATE TABLE public.listing_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type VARCHAR(20) NOT NULL DEFAULT 'image', -- image, video
    display_order INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5.1 VIRTUAL TOUR SCENES (Scènes 360 multi-pièces certifiées par EAZYRENT)
CREATE TABLE public.virtual_tour_scenes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    scene_name VARCHAR(100) NOT NULL, -- Ex: Salon principal, Chambre parentale, Terrasse
    panorama_url TEXT NOT NULL, -- Image équirectangulaire haute résolution WebP/JPEG
    initial_yaw DOUBLE PRECISION DEFAULT 0.0,
    initial_pitch DOUBLE PRECISION DEFAULT 0.0,
    display_order INT DEFAULT 0,
    captured_by_agent_id UUID REFERENCES public.profiles(id), -- Agent de terrain EAZYRENT
    is_eazyrent_certified BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5.2 VIRTUAL TOUR HOTSPOTS (Points de passage entre les pièces)
CREATE TABLE public.virtual_tour_hotspots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_scene_id UUID NOT NULL REFERENCES public.virtual_tour_scenes(id) ON DELETE CASCADE,
    target_scene_id UUID NOT NULL REFERENCES public.virtual_tour_scenes(id) ON DELETE CASCADE,
    yaw DOUBLE PRECISION NOT NULL,
    pitch DOUBLE PRECISION NOT NULL,
    tooltip_text VARCHAR(100) NOT NULL DEFAULT 'Aller vers cette pièce'
);

-- 5.3 VIRTUAL TOUR ACCESS PASSES (Pass Visite Vérifiée 100% EAZYRENT - 1 000 FCFA)
-- L'accès est PERMANENT tant que l'annonce est en ligne, et téléchargeable hors-ligne.
-- La validité 48h de la v1.0 est supprimée : punitive et génératrice de litiges.
CREATE TABLE public.virtual_tour_access_passes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    amount_paid NUMERIC(10,2) NOT NULL DEFAULT 1000.00,
    eazyrent_net_revenue NUMERIC(10,2) NOT NULL DEFAULT 1000.00, -- 100% perçu par EAZYRENT
    -- Opérateurs réellement disponibles au Bénin. Ni Wave ni Orange n'y opèrent.
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('mtn_momo','moov_flooz','celtiis_cash','card','credit','free_first_visit','weekly_gift')),
    payment_transaction_ref VARCHAR(100) UNIQUE,
    source VARCHAR(30) NOT NULL DEFAULT 'purchase', -- purchase | free_first_visit | weekly_gift | credit_pack | refund
    refunded_at TIMESTAMPTZ,                        -- Remboursement auto en crédit si le bien devient indisponible
    revoked_at TIMESTAMPTZ,                         -- Annonce retirée : l'accès cesse
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5.4 VISIT CREDITS (packs multi-visites promis par le PRD, absents de la v1.0)
CREATE TABLE public.visit_credits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    credits_total INT NOT NULL,
    credits_remaining INT NOT NULL,
    amount_paid NUMERIC(10,2) NOT NULL DEFAULT 0,
    origin VARCHAR(30) NOT NULL, -- pack_3 | pack_7 | referral | weekly_gift | refund | support
    payment_transaction_ref VARCHAR(100),
    expires_at TIMESTAMPTZ,      -- 90 jours pour les packs, NULL pour les remboursements
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT credits_remaining_valid CHECK (credits_remaining >= 0 AND credits_remaining <= credits_total)
);

-- 5.5 AVAILABILITY CHECKS (LA table qui matérialise la promesse produit)
-- Sans elle, EAZYRENT vend la visite d'un bien peut-être déjà loué :
-- exactement le grief adressé au démarcheur.
CREATE TABLE public.availability_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    checked_by UUID NOT NULL REFERENCES public.profiles(id), -- agent terrain, bailleur ou apporteur
    is_still_available BOOLEAN NOT NULL,
    check_method VARCHAR(30) NOT NULL, -- call | visit | owner_confirm | app_confirm
    notes TEXT,
    checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. VISIT BOOKINGS (Prise de rendez-vous de visite)
CREATE TABLE public.visit_bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    requested_datetime TIMESTAMPTZ NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'pending', -- pending, confirmed, completed, cancelled
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. ESCROW ACCOUNTS & TRANSACTIONS (Séquestre Financier)
CREATE TABLE public.escrow_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id),
    tenant_id UUID NOT NULL REFERENCES public.profiles(id),
    owner_id UUID NOT NULL REFERENCES public.profiles(id),
    
    -- Montants
    total_paid_amount NUMERIC(12,2) NOT NULL,
    first_rent_amount NUMERIC(12,2) NOT NULL,
    deposit_amount NUMERIC(12,2) NOT NULL,
    platform_commission_fee NUMERIC(12,2) NOT NULL,
    net_owner_amount NUMERIC(12,2) NOT NULL,
    
    -- Passerelle Mobile Money
    payment_gateway VARCHAR(50) NOT NULL, -- cinetpay, paystack, wave
    gateway_transaction_id VARCHAR(150),
    payment_phone_number VARCHAR(30),
    
    -- Statut du Séquestre
    status escrow_status_enum NOT NULL DEFAULT 'pending_payment',
    funds_locked_at TIMESTAMPTZ,
    funds_released_at TIMESTAMPTZ,
    dispute_reason TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. INSPECTIONS (États des Lieux d'Entrée / Sortie)
CREATE TABLE public.inspections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    escrow_transaction_id UUID REFERENCES public.escrow_transactions(id),
    listing_id UUID NOT NULL REFERENCES public.listings(id),
    tenant_id UUID NOT NULL REFERENCES public.profiles(id),
    owner_id UUID NOT NULL REFERENCES public.profiles(id),
    
    inspection_type inspection_type_enum NOT NULL DEFAULT 'check_in',
    inspection_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    general_observations TEXT,
    tenant_signature_url TEXT,
    owner_signature_url TEXT,
    is_signed_by_tenant BOOLEAN NOT NULL DEFAULT FALSE,
    is_signed_by_owner BOOLEAN NOT NULL DEFAULT FALSE,
    
    pdf_report_url TEXT,
    sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. INSPECTION ROOMS & PHOTOS
CREATE TABLE public.inspection_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inspection_id UUID NOT NULL REFERENCES public.inspections(id) ON DELETE CASCADE,
    room_name VARCHAR(100) NOT NULL, -- Ex: Salon, Chambre 1, Cuisine, Salle d'eau
    condition_rating VARCHAR(30) NOT NULL, -- Excellent, Bon, Moyen, Dégradé
    notes TEXT
);

CREATE TABLE public.inspection_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inspection_room_id UUID NOT NULL REFERENCES public.inspection_rooms(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    photo_sha256_hash VARCHAR(64),
    captured_latitude DOUBLE PRECISION,
    captured_longitude DOUBLE PRECISION,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. LEASE CONTRACTS & RENT PAYMENTS (Baux et Quittances)
CREATE TABLE public.lease_contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id),
    tenant_id UUID NOT NULL REFERENCES public.profiles(id),
    owner_id UUID NOT NULL REFERENCES public.profiles(id),
    start_date DATE NOT NULL,
    end_date DATE,
    monthly_rent_amount NUMERIC(12,2) NOT NULL,
    security_deposit_held NUMERIC(12,2) NOT NULL,
    contract_pdf_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.rent_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lease_id UUID NOT NULL REFERENCES public.lease_contracts(id) ON DELETE CASCADE,
    payer_id UUID NOT NULL REFERENCES public.profiles(id),
    amount_paid NUMERIC(12,2) NOT NULL,
    rent_period_month DATE NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_ref VARCHAR(100) UNIQUE NOT NULL,
    quittance_pdf_url TEXT,
    paid_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. CHAT MESSAGING (Temps Réel)
CREATE TABLE public.chat_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID REFERENCES public.listings(id),
    participant_one UUID NOT NULL REFERENCES public.profiles(id),
    participant_two UUID NOT NULL REFERENCES public.profiles(id),
    last_message_preview TEXT,
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.chat_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    message_text TEXT NOT NULL,
    attachment_url TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- INDEX (aucun n'existait en v1.0 - la recherche spatiale était inexploitable)
-- ============================================================================
CREATE INDEX idx_listings_geom          ON public.listings USING GIST (location_geom);
CREATE INDEX idx_listings_search        ON public.listings (city, neighborhood, listing_type, is_available, price_amount);
CREATE INDEX idx_listings_fresh         ON public.listings (created_at DESC) WHERE is_available = true;
CREATE INDEX idx_media_listing          ON public.listing_media (listing_id, display_order);
CREATE INDEX idx_scenes_listing         ON public.virtual_tour_scenes (listing_id, display_order);
CREATE UNIQUE INDEX idx_pass_unique     ON public.virtual_tour_access_passes (tenant_id, listing_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_availability_recent    ON public.availability_checks (listing_id, checked_at DESC);
CREATE INDEX idx_escrow_parties         ON public.escrow_transactions (tenant_id, owner_id, status);
CREATE INDEX idx_rent_payments_lease    ON public.rent_payments (lease_id, rent_period_month DESC);
CREATE INDEX idx_messages_conversation  ON public.chat_messages (conversation_id, sent_at DESC);

-- ============================================================================
-- TRIGGERS (location_geom n'était jamais alimenté, updated_at jamais mis à jour)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.sync_listing_geom() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location_geom := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    END IF;
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_listings_geom BEFORE INSERT OR UPDATE ON public.listings
FOR EACH ROW EXECUTE FUNCTION public.sync_listing_geom();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.profiles                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_transactions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspections                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lease_contracts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages               ENABLE ROW LEVEL SECURITY;
-- Ajouts v2.0 : sans ces trois lignes, le paywall à 1 000 F est contournable
-- en lisant panorama_url via l'API PostgREST.
ALTER TABLE public.virtual_tour_scenes         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.virtual_tour_hotspots       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.virtual_tour_access_passes  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_credits               ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- Profiles : la politique v1.0 `USING (true)` exposait le numéro de téléphone
-- de TOUS les utilisateurs. Sur ce marché, cela permet à un démarcheur
-- d'aspirer la base des chercheurs en un après-midi, et constitue un
-- manquement au Code du numérique béninois (loi n°2017-20, APDP).
-- ---------------------------------------------------------------------------
REVOKE ALL ON public.profiles FROM anon, authenticated;

CREATE VIEW public.public_profiles AS
SELECT id, full_name, avatar_url, role, kyc_status, created_at
FROM public.profiles;  -- phone_number et email volontairement exclus

CREATE POLICY "Own profile readable"   ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Own profile updatable"  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Listings : lecture publique des biens disponibles
CREATE POLICY "Active listings are viewable by all" ON public.listings FOR SELECT USING (is_available = true OR auth.uid() = owner_id);
CREATE POLICY "Owners can insert listings" ON public.listings FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners can update own listings" ON public.listings FOR UPDATE USING (auth.uid() = owner_id);

-- ---------------------------------------------------------------------------
-- PAYWALL 360 : aucun SELECT direct sur les scènes. Aucune URL publique n'est
-- persistée en base. Le bucket `virtual_tours` est PRIVÉ.
-- L'accès passe exclusivement par l'Edge Function `get-tour-access`, qui :
--   1. vérifie l'existence d'un pass valide (non révoqué, non remboursé),
--   2. retourne des signed_url d'une durée <= 15 minutes, renouvelées en session,
--   3. incruste un filigrane portant l'identifiant du compte.
-- La preview gratuite (1 pièce, 90°, floutée au-delà) est servie depuis un
-- bucket public SÉPARÉ : elle est censée circuler, c'est l'appât.
-- ---------------------------------------------------------------------------
CREATE POLICY "Scenes readable only with a valid pass" ON public.virtual_tour_scenes FOR SELECT
USING (EXISTS (
    SELECT 1 FROM public.virtual_tour_access_passes p
    WHERE p.listing_id = virtual_tour_scenes.listing_id
      AND p.tenant_id  = auth.uid()
      AND p.revoked_at IS NULL
      AND p.refunded_at IS NULL
));

CREATE POLICY "Hotspots follow scene access" ON public.virtual_tour_hotspots FOR SELECT
USING (EXISTS (
    SELECT 1 FROM public.virtual_tour_scenes s
    JOIN public.virtual_tour_access_passes p ON p.listing_id = s.listing_id
    WHERE s.id = virtual_tour_hotspots.from_scene_id
      AND p.tenant_id = auth.uid()
      AND p.revoked_at IS NULL
));

CREATE POLICY "Own passes only"   ON public.virtual_tour_access_passes FOR SELECT USING (auth.uid() = tenant_id);
CREATE POLICY "Own credits only"  ON public.visit_credits FOR SELECT USING (auth.uid() = profile_id);

-- Escrow : accessible uniquement par les parties prenantes
CREATE POLICY "Escrow visible to participants" ON public.escrow_transactions FOR SELECT
USING (auth.uid() = tenant_id OR auth.uid() = owner_id);

-- ============================================================================
-- TABLES RESTANT À MODÉLISER (promises par le PRD, absentes de la v1.0)
-- Priorité 1 (MVP)      : saved_searches, search_alerts, favorites, notifications,
--                         device_tokens, listing_views, referrals
-- Priorité 2 (offre)    : broker_leads, shooting_requests, field_agent_tours
-- Priorité 3 (escrow)   : wallets, payouts, disputes, escrow_audit_log
--                         -> bloquées par la conformité BCEAO, cf. AUDIT §6 R-1
-- Transverse            : deleted_at sur toutes les tables métier, historique de prix
-- ============================================================================
