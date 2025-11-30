import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _apiKey = 'AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Autocomplete des adresses
  static Future<List<PlaceSuggestion>> getPlaceSuggestions(String input, {double? userLat, double? userLng}) async {
    if (input.isEmpty) return [];

    // Bias vers Dakar pour des résultats plus pertinents
    final dakarLat = userLat ?? 14.6928;
    final dakarLng = userLng ?? -17.4467;
    final radius = 50000; // 50km autour de la position

    final encodedInput = Uri.encodeComponent(input);

    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=$encodedInput&key=$_apiKey&language=fr&location=$dakarLat,$dakarLng&radius=$radius&strictbounds=false',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        print('Places autocomplete status (SN bias): $status');

        if (status == 'OK') {
          final predictions = data['predictions'] as List;
          print('Places autocomplete predictions (SN bias) count: ${predictions.length}');
          if (predictions.isNotEmpty) {
            final results = <PlaceSuggestion>[];
            for (final p in predictions) {
              try {
                results.add(PlaceSuggestion.fromJson(p as Map<String, dynamic>));
              } catch (e) {
                print('Erreur parsing suggestion (SN bias): $e');
              }
            }
            return results;
          }
        }
      }

      // Fallback : requête globale sans restriction pays / localisation
      final globalUrl = Uri.parse(
        '$_baseUrl/autocomplete/json?input=$encodedInput&key=$_apiKey&language=fr',
      );

      final globalResponse = await http.get(globalUrl);
      if (globalResponse.statusCode == 200) {
        final data = json.decode(globalResponse.body);
        final status = data['status'];
        print('Places autocomplete status (global): $status');

        if (status == 'OK') {
          final predictions = data['predictions'] as List;
          final results = <PlaceSuggestion>[];
          for (final p in predictions) {
            try {
              results.add(PlaceSuggestion.fromJson(p as Map<String, dynamic>));
            } catch (e) {
              print('Erreur parsing suggestion (global): $e');
            }
          }
          return results;
        }
      }

      return [];
    } catch (e) {
      print('Erreur autocomplete: $e');
      return [];
    }
  }

  /// Obtenir les détails d'un lieu (coordonnées)
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey&language=fr&fields=geometry,formatted_address,name',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }

      return null;
    } catch (e) {
      print('Erreur details lieu: $e');
      return null;
    }
  }

  /// Géocodage inverse (coordonnées → adresse)
  static Future<String> reverseGeocode(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey&language=fr',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }

      return 'Dakar, Sénégal';
    } catch (e) {
      print('Erreur géocodage inverse: $e');
      return 'Dakar, Sénégal';
    }
  }
  
  /// Géocodage (adresse → coordonnées GPS)
  static Future<PlaceDetails?> geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey&language=fr&components=country:sn',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          
          return PlaceDetails(
            latitude: location['lat'],
            longitude: location['lng'],
            formattedAddress: result['formatted_address'],
            name: address,
          );
        }
      }

      return null;
    } catch (e) {
      print('Erreur géocodage adresse: $e');
      return null;
    }
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>?;
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structured != null ? (structured['main_text'] ?? '') : '',
      secondaryText: structured != null ? (structured['secondary_text'] ?? '') : '',
    );
  }
}

class PlaceDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String name;

  PlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.name,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return PlaceDetails(
      latitude: location['lat'],
      longitude: location['lng'],
      formattedAddress: json['formatted_address'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

