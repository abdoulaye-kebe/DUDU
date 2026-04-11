import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'places_service.dart';

/// Itinéraire routier via Google Directions API (même clé que Places).
class DirectionsRouteResult {
  DirectionsRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceKm;
  final int durationSeconds;
}

class DirectionsService {
  static final PolylinePoints _polylinePoints = PolylinePoints();

  /// Dernière erreur renvoyée par l’API Directions (status + message Google), pour l’UI / debug.
  static String? lastFailureDetail;

  static void _setFailure(String detail) {
    lastFailureDetail = detail;
    if (kDebugMode) {
      debugPrint('🗺️ Directions API: $detail');
    }
  }

  /// Trajet détaillé : concatène les polylines de **chaque étape** (virages, rues, sens uniques).
  /// Si les étapes manquent, utilise l’overview (toujours sur le réseau routier, pas une ligne droite).
  static List<LatLng>? _pointsFromRoute(Map<String, dynamic> route) {
    final legs = route['legs'] as List<dynamic>?;
    if (legs != null && legs.isNotEmpty) {
      final List<LatLng> merged = [];
      for (final leg in legs) {
        final legMap = leg as Map<String, dynamic>;
        final steps = legMap['steps'] as List<dynamic>?;
        if (steps == null) continue;
        for (final step in steps) {
          final stepMap = step as Map<String, dynamic>;
          final poly = stepMap['polyline'] as Map<String, dynamic>?;
          final encoded = poly?['points'] as String?;
          if (encoded == null || encoded.isEmpty) continue;
          final decoded = _polylinePoints.decodePolyline(encoded);
          for (final p in decoded) {
            final ll = LatLng(p.latitude, p.longitude);
            if (merged.isEmpty ||
                merged.last.latitude != ll.latitude ||
                merged.last.longitude != ll.longitude) {
              merged.add(ll);
            }
          }
        }
      }
      if (merged.length >= 2) {
        return merged;
      }
    }

    final overview = route['overview_polyline'] as Map<String, dynamic>?;
    final encoded = overview?['points'] as String?;
    if (encoded == null || encoded.isEmpty) return null;

    final decoded = _polylinePoints.decodePolyline(encoded);
    if (decoded.length < 2) return null;

    return decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  static Future<DirectionsRouteResult?> getDrivingRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    lastFailureDetail = null;
    final key = PlacesService.mapsApiKey;
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=driving'
      '&language=fr'
      '&region=sn'
      '&key=$key',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        _setFailure('HTTP ${res.statusCode}');
        return null;
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN';

      if (status != 'OK') {
        final msg = data['error_message'] as String? ?? '';
        _setFailure('$status${msg.isNotEmpty ? ': $msg' : ''}');
        return null;
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        _setFailure('OK mais aucune route');
        return null;
      }

      final route = routes.first as Map<String, dynamic>;
      final points = _pointsFromRoute(route);
      if (points == null || points.length < 2) {
        _setFailure('Polyline vide ou invalide');
        return null;
      }

      final legs = route['legs'] as List<dynamic>?;
      double meters = 0;
      int seconds = 0;
      if (legs != null) {
        for (final leg in legs) {
          final m = leg['distance']?['value'];
          final s = leg['duration']?['value'];
          if (m is num) meters += m.toDouble();
          if (s is num) seconds += s.round();
        }
      }

      return DirectionsRouteResult(
        points: points,
        distanceKm: meters / 1000.0,
        durationSeconds: seconds,
      );
    } catch (e, st) {
      _setFailure('$e');
      if (kDebugMode) {
        debugPrint('$st');
      }
      return null;
    }
  }
}
