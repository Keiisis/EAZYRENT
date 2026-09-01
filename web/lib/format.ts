/**
 * Formatage FCFA — identique a lib/core/utils/money_fcfa.dart cote mobile.
 * Les deux surfaces doivent afficher le meme montant de la meme facon.
 *
 * Espace insecable fine (U+202F) comme separateur : un espace ordinaire
 * laisserait « 35 000 F » se couper en fin de ligne.
 * Jamais de decimales : « 35 000,00 F » est du bruit.
 */
const SEP = ' '

function group(amount: number): string {
  const n = Math.round(Math.abs(amount)).toString()
  let out = ''
  for (let i = 0; i < n.length; i++) {
    if (i > 0 && (n.length - i) % 3 === 0) out += SEP
    out += n[i]
  }
  return amount < 0 ? `-${out}` : out
}

/** Listes et cartes. Ex. « 35 000 F » */
export const short = (amount: number) => `${group(amount)}${SEP}F`

/** Paiements et contrats, ou l'ambiguite coute cher. Ex. « 245 000 FCFA » */
export const full = (amount: number) => `${group(amount)}${SEP}FCFA`

/**
 * Fraicheur — le composant n°2 de la Visite Verifiee (UX_CORE_SPEC.md §2.1).
 * L'horodatage est ABSOLU et precis : la precision EST la preuve.
 */
export function freshness(checkedAt: string | null): {
  label: string
  tone: 'ok' | 'warn' | 'stale'
} {
  if (!checkedAt) return { label: 'Non verifie', tone: 'stale' }

  const d = new Date(checkedAt)
  const now = new Date()

  // JOUR CALENDAIRE, pas heures ecoulees. Une verification de 23h48 vue a
  // 07h48 date de 8 heures, mais elle a eu lieu HIER. Meme correctif que
  // Freshness.from() cote mobile : les deux surfaces doivent dire la meme
  // chose du meme bien, y compris quand elles se trompent... surtout quand
  // elles risquent de se tromper.
  const midnight = (x: Date) =>
    new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime()
  const days = Math.round((midnight(now) - midnight(d)) / 86_400_000)

  const hhmm = d.toLocaleTimeString('fr-FR', {
    hour: '2-digit',
    minute: '2-digit',
  })

  if (days <= 0) return { label: `Verifie aujourd'hui a ${hhmm}`, tone: 'ok' }
  if (days === 1) return { label: `Verifie hier a ${hhmm}`, tone: 'ok' }
  if (days <= 7) return { label: `Verifie il y a ${days} jours`, tone: 'warn' }
  // Miroir du raccourci applique cote mobile : la carte de 384 dp coupait
  // « Non confirme depuis 12 jours » sur le nombre de jours, c'est-a-dire sur
  // la seule partie qui dit a quel point l'information est vieille.
  return { label: `Non confirme · ${days} jours`, tone: 'stale' }
}
