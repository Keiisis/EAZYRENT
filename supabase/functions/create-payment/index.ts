// create-payment — la transaction naît ICI, avant que quoi que ce soit
// s'ouvre côté client.
//
// LEÇON 1 DU TEMPLATE, mot pour mot : « Cette approche garantit que l'ID de
// transaction est connu avant le paiement et que la vérification côté serveur
// fonctionnera correctement. »
//
// Le client n'envoie que : le fournisseur, un montant en francs, un nombre de
// crédits. Il ne fabrique ni référence, ni URL, ni signature. Tout ce qu'il
// affirmerait serait négociable ; tout ce qui est décidé ici ne l'est pas.
//
// DÉPLOIEMENT
//   supabase functions deploy create-payment
//   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...

import { createClient } from 'jsr:@supabase/supabase-js@2'
import { createWithProvider, type ProviderName } from '../_shared/providers.ts'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
}

const json = (b: unknown, s: number) =>
  new Response(JSON.stringify(b), {
    status: s,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })

/// Le catalogue est CÔTÉ SERVEUR. Si le client envoyait le prix, il
/// suffirait de le mettre à 1 F pour acheter dix visites. On ne vérifie donc
/// pas « son » prix : on utilise le nôtre.
const CATALOG: Record<number, number> = {
  1: 1000, // 1 visite
  3: 2500, // Pack Quartier
  7: 5000, // Pack Chasseur
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const { provider, amount_fcfa, credits, listing_id } = await req.json()

    const known: ProviderName[] = ['kkiapay', 'fedapay', 'stripe', 'revolut']
    if (!known.includes(provider)) {
      return json({ error: 'fournisseur inconnu' }, 400)
    }

    // ── L'identité vient du jeton ─────────────────────────────────────
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

    // ── LE PRIX EST LE NÔTRE ──────────────────────────────────────────
    const expected = CATALOG[credits]
    if (!expected) return json({ error: 'pack inconnu' }, 400)
    if (expected !== amount_fcfa) {
      // On ne corrige pas en silence : un écart signale soit un bug, soit une
      // tentative. Les deux méritent d'être vus.
      return json(
        { error: 'montant incohérent', expected, received: amount_fcfa },
        409,
      )
    }

    // ── Les clés, lues en base, JAMAIS envoyées au client ─────────────
    const { data: rows } = await admin
      .from('app_settings')
      .select('key, value')
      .like('key', `${provider}_%`)
    const settings: Record<string, string> = {}
    for (const r of rows ?? []) settings[r.key] = r.value

    // Le taux EUR/XOF vit aussi en réglages : codé en dur, il devient faux le
    // mois suivant et la différence sort de notre poche.
    const { data: rate } = await admin
      .from('app_settings')
      .select('value')
      .eq('key', 'eur_xof_rate')
      .maybeSingle()
    if (rate) settings.eur_xof_rate = rate.value

    // ── Notre référence, la seule qui compte ──────────────────────────
    const reference = `EZR-${crypto.randomUUID().slice(0, 8).toUpperCase()}`

    const { data: profile } = await admin
      .from('profiles')
      .select('email, phone_number')
      .eq('id', user.id)
      .maybeSingle()

    // La ligne est écrite en base AVANT l'appel au fournisseur. Si l'appel
    // échoue, il reste une trace `pending` qu'on peut expliquer — plutôt
    // qu'un paiement fantôme dont personne ne sait rien.
    await admin.from('payment_intents').insert({
      reference,
      user_id: user.id,
      provider,
      amount_fcfa,
      credits,
      listing_id: listing_id ?? null,
      status: 'pending',
    })

    const result = await createWithProvider(provider as ProviderName, {
      reference,
      amountFcfa: amount_fcfa,
      description: `EAZYRENT · ${credits} visite${credits > 1 ? 's' : ''} 360`,
      customerEmail: profile?.email ?? user.email ?? undefined,
      customerPhone: profile?.phone_number ?? undefined,
      returnUrl: 'https://eazyrent.bj/paiement/retour',
      settings,
    })

    await admin
      .from('payment_intents')
      .update({ provider_ref: result.providerRef })
      .eq('reference', reference)

    return json({ reference, checkout_url: result.checkoutUrl }, 200)
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
