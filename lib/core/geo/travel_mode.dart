import 'package:flutter/material.dart';

/// Les quatre façons de se rendre à un bien au Grand Nokoué.
///
/// L'ORDRE N'EST PAS CELUI DE GOOGLE MAPS. Le zémidjan vient en premier parce
/// qu'il est le mode dominant à Cotonou : c'est lui qu'on prend pour aller
/// visiter, pas une voiture qu'on ne possède pas. Mettre « voiture » d'abord
/// serait recopier une hiérarchie occidentale sur un marché qui n'est pas le
/// sien.
enum TravelMode {
  /// Zémidjan. Valhalla l'appelle `motorcycle`.
  zem,
  walk,
  bike,
  car;

  /// Le profil de coût Valhalla correspondant.
  String get costing => switch (this) {
    TravelMode.zem => 'motorcycle',
    TravelMode.walk => 'pedestrian',
    TravelMode.bike => 'bicycle',
    TravelMode.car => 'auto',
  };

  String get label => switch (this) {
    TravelMode.zem => 'Zem',
    TravelMode.walk => 'À pied',
    TravelMode.bike => 'Vélo',
    TravelMode.car => 'Voiture',
  };

  IconData get icon => switch (this) {
    TravelMode.zem => Icons.two_wheeler,
    TravelMode.walk => Icons.directions_walk,
    TravelMode.bike => Icons.pedal_bike,
    TravelMode.car => Icons.directions_car,
  };

  /// Ce qu'on peut honnêtement dire de la valeur affichée.
  ///
  /// Valhalla ne dispose d'AUCUNE donnée de trafic sur Cotonou, et son profil
  /// `motorcycle` ne modélise pas le faufilage entre les files — mesuré : il
  /// rend exactement la même durée que la voiture sur le trajet
  /// Ganhi → Fidjrossè (13 min pour 6,33 km).
  ///
  /// On affiche donc le chiffre du moteur, et on nomme sa limite. Inventer un
  /// coefficient « zem = voiture × 0,7 » produirait un nombre plus flatteur et
  /// tout aussi faux, avec en plus l'apparence de la mesure.
  bool get sharesCarTiming => this == TravelMode.zem;
}
