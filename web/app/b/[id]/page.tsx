import { notFound } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { short, full, freshness } from '@/lib/format'

/**
 * Lien profond : eazyrent.bj/b/{id}
 *
 * Quelqu'un recoit une fiche sur WhatsApp et l'ouvre SANS avoir l'application.
 * C'est le canal d'acquisition n°1 du produit (GROWTH_MONETISATION.md §4.3),
 * et il est gratuit. Cette page doit donc :
 *   1. montrer assez pour donner envie,
 *   2. ne jamais montrer le tour complet, qui est payant,
 *   3. mener a l'installation.
 *
 * Rendu 100 % serveur : le navigateur ne recoit aucun JavaScript Supabase.
 */

export const revalidate = 300 // 5 min : la fraicheur compte, le cache aussi

type Listing = {
  id: string
  price_amount: number
  property_type: string
  neighborhood: string | null
  city: string
  advance_months: number | null
  total_move_in_cost: number | null
  main_image_url: string | null
  is_available: boolean
}

export default async function Page({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const supabase = await createClient()

  // On ne lit QUE `listings`. Jamais `virtual_tour_scenes` :
  // voir TABLES_INTERDITES_EN_PUBLIC dans lib/supabase/server.ts.
  const { data: listing } = await supabase
    .from('listings')
    .select(
      'id, price_amount, property_type, neighborhood, city, advance_months, total_move_in_cost, main_image_url, is_available',
    )
    .eq('id', id)
    .maybeSingle<Listing>()

  if (!listing) notFound()

  const { data: check } = await supabase
    .from('availability_checks')
    .select('checked_at, is_still_available')
    .eq('listing_id', id)
    .order('checked_at', { ascending: false })
    .limit(1)
    .maybeSingle<{ checked_at: string; is_still_available: boolean }>()

  const fresh = freshness(check?.checked_at ?? null)
  const toneClass = {
    ok: 'text-[#006B4A]',
    warn: 'text-[#8A5A00]',
    stale: 'text-[#55617A]',
  }[fresh.tone]

  return (
    <main className="mx-auto max-w-md px-4 pb-24">
      {listing.main_image_url && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={listing.main_image_url}
          alt=""
          className="mt-4 aspect-video w-full rounded-2xl object-cover"
        />
      )}

      <p className="mt-4 text-3xl font-extrabold text-[#0B0F19]">
        {short(listing.price_amount)}
        <span className="text-base font-medium text-[#55617A]"> /mois</span>
      </p>

      <p className="mt-1 text-[#1E2635]">
        {listing.property_type} · {listing.neighborhood ?? listing.city}
      </p>

      <p className={`mt-3 text-sm font-medium ${toneClass}`}>◉ {fresh.label}</p>

      {listing.total_move_in_cost !== null && (
        <section className="mt-5 rounded-2xl border border-[#E2E8F0] p-4">
          <h2 className="text-xs font-semibold uppercase tracking-wide text-[#55617A]">
            Ce que tu paies pour entrer
          </h2>
          <p className="mt-2 text-2xl font-semibold tabular-nums text-[#0B0F19]">
            {full(listing.total_move_in_cost)}
          </p>
          {listing.advance_months ? (
            <p className="text-sm text-[#55617A]">
              {listing.advance_months} mois d&apos;avance
            </p>
          ) : null}
        </section>
      )}

      {/* Le seul verrou volontairement visible du produit. */}
      <section className="mt-5 rounded-2xl bg-[#0B0F19] p-5 text-white">
        <p className="text-lg font-bold">Visite ce logement en entier</p>
        <p className="mt-1 text-sm text-white/70">
          Toutes les pieces, filmees sur place par un agent EAZYRENT. Depuis
          chez toi, avant de payer le zem.
        </p>
        <a
          href="/telecharger"
          className="mt-4 flex min-h-12 items-center justify-center rounded-full bg-[#FF4D2E] px-6 font-semibold text-[#0B0F19]"
        >
          Installer EAZYRENT
        </a>
      </section>

      {!listing.is_available && (
        <p className="mt-4 rounded-xl bg-[#FEF2F2] p-3 text-sm text-[#B3151A]">
          Ce bien vient d&apos;etre loue. L&apos;application t&apos;en propose
          d&apos;autres dans le meme quartier.
        </p>
      )}
    </main>
  )
}
