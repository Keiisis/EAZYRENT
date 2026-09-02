// Les quatre fournisseurs de paiement, en un seul endroit.
//
// TOUT CE QUI DIFFÈRE ENTRE EUX EST ICI, ET NULLE PART AILLEURS. Un
// fournisseur ajouté demain ne touche ni `create-payment`, ni
// `verify-payment`, ni une seule ligne de Flutter.
//
// Les cinq pièges, tous rencontrés dans RETOUR GAGNANT TEMPLATE et tous
// traités ci-dessous :
//
//   · XOF EST ZERO-DECIMAL chez Stripe. `amount: 1000 * 100` facture
//     100 000 F pour un pass à 1 000 F. Le template maintient explicitement
//     la liste des devises zero-decimal ; on fait pareil.
//   · FEDAPAY ATTEND UN PAYLOAD PLAT, avec `currency: { iso }`. Le wrapper
//     `{ transaction: {...} }` que suggère l'intuition est refusé.
//   · KKIAPAY ET FEDAPAY NE TRAITENT QUE LE XOF. Leur envoyer des euros
//     produit un refus que l'utilisateur ne peut pas comprendre.
//   · STRIPE ET REVOLUT travaillent en centimes pour l'euro, mais PAS pour
//     le franc CFA.
//   · SANDBOX ET PRODUCTION ont des adresses différentes chez tous.

export type ProviderName = 'kkiapay' | 'fedapay' | 'stripe' | 'revolut'

/// Devises sans sous-unité. Le franc CFA en fait partie : 1 000 XOF
/// s'envoie « 1000 », jamais « 100000 ».
const ZERO_DECIMAL = new Set([
  'BIF', 'CLP', 'DJF', 'GNF', 'JPY', 'KMF', 'KRW', 'MGA',
  'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
])

/// LA fonction qui évite de facturer cent fois trop cher.
export function toProviderAmount(amountFcfa: number, currency: string): number {
  if (!Number.isInteger(amountFcfa) || amountFcfa <= 0) {
    throw new Error(`montant invalide: ${amountFcfa}`)
  }
  return ZERO_DECIMAL.has(currency.toUpperCase())
    ? amountFcfa
    : Math.round(amountFcfa * 100)
}

export interface Settings {
  [key: string]: string
}

export interface CreateArgs {
  reference: string
  amountFcfa: number
  description: string
  customerEmail?: string
  customerPhone?: string
  returnUrl: string
  settings: Settings
}

export interface CreateResult {
  checkoutUrl: string
  providerRef: string
}

// ─────────────────────────────────────────────────────────────────────────
// KKIAPAY
// ─────────────────────────────────────────────────────────────────────────
//
// On n'utilise PAS le SDK mobile : dans le template, son provider démontait
// tout l'arbre React à l'ouverture du widget — « c'est ce que l'on prenait
// pour l'application redémarre ». On passe par la page hébergée, ouverte
// dans une vue web par-dessus l'application.
async function createKkiapay(a: CreateArgs): Promise<CreateResult> {
  const key = a.settings.kkiapay_private_key
  const sandbox = a.settings.kkiapay_sandbox === 'true'
  if (!key) throw new Error('KkiaPay non configuré')

  const base = sandbox
    ? 'https://api-sandbox.kkiapay.me'
    : 'https://api.kkiapay.me'

  const res = await fetch(`${base}/api/v1/payments/init`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-api-key': key },
    body: JSON.stringify({
      // XOF : aucune multiplication.
      amount: toProviderAmount(a.amountFcfa, 'XOF'),
      reason: a.description,
      // Notre référence voyage avec la transaction : c'est elle qu'on
      // retrouvera à la vérification, pas l'identifiant du fournisseur.
      partnerId: a.reference,
      callback: a.returnUrl,
      phone: a.customerPhone ?? undefined,
      email: a.customerEmail ?? undefined,
    }),
  })

  if (!res.ok) throw new Error(`kkiapay ${res.status}: ${await res.text()}`)
  const data = await res.json()
  return {
    checkoutUrl: data.payment_url ?? data.url,
    providerRef: data.transactionId ?? data.id ?? a.reference,
  }
}

// ─────────────────────────────────────────────────────────────────────────
// FEDAPAY
// ─────────────────────────────────────────────────────────────────────────
async function createFedapay(a: CreateArgs): Promise<CreateResult> {
  const key = a.settings.fedapay_secret_key
  const sandbox = a.settings.fedapay_sandbox === 'true'
  if (!key) throw new Error('FedaPay non configuré')

  const base = sandbox
    ? 'https://sandbox-api.fedapay.com'
    : 'https://api.fedapay.com'

  // PAYLOAD PLAT. Pas de `{ transaction: {...} }` — vérifié dans le
  // template : « FedaPay API : structure PLATE (pas de wrapper transaction) ».
  const payload: Record<string, unknown> = {
    amount: toProviderAmount(a.amountFcfa, 'XOF'),
    description: a.description,
    currency: { iso: 'XOF' },
    callback_url: a.returnUrl,
  }
  if (a.customerEmail || a.customerPhone) {
    const customer: Record<string, unknown> = {}
    if (a.customerEmail) customer.email = a.customerEmail
    if (a.customerPhone) {
      customer.phone_number = { number: a.customerPhone, country: 'BJ' }
    }
    payload.customer = customer
  }

  const created = await fetch(`${base}/v1/transactions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${key}`,
    },
    body: JSON.stringify(payload),
  })
  if (!created.ok) {
    throw new Error(`fedapay ${created.status}: ${await created.text()}`)
  }
  const tx = (await created.json())['v1/transaction']

  // FedaPay demande un second appel pour obtenir le lien de paiement.
  // L'oublier rend une transaction créée que personne ne peut payer.
  const tokenRes = await fetch(`${base}/v1/transactions/${tx.id}/token`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}` },
  })
  if (!tokenRes.ok) throw new Error(`fedapay token ${tokenRes.status}`)
  const token = await tokenRes.json()

  return { checkoutUrl: token.url, providerRef: String(tx.id) }
}

// ─────────────────────────────────────────────────────────────────────────
// STRIPE — diaspora
// ─────────────────────────────────────────────────────────────────────────
async function createStripe(a: CreateArgs): Promise<CreateResult> {
  const key = a.settings.stripe_secret_key
  if (!key) throw new Error('Stripe non configuré')

  // Stripe accepte le XOF, et le traite comme zero-decimal. C'est ce qui
  // permet à la diaspora de payer en francs, sans conversion inventée par
  // nous — donc sans écart entre ce qui est annoncé et ce qui est débité.
  const body = new URLSearchParams({
    mode: 'payment',
    'line_items[0][price_data][currency]': 'xof',
    'line_items[0][price_data][unit_amount]': String(
      toProviderAmount(a.amountFcfa, 'XOF'),
    ),
    'line_items[0][price_data][product_data][name]': a.description,
    'line_items[0][quantity]': '1',
    success_url: `${a.returnUrl}?ref=${a.reference}&status=ok`,
    cancel_url: `${a.returnUrl}?ref=${a.reference}&status=cancel`,
    client_reference_id: a.reference,
  })
  if (a.customerEmail) body.set('customer_email', a.customerEmail)

  const res = await fetch('https://api.stripe.com/v1/checkout/sessions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  })
  if (!res.ok) throw new Error(`stripe ${res.status}: ${await res.text()}`)
  const session = await res.json()
  return { checkoutUrl: session.url, providerRef: session.id }
}

// ─────────────────────────────────────────────────────────────────────────
// REVOLUT — diaspora
// ─────────────────────────────────────────────────────────────────────────
async function createRevolut(a: CreateArgs): Promise<CreateResult> {
  const key = a.settings.revolut_secret_key
  const sandbox = a.settings.revolut_sandbox === 'true'
  if (!key) throw new Error('Revolut non configuré')

  const base = sandbox
    ? 'https://sandbox-merchant.revolut.com'
    : 'https://merchant.revolut.com'

  // Revolut Merchant ne traite pas le XOF. On facture donc en EUR, et le
  // taux est LU dans les réglages plutôt qu'inventé ici : un taux codé en
  // dur devient faux le mois suivant, et la différence sort de notre poche.
  const rate = Number(a.settings.eur_xof_rate ?? '655.957')
  const amountEurCents = Math.round((a.amountFcfa / rate) * 100)

  const res = await fetch(`${base}/api/orders`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${key}`,
      'Revolut-Api-Version': '2024-09-01',
    },
    body: JSON.stringify({
      amount: amountEurCents, // EUR : centimes, contrairement au XOF.
      currency: 'EUR',
      description: a.description,
      merchant_order_data: { reference: a.reference },
      redirect_url: `${a.returnUrl}?ref=${a.reference}`,
    }),
  })
  if (!res.ok) throw new Error(`revolut ${res.status}: ${await res.text()}`)
  const order = await res.json()
  return {
    checkoutUrl: order.checkout_url,
    providerRef: order.id,
  }
}

export function createWithProvider(
  provider: ProviderName,
  args: CreateArgs,
): Promise<CreateResult> {
  switch (provider) {
    case 'kkiapay':
      return createKkiapay(args)
    case 'fedapay':
      return createFedapay(args)
    case 'stripe':
      return createStripe(args)
    case 'revolut':
      return createRevolut(args)
  }
}

// ─────────────────────────────────────────────────────────────────────────
// VÉRIFICATION
// ─────────────────────────────────────────────────────────────────────────
//
// On RELIT le fournisseur. On ne croit jamais ni le client, ni un paramètre
// d'URL de retour : `?status=ok` est écrit par le navigateur, donc par
// n'importe qui.
export async function isPaidAtProvider(
  provider: ProviderName,
  providerRef: string,
  settings: Settings,
): Promise<boolean> {
  switch (provider) {
    case 'kkiapay': {
      const sandbox = settings.kkiapay_sandbox === 'true'
      const base = sandbox
        ? 'https://api-sandbox.kkiapay.me'
        : 'https://api.kkiapay.me'
      const res = await fetch(`${base}/api/v1/transactions/status`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': settings.kkiapay_private_key,
          's-api-key': settings.kkiapay_secret ?? '',
        },
        body: JSON.stringify({ transactionId: providerRef }),
      })
      if (!res.ok) return false
      const d = await res.json()
      return d.status === 'SUCCESS'
    }
    case 'fedapay': {
      const sandbox = settings.fedapay_sandbox === 'true'
      const base = sandbox
        ? 'https://sandbox-api.fedapay.com'
        : 'https://api.fedapay.com'
      const res = await fetch(`${base}/v1/transactions/${providerRef}`, {
        headers: { Authorization: `Bearer ${settings.fedapay_secret_key}` },
      })
      if (!res.ok) return false
      const d = await res.json()
      return d['v1/transaction']?.status === 'approved'
    }
    case 'stripe': {
      const res = await fetch(
        `https://api.stripe.com/v1/checkout/sessions/${providerRef}`,
        { headers: { Authorization: `Bearer ${settings.stripe_secret_key}` } },
      )
      if (!res.ok) return false
      const d = await res.json()
      return d.payment_status === 'paid'
    }
    case 'revolut': {
      const sandbox = settings.revolut_sandbox === 'true'
      const base = sandbox
        ? 'https://sandbox-merchant.revolut.com'
        : 'https://merchant.revolut.com'
      const res = await fetch(`${base}/api/orders/${providerRef}`, {
        headers: {
          Authorization: `Bearer ${settings.revolut_secret_key}`,
          'Revolut-Api-Version': '2024-09-01',
        },
      })
      if (!res.ok) return false
      const d = await res.json()
      return d.state === 'completed'
    }
  }
}
