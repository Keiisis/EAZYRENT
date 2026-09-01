/// Les types de bien, et LE SEUL endroit qui traduit entre ce que la base
/// stocke et ce que l'utilisateur lit.
///
/// La base connaît exactement cinq valeurs (`property_type_enum` :
/// `room`, `apartment`, `villa_house`, `land`, `commercial`). L'interface
/// proposait, elle, « Studio », « Appartement », « 2 chambres-salon » — des
/// libellés qui n'existent nulle part côté serveur.
///
/// Conséquence exacte du décalage : un filtre par type envoyait
/// `property_type = 'Chambre-salon'` à une colonne qui contient `apartment`.
/// Zéro résultat, sans message d'erreur — la pire forme de panne, celle qui
/// ressemble à « il n'y a rien à louer ».
///
/// D'où cette table unique, utilisée par l'onboarding, la feuille de filtres
/// ET la source de données. Proposer cinq filtres qui marchent vaut mieux
/// qu'en proposer huit dont trois ne rendent jamais rien.
abstract final class PropertyTypes {
  /// Libellé lu par l'utilisateur → code stocké en base.
  ///
  /// Vocabulaire local : « Chambre-salon », jamais « T2 » ni « F3 ».
  static const labelToCode = <String, String>{
    'Chambre': 'room',
    'Chambre-salon': 'apartment',
    'Villa': 'villa_house',
    'Boutique': 'commercial',
    'Terrain': 'land',
  };

  /// Ordre d'affichage : celui de la fréquence réelle sur le marché du Grand
  /// Nokoué, pas l'ordre alphabétique ni celui de l'enum SQL.
  static const labels = <String>[
    'Chambre-salon',
    'Chambre',
    'Villa',
    'Boutique',
    'Terrain',
  ];

  /// `null` si le code est inconnu : une valeur ajoutée en base sans passer
  /// par ici doit se voir, pas se déguiser en « Chambre ».
  static String labelOf(String? code) => switch (code) {
    'room' => 'Chambre',
    'apartment' => 'Chambre-salon',
    'villa_house' => 'Villa',
    'commercial' => 'Boutique',
    'land' => 'Terrain',
    _ => 'Logement',
  };

  static String? codeOf(String? label) =>
      label == null ? null : labelToCode[label];
}
