import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'EAZYRENT — Visite avant de payer le zem',
  description:
    'Vois le logement en entier, filme sur place, avant de te deplacer. Cotonou et Abomey-Calavi.',
}

/**
 * Landing page. Statique : aucune requete Supabase, aucun JavaScript client.
 *
 * La promesse vient de BRAND_GUIDELINES.md v2.0. On ne decrit pas la
 * technologie — on nomme l'economie realisee.
 */
export default function Home() {
  return (
    <main className="mx-auto max-w-md px-5 pb-20">
      <header className="pt-10">
        <p className="text-2xl font-extrabold tracking-tight text-[#0B0F19]">
          EAZY<span className="text-[#C4321A]">RENT</span>
        </p>
      </header>

      <h1 className="mt-10 text-4xl font-extrabold leading-tight text-[#0B0F19]">
        Arrete de payer le zem pour rien.
      </h1>
      <p className="mt-4 text-lg text-[#1E2635]">
        Vois le logement en entier avant de te deplacer. Filme sur place par un
        agent, et confirme encore libre.
      </p>

      <a
        href="/telecharger"
        className="mt-8 flex min-h-14 items-center justify-center rounded-full bg-[#D93A1F] px-6 text-lg font-semibold text-white"
      >
        Installer l&apos;application
      </a>
      <p className="mt-2 text-center text-sm text-[#55617A]">
        Android · Cotonou et Abomey-Calavi
      </p>

      <section className="mt-14 space-y-6">
        <Point
          titre="Un deplacement te coute environ 2 000 F"
          corps="Le zem, plus le demarcheur qui « fait deplacer ». Souvent pour decouvrir que le bien est deja loue."
        />
        <Point
          titre="Une visite en 360 te coute 1 000 F"
          corps="Toutes les pieces, depuis chez toi. La premiere est offerte."
        />
        <Point
          titre="Et tu sais si le bien est encore libre"
          corps="Chaque logement porte la date exacte de sa derniere verification. C'est ce que personne d'autre ne garantit."
        />
      </section>

      <section className="mt-14 rounded-2xl border border-[#E2E8F0] p-5">
        <h2 className="font-bold text-[#0B0F19]">Tu as un bien a louer ?</h2>
        <p className="mt-2 text-[#1E2635]">
          Publie gratuitement. Tu ne recois que des visiteurs qui ont deja vu
          ton logement en entier.
        </p>
        <a
          href="/telecharger"
          className="mt-4 inline-flex min-h-12 items-center rounded-full border-2 border-[#C4321A] px-5 font-semibold text-[#C4321A]"
        >
          Publier un bien
        </a>
      </section>

      <footer className="mt-16 text-sm text-[#55617A]">
        <p>EAZYRENT · Cotonou, Benin</p>
        <p className="mt-2">
          <a href="/confidentialite" className="underline">
            Politique de donnees
          </a>
          {' · '}
          <a href="/conditions" className="underline">
            Conditions
          </a>
        </p>
      </footer>
    </main>
  )
}

function Point({ titre, corps }: { titre: string; corps: string }) {
  return (
    <div>
      <h2 className="font-bold text-[#0B0F19]">{titre}</h2>
      <p className="mt-1 text-[#1E2635]">{corps}</p>
    </div>
  )
}
