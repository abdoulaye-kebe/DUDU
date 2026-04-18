import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';

/// Repères Google Maps pour le Sénégal (app client).
abstract final class SenegalMap {
  SenegalMap._();

  /// Dakar — aligné sur [AppConfig].
  static const LatLng dakar = LatLng(
    AppConfig.defaultLatitude,
    AppConfig.defaultLongitude,
  );

  /// Centre approximatif du pays — vue d’ensemble (sans GPS ou avant fix).
  static const LatLng countryOverviewCenter = LatLng(14.52, -14.35);

  /// Zoom pour voir l’essentiel du territoire sur un petit widget carte.
  static const double countryOverviewZoom = 6.75;

  /// Bornes du territoire.
  static final LatLngBounds countryBounds = LatLngBounds(
    southwest: const LatLng(12.3071, -17.5352),
    northeast: const LatLng(16.6919, -11.3459),
  );

  /// Cadre la caméra sur le pays (padding des bords en pixels logiques).
  static CameraUpdate fitCountry(double paddingPx) =>
      CameraUpdate.newLatLngBounds(countryBounds, paddingPx);

  /// Point dans le rectangle pays (évite l’ancienne règle `longitude <= -11` qui excluait l’est du Sénégal).
  static bool containsCoordinates(double latitude, double longitude) {
    return countryBounds.contains(LatLng(latitude, longitude));
  }
}

