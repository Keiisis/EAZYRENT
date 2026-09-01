// get-tour-access — le seul chemin vers un panorama.
//
// CONSTITUTION P4 : le paywall n'est jamais arbitré côté client.
//
// Cette fonction est la serrure. Elle tourne sur le serveur, avec la clé
// SECRÈTE (`service_role`), qui n'existe nulle part dans l'APK. Elle fait
// trois choses, dans cet ordre, et refuse à la première qui échoue :
//
//   1. identifie l'appelant par son JWT — pas par un identifiant qu'il
//      envoie lui-même ;
//   2. vérifie EN BASE qu'il a payé pour ce bien, ou qu'il lui reste un
//      crédit ; si c'est un crédit, elle le débite ICI, au moment où la
//      visite s'ouvre — jamais à l'achat ;
//   3. ne rend alors que des URL SIGNÉES valables 60 minutes.
//
// Ce qu'elle ne rend JAMAIS : le chemin de stockage brut. Une URL permanente
// rendue au client transforme un client HTTP et un identifiant de bien en
// aspirateur à panoramas — c'est-à-dire en fin du modèle économique.
//
// DÉPLOIEMENT
//   supabase functions deploy get-tour-access
//   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=sk_...
//
// ⚠️ La clé `service_role` vit UNIQUEMENT dans les secrets Supabase. Elle ne
// doit jamais entrer dans `.env`, dans `AppConfig`, ni dans un dépôt git.

import { createClient } from 'jsr:@supabase/supabase-js@2'

const SIGNED_URL_TTL_SECONDS = 60 * 60 // 60 minutes
const PANORAMA_BUCKET = 'panoramas'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
}

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const { listing_id } = await req.json()
    if (!listing_id) return json({ error: 'listing_id manquant' }, 400)

    // ── 1. QUI APPELLE ────────────────────────────────────────────────
    // L'identité vient du jeton, jamais du corps de la requête. Accepter un
    // `user_id` envoyé par le client reviendrait à laisser n'importe qui
    // ouvrir les visites de n'importe qui.
    const authHeader = req.headers.get('Authorization') ?? ''
    const anon = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user } } = await anon.auth.getUser()
    if (!user) return json({ error: 'non authentifié' }, 401)

    // À partir d'ici on travaille avec la clé secrète : la RLS ne s'applique
    // plus, c'est CETTE fonction qui décide.
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // ── 2. LE BIEN EXISTE-T-IL, ET A-T-IL UNE VISITE ? ────────────────
    const { data: listing } = await admin
      .from('listings')
      .select('id, is_available')
      .eq('id', listing_id)
      .maybeSingle()
    if (!listing) return json({ error: 'bien introuvable' }, 404)

    // ── 3. A-T-IL PAYÉ ? ──────────────────────────────────────────────
    //
    // Noms de tables pris dans DATABASE_SCHEMA.sql, pas devinés :
    // `virtual_tour_access_passes` (§5.3) et `visit_credits` (§5.4).
    //
    // Un pass déjà ouvert sur ce bien reste ouvert — l'accès est PERMANENT
    // tant que l'annonce est en ligne (§5.3). C'est ce qui rend le retour en
    // arrière sans danger et le hors-ligne possible. `revoked_at` couvre le
    // cas de l'annonce retirée.
    const { data: pass } = await admin
      .from('virtual_tour_access_passes')
      .select('id')
      .eq('tenant_id', user.id)
      .eq('listing_id', listing_id)
      .is('revoked_at', null)
      .maybeSingle()

    if (!pass) {
      // Pas de pass : reste-t-il un crédit ? Le débit se fait ICI, à
      // l'ouverture — pas à l'achat. Quelqu'un qui achète un pack de 3 et
      // n'en ouvre qu'un en garde deux.
      const { data: wallet } = await admin
        .from('visit_credits')
        .select('id, credits_remaining')
        .eq('profile_id', user.id)
        .gt('credits_remaining', 0)
        .or(`expires_at.is.null,expires_at.gt.${new Date().toISOString()}`)
        // Le plus ancien d'abord : on consomme ce qui expire en premier.
        .order('expires_at', { ascending: true, nullsFirst: false })
        .limit(1)
        .maybeSingle()

      if (!wallet) return json({ error: 'aucun crédit' }, 402)

      const { error: debitError } = await admin
        .from('visit_credits')
        .update({ credits_remaining: wallet.credits_remaining - 1 })
        .eq('id', wallet.id)
        // Garde anti-course : deux ouvertures simultanées ne peuvent pas
        // débiter deux fois le même dernier crédit.
        .gt('credits_remaining', 0)
      if (debitError) return json({ error: 'débit impossible' }, 409)

      await admin.from('virtual_tour_access_passes').insert({
        tenant_id: user.id,
        listing_id,
        amount_paid: 0,
        eazyrent_net_revenue: 0,
        payment_method: 'credit',
        source: 'credit_pack',
      })
    }

    // ── 4. LES SCÈNES, ET SEULEMENT MAINTENANT ────────────────────────
    const { data: scenes } = await admin
      .from('virtual_tour_scenes')
      .select(
        'id, scene_name, panorama_url, initial_yaw, initial_pitch, ' +
          'display_order, captured_by_agent_id, created_at',
      )
      .eq('listing_id', listing_id)
      .order('display_order', { ascending: true })

    if (!scenes || scenes.length === 0) {
      // Incohérence de NOTRE côté : le bien est vendu comme vérifié mais
      // aucune scène n'est publiée. On rend une liste vide et le client
      // rembourse — plutôt qu'un écran noir.
      return json(
        { scenes: [], expires_at: new Date().toISOString() },
        200,
      )
    }

    // Les points de passage vivent dans leur PROPRE table (§5.2), pas dans
    // une colonne JSON. On les charge en une requête et on les regroupe.
    const sceneIds = scenes.map((s) => s.id)
    const { data: hotspots } = await admin
      .from('virtual_tour_hotspots')
      .select('from_scene_id, target_scene_id, yaw, pitch, tooltip_text')
      .in('from_scene_id', sceneIds)

    const byScene = new Map<string, unknown[]>()
    for (const h of hotspots ?? []) {
      const list = byScene.get(h.from_scene_id) ?? []
      list.push({
        target_scene_id: h.target_scene_id,
        label: h.tooltip_text,
        longitude: h.yaw,
        latitude: h.pitch,
      })
      byScene.set(h.from_scene_id, list)
    }

    // Les URL signées, générées à l'instant, valables une heure.
    const signed = await Promise.all(
      scenes.map(async (s) => {
        const path = String(s.panorama_url).replace(
          new RegExp(`^.*${PANORAMA_BUCKET}/`),
          '',
        )
        const { data } = await admin.storage
          .from(PANORAMA_BUCKET)
          .createSignedUrl(path, SIGNED_URL_TTL_SECONDS)
        return {
          id: s.id,
          scene_name: s.scene_name,
          initial_yaw: s.initial_yaw,
          initial_pitch: s.initial_pitch,
          hotspots: byScene.get(s.id) ?? [],
          signed_url: data?.signedUrl,
          // `panorama_url` n'est JAMAIS renvoyé : c'est le chemin permanent.
        }
      }),
    )

    // Le nom de l'agent : « Filmé par Rachid » bat n'importe quel badge.
    let agentName: string | null = null
    if (scenes[0].captured_by_agent_id) {
      const { data: agent } = await admin
        .from('profiles')
        .select('full_name')
        .eq('id', scenes[0].captured_by_agent_id)
        .maybeSingle()
      agentName = agent?.full_name ?? null
    }

    return json(
      {
        scenes: signed,
        agent_name: agentName,
        captured_at: scenes[0].created_at ?? new Date().toISOString(),
        expires_at: new Date(
          Date.now() + SIGNED_URL_TTL_SECONDS * 1000,
        ).toISOString(),
      },
      200,
    )
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
