import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

/**
 * Client Supabase pour composants serveur (RSC).
 *
 * POURQUOI IL N'Y A PAS DE CLIENT NAVIGATEUR NI DE MIDDLEWARE
 *
 * Le quickstart Supabase installe trois clients — serveur, navigateur,
 * middleware — parce qu'il vise une application avec des sessions
 * authentifiees. Le site EAZYRENT est en LECTURE PUBLIQUE ANONYME :
 * la landing, le lien profond /b/[id] et le Conseil de famille n'ont pas
 * d'utilisateur connecte.
 *
 * En n'utilisant que ce client, les pages rendent du HTML cote serveur et
 * le navigateur ne recoit AUCUN JavaScript Supabase. C'est la seule facon
 * de tenir les 100 Ko specifies pour la page de vote familial
 * (FEATURES_V2.md F5) — impossible avec le client navigateur.
 *
 * Si un jour une page exige une session (espace proprietaire web, par
 * exemple), on ajoutera le middleware A CE MOMENT-LA, pour cette route
 * uniquement.
 */
export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            )
          } catch {
            // Appele depuis un Server Component : sans session a rafraichir,
            // il n'y a rien a ecrire. Ignorer est correct ici.
          }
        },
      },
    },
  )
}

/**
 * ⛔ REGLE DE SECURITE — CONSTITUTION.md P4
 *
 * Aucune page publique ne doit lire `virtual_tour_scenes`. Cette table
 * contient les panoramas COMPLETS, payants a 1 000 FCFA.
 *
 * La RLS les protege deja, mais la regle est ici pour qu'on ne l'oublie pas :
 * le site ne sert que la PREVIEW basse resolution, depuis le bucket public
 * separe. Un tour complet ne s'obtient que par l'Edge Function
 * `get-tour-access`, qui verifie un pass et signe des URL de 15 minutes.
 *
 * Si cette regle saute, le paywall meurt sur le web meme s'il reste etanche
 * sur mobile.
 */
export const TABLES_INTERDITES_EN_PUBLIC = [
  'virtual_tour_scenes',
  'virtual_tour_hotspots',
  'virtual_tour_access_passes',
  'profiles',
  'escrow_transactions',
] as const
