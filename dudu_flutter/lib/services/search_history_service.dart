import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service pour gérer l'historique des recherches de destinations
class SearchHistoryService {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryItems = 3;

  /// Récupérer l'historique des recherches
  static Future<List<SearchHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = json.decode(historyJson);
      return decoded
          .map((item) => SearchHistoryItem.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  /// Ajouter une destination à l'historique
  static Future<void> addToHistory(SearchHistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<SearchHistoryItem> history = await getHistory();

      // Supprimer l'élément s'il existe déjà (éviter les doublons)
      history.removeWhere((h) => 
        h.title.toLowerCase() == item.title.toLowerCase() &&
        h.subtitle.toLowerCase() == item.subtitle.toLowerCase()
      );

      // Ajouter le nouvel élément au début
      history.insert(0, item);

      // Garder seulement les 3 derniers éléments
      if (history.length > _maxHistoryItems) {
        history = history.sublist(0, _maxHistoryItems);
      }

      // Sauvegarder
      final String encoded = json.encode(
        history.map((h) => h.toJson()).toList()
      );
      await prefs.setString(_historyKey, encoded);
    } catch (e) {
      print('❌ Erreur lors de l\'ajout à l\'historique: $e');
    }
  }

  /// Effacer tout l'historique
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('❌ Erreur lors de l\'effacement de l\'historique: $e');
    }
  }

  /// Supprimer un élément spécifique de l'historique
  static Future<void> removeFromHistory(SearchHistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<SearchHistoryItem> history = await getHistory();

      history.removeWhere((h) => 
        h.title == item.title && h.subtitle == item.subtitle
      );

      final String encoded = json.encode(
        history.map((h) => h.toJson()).toList()
      );
      await prefs.setString(_historyKey, encoded);
    } catch (e) {
      print('❌ Erreur lors de la suppression de l\'historique: $e');
    }
  }
}

/// Modèle pour un élément de l'historique de recherche
class SearchHistoryItem {
  final String title;
  final String subtitle;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  SearchHistoryItem({
    required this.title,
    required this.subtitle,
    this.latitude,
    this.longitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'SearchHistoryItem(title: $title, subtitle: $subtitle)';
  }
}
