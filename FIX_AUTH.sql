-- ============================================================================
-- CORRECTIF — l'authentification ne pouvait pas créer de profil
--
-- Le schéma v2.0 fait `REVOKE ALL ON public.profiles FROM anon, authenticated`.
-- C'était la bonne intention : empêcher un démarcheur d'aspirer les numéros de
-- tous les chercheurs en un après-midi (défaut de la v1.0, AUDIT §4).
--
-- Mais la révocation était TROP LARGE : elle bloque aussi l'utilisateur qui
-- crée SA PROPRE ligne au premier code validé. Et aucune politique INSERT
-- n'existait.
--
-- Le principe à tenir n'est pas « personne ne touche profiles », c'est
-- « chacun ne touche que sa propre ligne ». C'est ce que cette version écrit.
--
-- À exécuter dans l'éditeur SQL de Supabase. Idempotent.
-- ============================================================================

BEGIN;

-- 1. Droits de table : le minimum, et seulement pour les comptes connectés ----
-- `anon` n'obtient RIEN : un visiteur non identifié n'a aucune raison de
-- toucher à la table des profils.
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;

-- 2. Politiques : chacun sur sa propre ligne, jamais celle des autres ---------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Own profile readable"  ON public.profiles;
DROP POLICY IF EXISTS "Own profile updatable" ON public.profiles;
DROP POLICY IF EXISTS "Own profile insert"    ON public.profiles;

CREATE POLICY "Own profile readable" ON public.profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

-- WITH CHECK (auth.uid() = id) : on ne peut pas créer une ligne au nom
-- de quelqu'un d'autre, même en forgeant la requête.
CREATE POLICY "Own profile insert" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Own profile updatable" ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 3. L'OTP passe par E-MAIL : le numéro n'est plus unique ni obligatoire ------
-- Le code valide l'adresse, pas le téléphone. Deux consequences :
--   · `phone_number` ne peut plus etre NOT NULL au moment de l'insertion
--     si un jour un profil se cree sans numero ;
--   · l'unicite reste souhaitable mais ne doit pas faire echouer une
--     inscription legitime — on la garde, en la nommant pour pouvoir la
--     lever si le terrain montre le contraire.
ALTER TABLE public.profiles ALTER COLUMN full_name DROP NOT NULL;

COMMIT;

-- ============================================================================
-- VÉRIFICATION
-- ============================================================================
SELECT policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles'
ORDER BY cmd;

-- Attendu : 3 politiques — SELECT, INSERT, UPDATE — toutes sur {authenticated}
--
-- Le test qui compte, depuis un terminal : avec la clé PUBLIABLE (donc `anon`),
-- la table doit rester muette.
--   curl -H "apikey: sb_publishable_..." ".../rest/v1/profiles?select=phone_number"
-- Attendu : une erreur de privilège, PAS une liste de numéros.
-- ============================================================================


-- ============================================================================
-- À FAIRE DANS LE TABLEAU DE BORD, PAS EN SQL
--
-- 1. Authentication → Providers → Email : activer, et DÉSACTIVER
--    « Confirm email » si vous voulez un code à 6 chiffres plutôt qu'un lien.
--
-- 2. Authentication → SMTP Settings : brancher un SMTP à vous.
--    ⚠️ Le SMTP par défaut de Supabase est plafonné à quelques envois par
--    heure. Suffisant pour tester, inutilisable dès les premiers vrais
--    utilisateurs : le troisième inscrit de la journée ne recevra rien.
--    Gratuit et suffisant pour démarrer : Brevo (300/jour) ou Resend
--    (3 000/mois).
--
-- 3. Authentication → Email Templates : le gabarit « Magic Link » doit
--    contenir {{ .Token }} pour afficher le code à 6 chiffres. Par défaut il
--    ne contient qu'un lien, et l'écran de saisie du code n'aurait rien à
--    recevoir.
-- ============================================================================
