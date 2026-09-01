-- ============================================================================
-- EAZYRENT — Données de test (Grand Nokoué)
--
-- À exécuter dans l'éditeur SQL de Supabase, APRÈS DATABASE_SCHEMA.sql.
--
-- ⚠️ SEED UNIQUEMENT. L'insertion directe dans `auth.users` est une pratique
--    de développement : en production, les comptes se créent par l'OTP.
--
-- Idempotent : relançable sans dupliquer.
-- Pour tout effacer : voir le bloc de nettoyage en fin de fichier.
-- ============================================================================

BEGIN;

-- 1. Un bailleur et un agent de terrain -------------------------------------
DO $$
DECLARE
  v_owner  UUID := '11111111-1111-1111-1111-111111111111';
  v_agent  UUID := '22222222-2222-2222-2222-222222222222';
BEGIN
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data
  )
  VALUES
    (v_owner, '00000000-0000-0000-0000-000000000000', 'authenticated',
     'authenticated', 'bailleur.test@eazyrent.bj', crypt('seed-only', gen_salt('bf')),
     NOW(), NOW(), NOW(), '{"provider":"email"}'::jsonb, '{}'::jsonb),
    (v_agent, '00000000-0000-0000-0000-000000000000', 'authenticated',
     'authenticated', 'agent.test@eazyrent.bj', crypt('seed-only', gen_salt('bf')),
     NOW(), NOW(), NOW(), '{"provider":"email"}'::jsonb, '{}'::jsonb)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.profiles (id, role, full_name, phone_number, kyc_status, is_phone_verified)
  VALUES
    (v_owner, 'owner',       'Mensah Adjovi', '+22997000001', 'verified', TRUE),
    (v_agent, 'field_agent', 'Rachid',        '+22997000002', 'verified', TRUE)
  ON CONFLICT (id) DO NOTHING;
END $$;

-- 2. Dix biens du Grand Nokoué ------------------------------------------------
-- Loyers et avances calqués sur la pratique réelle de Cotonou et Abomey-Calavi.
-- `total_move_in_cost` = avance + caution + frais, le chiffre qui decide.
INSERT INTO public.listings (
  id, owner_id, title, description, listing_type, property_type,
  price_amount, deposit_amount, agency_fees, advance_months, total_move_in_cost,
  is_price_firm, bedrooms_count, electricity_meter, submeter_kwh_price,
  water_supply, is_flood_prone, is_paved_access, has_generator,
  has_security_guard, address, neighborhood, city, country,
  latitude, longitude, main_image_url, virtual_tour_360_url,
  is_available, is_featured, created_at
) VALUES
  ('a0000001-0000-4000-8000-000000000001', '11111111-1111-1111-1111-111111111111',
   'Chambre-salon Fidjrossè', 'Cour commune calme, portail metallique.',
   'rent_long_term', 'apartment',
   35000, 35000, 105000, 3, 245000, TRUE, 1, 'prepaid_card', NULL,
   'public_network_running', FALSE, TRUE, FALSE, FALSE,
   'Rue 12.045, Fidjrosse', 'Fidjrossè', 'Cotonou', 'Bénin',
   6.3654, 2.3841, 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800',
   'https://tours.eazyrent.bj/a0000001', TRUE, FALSE, NOW() - INTERVAL '2 hours'),

  ('a0000002-0000-4000-8000-000000000002', '11111111-1111-1111-1111-111111111111',
   'Chambre-salon Cadjèhoun', 'Etage, balcon, quartier bitume.',
   'rent_long_term', 'apartment',
   45000, 45000, 90000, 2, 225000, TRUE, 1, 'prepaid_card', NULL,
   'public_network_running', FALSE, TRUE, FALSE, TRUE,
   'Avenue Steinmetz, Cadjehoun', 'Cadjèhoun', 'Cotonou', 'Bénin',
   6.3598, 2.3912, 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
   'https://tours.eazyrent.bj/a0000002', TRUE, FALSE, NOW() - INTERVAL '6 hours'),

  ('a0000003-0000-4000-8000-000000000003', '11111111-1111-1111-1111-111111111111',
   'Chambre Agla', 'Chambre simple, douche interne.',
   'rent_long_term', 'room',
   22000, 22000, 44000, 2, 110000, FALSE, 1, 'shared_submeter', 150,
   'water_tower_tank', TRUE, FALSE, FALSE, FALSE,
   'Agla les Pylones', 'Agla', 'Cotonou', 'Bénin',
   6.3712, 2.3564, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
   NULL, TRUE, FALSE, NOW() - INTERVAL '1 day'),

  ('a0000004-0000-4000-8000-000000000004', '11111111-1111-1111-1111-111111111111',
   '2 chambres-salon Godomey', 'Maison basse, cour privee, forage.',
   'rent_long_term', 'apartment',
   65000, 65000, 130000, 3, 390000, TRUE, 2, 'prepaid_card', NULL,
   'private_borehole', FALSE, FALSE, TRUE, TRUE,
   'Godomey Salamey', 'Godomey', 'Abomey-Calavi', 'Bénin',
   6.3889, 2.3255, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
   'https://tours.eazyrent.bj/a0000004', TRUE, TRUE, NOW() - INTERVAL '3 days'),

  ('a0000005-0000-4000-8000-000000000005', '11111111-1111-1111-1111-111111111111',
   'Chambre-salon Kpota', 'Proche du marche, voie laterite.',
   'rent_long_term', 'apartment',
   30000, 30000, 60000, 2, 150000, FALSE, 1, 'shared_submeter', 175,
   'water_tower_tank', TRUE, FALSE, FALSE, FALSE,
   'Kpota carrefour', 'Kpota', 'Abomey-Calavi', 'Bénin',
   6.4122, 2.3401, 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800',
   NULL, TRUE, FALSE, NOW() - INTERVAL '5 days'),

  ('a0000006-0000-4000-8000-000000000006', '11111111-1111-1111-1111-111111111111',
   'Appartement Fidjrossè plage', 'Standing, climatisation, gardien.',
   'rent_long_term', 'apartment',
   150000, 150000, 300000, 3, 900000, TRUE, 2, 'conventional_postpaid', NULL,
   'public_network_running', FALSE, TRUE, TRUE, TRUE,
   'Fidjrosse plage', 'Fidjrossè', 'Cotonou', 'Bénin',
   6.3521, 2.3789, 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
   'https://tours.eazyrent.bj/a0000006', TRUE, FALSE, NOW() - INTERVAL '8 days'),

  ('a0000007-0000-4000-8000-000000000007', '11111111-1111-1111-1111-111111111111',
   'Chambre Vèdoko', 'Cour commune, eau au chateau.',
   'rent_long_term', 'room',
   18000, 18000, 36000, 2, 90000, FALSE, 1, 'shared_submeter', 200,
   'water_tower_tank', FALSE, FALSE, FALSE, FALSE,
   'Vedoko carre 421', 'Vèdoko', 'Cotonou', 'Bénin',
   6.3745, 2.3689, 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800',
   NULL, TRUE, FALSE, NOW() - INTERVAL '14 days'),

  ('a0000008-0000-4000-8000-000000000008', '11111111-1111-1111-1111-111111111111',
   'Boutique Akpakpa', 'Local commercial sur voie bitumee.',
   'rent_long_term', 'commercial',
   80000, 80000, 160000, 3, 480000, TRUE, 0, 'conventional_postpaid', NULL,
   'public_network_running', TRUE, TRUE, FALSE, FALSE,
   'Akpakpa Dodome', 'Akpakpa', 'Cotonou', 'Bénin',
   6.3634, 2.4412, 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
   NULL, TRUE, FALSE, NOW() - INTERVAL '20 days'),

  -- Un bien deja loue : verifie que le feed le masque bien.
  ('a0000009-0000-4000-8000-000000000009', '11111111-1111-1111-1111-111111111111',
   'Chambre-salon Menontin (loue)', 'Ne doit PAS apparaitre dans le feed.',
   'rent_long_term', 'apartment',
   32000, 32000, 64000, 2, 160000, FALSE, 1, 'prepaid_card', NULL,
   'public_network_running', FALSE, TRUE, FALSE, FALSE,
   'Menontin', 'Menontin', 'Cotonou', 'Bénin',
   6.3811, 2.3712, NULL, NULL, FALSE, FALSE, NOW() - INTERVAL '30 days'),

  -- Un bien sans photo : verifie l'etat `partial` de la carte.
  ('a0000010-0000-4000-8000-000000000010', '11111111-1111-1111-1111-111111111111',
   'Chambre Sainte-Rita', 'Sans photo : teste le repli de la vignette.',
   'rent_long_term', 'room',
   25000, 25000, 50000, 2, 125000, FALSE, 1, 'prepaid_card', NULL,
   'public_network_running', FALSE, TRUE, FALSE, FALSE,
   'Sainte Rita', 'Sainte-Rita', 'Cotonou', 'Bénin',
   6.3667, 2.3945, NULL, NULL, TRUE, FALSE, NOW() - INTERVAL '4 days')
ON CONFLICT (id) DO NOTHING;

-- 3. Re-confirmations de disponibilité ----------------------------------------
-- Les trois tons de fraicheur sont representes : ok, warn, stale.
INSERT INTO public.availability_checks (listing_id, checked_by, is_still_available, check_method, checked_at)
VALUES
  ('a0000001-0000-4000-8000-000000000001', '22222222-2222-2222-2222-222222222222', TRUE, 'visit',        NOW() - INTERVAL '3 hours'),
  ('a0000002-0000-4000-8000-000000000002', '22222222-2222-2222-2222-222222222222', TRUE, 'call',         NOW() - INTERVAL '8 hours'),
  ('a0000004-0000-4000-8000-000000000004', '22222222-2222-2222-2222-222222222222', TRUE, 'owner_confirm',NOW() - INTERVAL '4 days'),
  ('a0000005-0000-4000-8000-000000000005', '22222222-2222-2222-2222-222222222222', TRUE, 'call',         NOW() - INTERVAL '6 days'),
  ('a0000006-0000-4000-8000-000000000006', '22222222-2222-2222-2222-222222222222', TRUE, 'visit',        NOW() - INTERVAL '12 days'),
  ('a0000010-0000-4000-8000-000000000010', '22222222-2222-2222-2222-222222222222', TRUE, 'call',         NOW() - INTERVAL '1 day')
ON CONFLICT DO NOTHING;
-- a0000003, a0000007, a0000008 n'ont AUCUNE verification : ils doivent
-- afficher « Photos seulement ».

-- 4. Scènes 360 — protégées par la RLS ---------------------------------------
-- Elles ne doivent JAMAIS etre lisibles sans pass valide. C'est le test de
-- penetration de GATES.md G19 : avec la cle publiable, ces lignes doivent
-- rester invisibles.
INSERT INTO public.virtual_tour_scenes (listing_id, scene_name, panorama_url, display_order, captured_by_agent_id)
VALUES
  ('a0000001-0000-4000-8000-000000000001', 'Salon',    'private://a0000001/salon.webp',    0, '22222222-2222-2222-2222-222222222222'),
  ('a0000001-0000-4000-8000-000000000001', 'Chambre',  'private://a0000001/chambre.webp',  1, '22222222-2222-2222-2222-222222222222'),
  ('a0000001-0000-4000-8000-000000000001', 'Cuisine',  'private://a0000001/cuisine.webp',  2, '22222222-2222-2222-2222-222222222222'),
  ('a0000001-0000-4000-8000-000000000001', 'Douche',   'private://a0000001/douche.webp',   3, '22222222-2222-2222-2222-222222222222'),
  ('a0000001-0000-4000-8000-000000000001', 'Cour',     'private://a0000001/cour.webp',     4, '22222222-2222-2222-2222-222222222222'),
  ('a0000001-0000-4000-8000-000000000001', 'Entrée',   'private://a0000001/entree.webp',   5, '22222222-2222-2222-2222-222222222222')
ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================================================
-- CE QUE CE JEU DE DONNÉES DOIT PRODUIRE
--
--   Feed sans filtre        : 8 biens (le loué et rien d'autre sont exclus)
--   Fraîcheur « ok »        : Fidjrossè (3 h), Cadjèhoun (8 h)
--   Fraîcheur « warn »      : Godomey (4 j), Kpota (6 j)
--   Fraîcheur « stale »     : Fidjrossè plage (12 j)
--   « Photos seulement »    : Agla, Vèdoko, Akpakpa
--   Badge 360               : Fidjrossè, Cadjèhoun, Godomey, Fidjrossè plage
--   Repli sans photo        : Sainte-Rita
--   Coût d'entrée le + bas  : Vèdoko 90 000 F
--   Coût d'entrée le + haut : Fidjrossè plage 900 000 F
--
-- TEST DE PÉNÉTRATION (GATES.md G19) — doit renvoyer [] avec la clé publiable :
--   curl -H "apikey: sb_publishable_..." \
--     "https://<projet>.supabase.co/rest/v1/virtual_tour_scenes?select=panorama_url"
-- Si des lignes reviennent, le paywall est ouvert.
-- ============================================================================

-- NETTOYAGE (a executer separement si besoin)
-- DELETE FROM public.virtual_tour_scenes WHERE listing_id::text LIKE 'a00000%';
-- DELETE FROM public.availability_checks WHERE listing_id::text LIKE 'a00000%';
-- DELETE FROM public.listings           WHERE id::text          LIKE 'a00000%';
-- DELETE FROM public.profiles WHERE id IN ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222');
-- DELETE FROM auth.users      WHERE id IN ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222');
