-- ============================================================================
-- CORRECTIF — la fraîcheur ne remontait pas jusqu'à l'application
--
-- Symptôme observé au premier lancement : les 9 biens affichaient
-- « Photos seulement », alors que 6 re-confirmations existaient.
-- `listings` renvoyait des lignes, `availability_checks` renvoyait [].
--
-- DÉCISION DE CONCEPTION : la fraîcheur est PUBLIQUE. C'est la preuve que le
-- produit vend — « ce bien est encore libre, vérifié aujourd'hui à 09h12 ».
-- La cacher revient à retirer au produit sa seule promesse différenciante.
-- Elle ne contient aucune donnée personnelle : un identifiant de bien, une
-- date, un booléen.
--
-- À exécuter dans l'éditeur SQL de Supabase. Idempotent.
-- ============================================================================

BEGIN;

-- 1. Lecture publique de la fraîcheur ----------------------------------------
ALTER TABLE public.availability_checks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Freshness is public" ON public.availability_checks;
CREATE POLICY "Freshness is public"
  ON public.availability_checks
  FOR SELECT
  USING (true);

-- L'écriture reste fermée : seuls les agents, bailleurs et apporteurs
-- re-confirment, et ils passent par une Edge Function.
GRANT SELECT ON public.availability_checks TO anon, authenticated;

-- 2. Filet de sécurité : ré-insérer les vérifications si elles manquent -------
-- Si le bloc du seed avait échoué, ceci le rattrape sans dupliquer.
INSERT INTO public.availability_checks
  (listing_id, checked_by, is_still_available, check_method, checked_at)
SELECT v.listing_id, '22222222-2222-2222-2222-222222222222', TRUE, v.method, v.at
FROM (VALUES
  ('a0000001-0000-4000-8000-000000000001'::uuid, 'visit',         NOW() - INTERVAL '3 hours'),
  ('a0000002-0000-4000-8000-000000000002'::uuid, 'call',          NOW() - INTERVAL '8 hours'),
  ('a0000004-0000-4000-8000-000000000004'::uuid, 'owner_confirm', NOW() - INTERVAL '4 days'),
  ('a0000005-0000-4000-8000-000000000005'::uuid, 'call',          NOW() - INTERVAL '6 days'),
  ('a0000006-0000-4000-8000-000000000006'::uuid, 'visit',         NOW() - INTERVAL '12 days'),
  ('a0000010-0000-4000-8000-000000000010'::uuid, 'call',          NOW() - INTERVAL '1 day')
) AS v(listing_id, method, at)
WHERE EXISTS (SELECT 1 FROM public.listings l WHERE l.id = v.listing_id)
  AND NOT EXISTS (
    SELECT 1 FROM public.availability_checks c WHERE c.listing_id = v.listing_id
  );

-- 3. Deux photos du seed renvoient 404 sur Unsplash --------------------------
UPDATE public.listings SET main_image_url =
  'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=70'
WHERE id = 'a0000001-0000-4000-8000-000000000001';

UPDATE public.listings SET main_image_url =
  'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&q=70'
WHERE id = 'a0000002-0000-4000-8000-000000000002';

COMMIT;

-- ============================================================================
-- VÉRIFICATION — à lire après exécution
-- ============================================================================
SELECT
  (SELECT count(*) FROM public.listings)                                  AS biens_total,
  (SELECT count(*) FROM public.listings WHERE is_available)               AS biens_visibles,
  (SELECT count(*) FROM public.availability_checks)                       AS verifications,
  (SELECT count(*) FROM public.virtual_tour_scenes)                       AS scenes_360,
  (SELECT count(*) FROM public.profiles)                                  AS profils;

-- Attendu : 10 · 9 · 6 · 6 · 2
--
-- Puis, depuis un terminal — le test de pénétration de GATES.md G19 :
--   curl -H "apikey: sb_publishable_..." \
--     ".../rest/v1/availability_checks?select=checked_at"   -> 6 lignes
--   curl -H "apikey: sb_publishable_..." \
--     ".../rest/v1/virtual_tour_scenes?select=panorama_url" -> 0 ligne
--
-- Le second est la porte G19 : 6 scènes existent, la clé publiable n'en voit
-- aucune. Tant que `scenes_360` valait 0, ce test ne prouvait rien.
-- ============================================================================
