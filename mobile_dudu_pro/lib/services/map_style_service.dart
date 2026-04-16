import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/senegal_map.dart';

/// Applique un style de carte moderne (type Yango) + bornes Sénégal.
abstract final class MapStyleService {
  MapStyleService._();

  static const String yangoLikeStyle = r'''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#2b2b2b"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"},{"weight":3}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f2f2f2"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#f7f7f7"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#cfe8ff"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f6f7f9"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#d4d8de"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#2b2b2b"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#2b2b2b"}]}
]
''';

  static final CameraTargetBounds senegalBounds =
      CameraTargetBounds(SenegalMap.countryBounds);

  static const MinMaxZoomPreference zoomPreference =
      MinMaxZoomPreference(5.8, 20.0);

  static Future<void> apply(GoogleMapController controller) async {
    try {
      await controller.setMapStyle(yangoLikeStyle);
    } catch (_) {}
  }
}

