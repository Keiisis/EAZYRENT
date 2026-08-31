// Formatage FCFA — UI_DESIGN_SYSTEM.md §10.
//
// `35 000 F` — espace insécable fine comme séparateur, `F` dans les listes
// (gain de place), `FCFA` en toutes lettres sur les écrans de paiement où
// l'ambiguïté coûte cher.
//
// JAMAIS de décimales : `35 000,00 F` est du bruit.

abstract final class MoneyFcfa {
  /// Espace insécable fine (U+202F). Un espace ordinaire laisserait le
  /// montant se couper en fin de ligne — un loyer coupé en deux est illisible.
  static const _sep = ' ';

  /// Listes, cartes, filtres. Ex. `35 000 F`
  static String short(int amount) => '${_group(amount)}${_sep}F';

  /// Écrans de paiement, contrats, quittances. Ex. `245 000 FCFA`
  static String full(int amount) => '${_group(amount)}${_sep}FCFA';

  /// Sans unité, pour un tableau déjà titré. Ex. `245 000`
  static String bare(int amount) => _group(amount);

  static String _group(int amount) {
    final negative = amount < 0;
    final digits = amount.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_sep);
      buffer.write(digits[i]);
    }
    return negative ? '-${buffer.toString()}' : buffer.toString();
  }
}
