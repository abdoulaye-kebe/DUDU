import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';

/// Service pour calculer les itinéraires avec Google Directions API
class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Calculer un itinéraire entre deux points
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving', // driving, walking, bicycling, transit
    bool alternatives = true,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$travelMode'
        '&alternatives=${alternatives ? 'true' : 'false'}'
        '&key=${AppConfig.googleMapsApiKey}'
        '&language=fr'
        '&region=sn', // Sénégal
      );

      print('🗺️ Calcul itinéraire: ${origin.latitude},${origin.longitude} -> ${destination.latitude},${destination.longitude}');
      
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      if (data['status'] != 'OK' || data['routes'] == null || data['routes'].isEmpty) {
        print('❌ Erreur Directions API: ${data['status']}');
        return null;
      }

      Map<String, dynamic>? bestRoute;
      Map<String, dynamic>? bestLeg;
      int? bestDistance;

      for (final r in data['routes']) {
        if (r is! Map) continue;
        final legs = r['legs'];
        if (legs is! List || legs.isEmpty) continue;
        final leg = legs[0];
        if (leg is! Map) continue;
        final dist = leg['distance'];
        if (dist is! Map) continue;
        final distValue = dist['value'];
        if (distValue is! num) continue;

        final d = distValue.toInt();
        if (bestDistance == null || d < bestDistance!) {
          bestDistance = d;
          bestRoute = Map<String, dynamic>.from(r.map((k, v) => MapEntry(k.toString(), v)));
          bestLeg = Map<String, dynamic>.from(leg.map((k, v) => MapEntry(k.toString(), v)));
        }
      }

      if (bestRoute == null || bestLeg == null) {
        print('⚠️ Impossible de sélectionner un itinéraire');
        return null;
      }

      final overview = bestRoute!['overview_polyline'];
      final polyline = overview is Map ? overview['points']?.toString() : null;
      final points = polyline != null ? _decodePolyline(polyline) : <LatLng>[];

      final distanceMap = bestLeg!['distance'] as Map;
      final durationMap = bestLeg!['duration'] as Map;
      final stepsData = bestLeg!['steps'];

      return DirectionsResult(
        distance: (distanceMap['value'] as num).toDouble() / 1000.0,
        duration: (durationMap['value'] as num).toDouble() / 60.0,
        distanceText: distanceMap['text']?.toString() ?? '',
        durationText: durationMap['text']?.toString() ?? '',
        points: points,
        startAddress: bestLeg!['start_address']?.toString() ?? '',
        endAddress: bestLeg!['end_address']?.toString() ?? '',
        steps: stepsData is List ? _parseSteps(stepsData) : <RouteStep>[],
      );
    } catch (e) {
      print('❌ Erreur calcul itinéraire: $e');
      return null;
    }
  }

  /// Décoder une polyline encodée de Google Maps
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int deltaLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  /// Parser les étapes de l'itinéraire
  static List<RouteStep> _parseSteps(List<dynamic> stepsData) {
    return stepsData.map((step) {
      return RouteStep(
        distance: step['distance']['value'] / 1000.0,
        duration: step['duration']['value'] / 60.0,
        instruction: step['html_instructions']
            .replaceAll(RegExp(r'<[^>]*>'), ''), // Enlever les balises HTML
        points: _decodePolyline(step['polyline']['points']),
      );
    }).toList();
  }
}

/// Résultat d'un calcul d'itinéraire
class DirectionsResult {
  final double distance; // en km
  final double duration; // en minutes
  final String distanceText;
  final String durationText;
  final List<LatLng> points;
  final String startAddress;
  final String endAddress;
  final List<RouteStep> steps;

  DirectionsResult({
    required this.distance,
    required this.duration,
    required this.distanceText,
    required this.durationText,
    required this.points,
    required this.startAddress,
    required this.endAddress,
    required this.steps,
  });
}

/// Étape d'un itinéraire
class RouteStep {
  final double distance;
  final double duration;
  final String instruction;
  final List<LatLng> points;

  RouteStep({
    required this.distance,
    required this.duration,
    required this.instruction,
    required this.points,
  });
}




