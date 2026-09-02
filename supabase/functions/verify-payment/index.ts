// verify-payment — la seule autorité sur « est-ce payé ? ».
//
// LEÇON 2 DU TEMPLATE, commentaire d'origine : « `payment_method` du client
// est IGNORÉ : on utilise toujours celui en DB ». C'est la différence entre
// un paiement et une DÉCLARATION de paiement.
//
// Cette fonction ne reçoit qu'une référence. Ni montant, ni statut, ni
// fournisseur. Elle relit la base, elle relit le fournisseur, et elle tranche.
//
// ELLE EST IDEMPOTENTE. Le client l'appelle en boucle pendant l'attente —
// c'est le seul moyen fiable quand le retour du fournisseur se perd, ce qui
// arrive tous les jours en Mobile Money. Créditer deux fois serait pire que
// ne pas créditer.

import { createClient } from 'jsr:@supabase/supabase-js@2'
import { isPaidAtProvider, type ProviderName } from '../_shared/providers.ts'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
}

const json = (b: unknown, s: number) =>
  new Response(JSON.stringify(b), {
    status: s,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const { reference } = await req.json()
    if (!reference) return json({ error: 'reference manquante' }, 400)

    const anon = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization') ?? '' },
        },
      },
    )
    const { data: { user } } = await anon.auth.getUser()
    if (!user) return json({ error: 'non authentifié' }, 401)

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // La transaction est relue EN BASE, et on vérifie qu'elle appartient à
    // l'appelant. Sans ce `eq('user_id')`, connaître une référence suffirait
    // à créditer le compte de quelqu'un d'autre… ou à lire ses paiements.
    const { data: intent } = await admin
      .from('payment_intents')
      .select('reference, user_id, provider, provider_ref, amount_fcfa, '
        + 'credits, status')
      .eq('reference', reference)
      .eq('user_id', user.id)
      .maybeSingle()

    if (!intent) return json({ error: 'transaction introuvable' }, 404)

    // Déjà traitée : on rend le même résultat, sans recréditer.
    if (intent.status === 'paid') {
      return json(
        {
          status: 'paid',
          amount_fcfa: intent.amount_fcfa,
          credits_added: 0,
          message: 'Déjà validé.',
        },
        200,
      )
    }

    if (!intent.provider_ref) {
      return json({ status: 'pending', amount_fcfa: intent.amount_fcfa }, 200)
    }

    const { data: rows } = await admin
      .from('app_settings')
      .select('key, value')
      .like('key', `${intent.provider}_%`)
    const settings: Record<string, string> = {}
    for (const r of rows ?? []) settings[r.key] = r.value

    // ON RELIT LE FOURNISSEUR. Un `?status=ok` dans l'URL de retour est écrit
    // par le navigateur : il ne prouve rien.
    const paid = await isPaidAtProvider(
      intent.provider as ProviderName,
      intent.provider_ref,
      settings,
    )

    if (!paid) {
      return json({ status: 'pending', amount_fcfa: intent.amount_fcfa }, 200)
    }

    // ── LE CRÉDIT, UNE SEULE FOIS ─────────────────────────────────────
    //
    // Le passage à `paid` est conditionné à `status = 'pending'`. Deux appels
    // simultanés — l'utilisateur qui touche « J'ai payé » pendant que le
    // sondage tourne — ne peuvent pas créditer deux fois : le second ne
    // trouve plus de ligne à mettre à jour.
    const { data: locked } = await admin
      .from('payment_intents')
      .update({ status: 'paid', paid_at: new Date().toISOString() })
      .eq('reference', reference)
      .eq('status', 'pending')
      .select('reference')
      .maybeSingle()

    if (!locked) {
      return json(
        {
          status: 'paid',
          amount_fcfa: intent.amount_fcfa,
          credits_added: 0,
          message: 'Déjà validé.',
        },
        200,
      )
    }

    await admin.from('visit_credits').insert({
      profile_id: user.id,
      credits_total: intent.credits,
      credits_remaining: intent.credits,
      amount_paid: intent.amount_fcfa,
      origin: intent.credits === 1 ? 'pack_3' : 'pack_3',
      payment_transaction_ref: reference,
      // 90 jours pour les packs, comme spécifié §5.4. Une visite achetée à
      // l'unité n'expire pas : elle correspond à un bien précis.
      expires_at: intent.credits > 1
        ? new Date(Date.now() + 90 * 86400_000).toISOString()
        : null,
    })

    return json(
      {
        status: 'paid',
        amount_fcfa: intent.amount_fcfa,
        credits_added: intent.credits,
      },
      200,
    )
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
