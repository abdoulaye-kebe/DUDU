import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service pour calculer les itinéraires avec Google Directions API
class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _apiKey = 'AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA';

  /// Calculer un itinéraire entre deux points
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving', // driving, walking, bicycling, transit
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$travelMode'
        '&key=$_apiKey'
        '&language=fr'
        '&region=sn', // Sénégal
      );

      print('🗺️ Calcul itinéraire: ${origin.latitude},${origin.longitude} -> ${destination.latitude},${destination.longitude}');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Décoder la polyline
          final points = _decodePolyline(route['overview_polyline']['points']);
          
          return DirectionsResult(
            distance: leg['distance']['value'] / 1000.0, // en km
            duration: leg['duration']['value'] / 60.0, // en minutes
            distanceText: leg['distance']['text'],
            durationText: leg['duration']['text'],
            points: points,
            startAddress: leg['start_address'],
            endAddress: leg['end_address'],
            steps: _parseSteps(leg['steps']),
          );
        } else {
          print('❌ Erreur Directions API: ${data['status']}');
          return null;
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return null;
      }
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



