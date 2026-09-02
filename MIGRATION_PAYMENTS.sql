-- =========================================================================
-- MIGRATION_PAYMENTS.sql — paiements réels : KkiaPay, FedaPay, Stripe,
-- Revolut.
--
-- À exécuter dans l'éditeur SQL Supabase. Idempotent.
--
-- DEUX TABLES, ET LEUR RAISON D'ÊTRE
--
--   `app_settings`   — les clés des fournisseurs, lues UNIQUEMENT par les
--                      Edge Functions. Aucune politique de lecture n'est
--                      créée : sans policy, la RLS refuse tout le monde, et
--                      seule la clé `service_role` passe. C'est exactement ce
--                      qu'on veut.
--   `payment_intents`— la trace, écrite AVANT l'appel au fournisseur. Sans
--                      elle, un appel qui échoue ne laisse rien, et personne
--                      ne peut expliquer à quelqu'un pourquoi il a été
--                      débité.
-- =========================================================================

-- 1. RÉGLAGES DES FOURNISSEURS --------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_settings (
    key         VARCHAR(80) PRIMARY KEY,
    value       TEXT NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- AUCUNE POLICY. C'est volontaire et c'est la protection principale : avec
-- la RLS activée et zéro politique, ni `anon` ni `authenticated` ne lisent
-- quoi que ce soit. Les Edge Functions utilisent `service_role`, qui
-- contourne la RLS — elles seules voient les clés.
--
-- ⚠️ NE JAMAIS ajouter ici un `CREATE POLICY ... FOR SELECT USING (true)`.
-- Ce serait publier les clés secrètes de paiement.

COMMENT ON TABLE public.app_settings IS
  'Clés des fournisseurs de paiement. RLS active SANS policy : lecture '
  'réservée au service_role, donc aux Edge Functions. Ne jamais ouvrir.';

-- Gabarits. Renseigner les valeurs depuis le tableau de bord Supabase,
-- jamais depuis un dépôt git.
INSERT INTO public.app_settings (key, value) VALUES
    ('kkiapay_private_key', ''),
    ('kkiapay_secret',      ''),
    ('kkiapay_sandbox',     'true'),
    ('fedapay_secret_key',  ''),
    ('fedapay_sandbox',     'true'),
    ('stripe_secret_key',   ''),
    ('revolut_secret_key',  ''),
    ('revolut_sandbox',     'true'),
    -- Taux EUR→XOF. Le franc CFA est arrimé à l'euro à 655,957 : c'est une
    -- parité fixe, pas un cours. On la garde en réglage quand même, parce
    -- qu'un jour elle changera, et ce jour-là on ne veut pas redéployer.
    ('eur_xof_rate',        '655.957')
ON CONFLICT (key) DO NOTHING;

-- 2. INTENTIONS DE PAIEMENT ------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payment_intents (
    reference     VARCHAR(40) PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    provider      VARCHAR(20) NOT NULL
                  CHECK (provider IN ('kkiapay','fedapay','stripe','revolut')),
    -- Le montant est stocké EN FRANCS ENTIERS. Aucune conversion en
    -- centimes n'est jamais persistée : c'est ce qui garantit qu'on ne
    -- facture pas cent fois trop cher un jour de refactoring.
    amount_fcfa   INTEGER NOT NULL CHECK (amount_fcfa > 0),
    credits       INTEGER NOT NULL CHECK (credits > 0),
    listing_id    UUID REFERENCES public.listings(id) ON DELETE SET NULL,
    provider_ref  VARCHAR(120),
    status        VARCHAR(20) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','paid','failed','cancelled')),
    paid_at       TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_intents_user
    ON public.payment_intents (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_payment_intents_pending
    ON public.payment_intents (status)
    WHERE status = 'pending';

ALTER TABLE public.payment_intents ENABLE ROW LEVEL SECURITY;

-- L'utilisateur LIT ses propres paiements — c'est l'écran « Historique de
-- paiements », et c'est la trace qu'il peut citer au support.
DROP POLICY IF EXISTS "Own payments readable" ON public.payment_intents;
CREATE POLICY "Own payments readable" ON public.payment_intents
    FOR SELECT USING (auth.uid() = user_id);

-- Aucune policy d'INSERT ni d'UPDATE. Écrire un paiement est réservé aux
-- Edge Functions. Un client qui pourrait insérer une ligne `status = 'paid'`
-- s'offrirait des crédits — c'est exactement la faille que la leçon n°2 du
-- template décrit.

COMMENT ON COLUMN public.payment_intents.amount_fcfa IS
  'FRANCS ENTIERS, jamais des centimes. XOF est zero-decimal : multiplier '
  'par 100 facture 100 fois trop cher.';

-- 3. GARDE-FOU SUR LES CRÉDITS --------------------------------------------
-- Une référence de transaction ne peut créditer qu'UNE fois. C'est la
-- deuxième serrure derrière l'idempotence de `verify-payment` : si un jour
-- la fonction est réécrite avec un défaut, la base refuse quand même.
CREATE UNIQUE INDEX IF NOT EXISTS idx_visit_credits_one_per_payment
    ON public.visit_credits (payment_transaction_ref)
    WHERE payment_transaction_ref IS NOT NULL;
