import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/driver_profile.dart';
import '../models/ride.dart';
import 'api_service.dart'; // Pour SubscriptionPlan

/// Service Firebase pour remplacer l'API service
/// Permet la collaboration en temps réel via Firestore
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections Firestore
  static const String driversCollection = 'drivers';
  static const String ridesCollection = 'rides';
  static const String subscriptionsCollection = 'subscriptions';
  static const String subscriptionPlansCollection = 'subscription_plans';
  static const String notificationsCollection = 'notifications';

  // Getters
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;
  User? get currentUser => _auth.currentUser;

  // ============================================
  // AUTHENTIFICATION
  // ============================================

  /// Connexion avec téléphone et mot de passe
  Future<UserCredential> signInWithPhoneAndPassword({
    required String phone,
    required String password,
  }) async {
    try {
      // Vérifier si l'utilisateur existe dans Firestore
      final driverQuery = await _firestore
          .collection(driversCollection)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (driverQuery.docs.isEmpty) {
        throw Exception('Aucun chauffeur trouvé avec ce numéro de téléphone');
      }

      final driverData = driverQuery.docs.first.data();
      final email = driverData['email'] as String? ?? '$phone@dudu.sn';

      // Utiliser l'email pour l'authentification Firebase
      // Note: Pour production, vous devriez utiliser Firebase Phone Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Inscription d'un nouveau chauffeur
  Future<UserCredential> signUpDriver({
    required String phone,
    required String email,
    required String password,
    required Map<String, dynamic> driverData,
  }) async {
    try {
      // Créer l'utilisateur Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Créer le document chauffeur dans Firestore
      final driverId = userCredential.user!.uid;
      await _firestore
          .collection(driversCollection)
          .doc(driverId)
          .set({
            ...driverData,
            'phone': phone,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return userCredential;
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ============================================
  // PROFIL CHAUFFEUR
  // ============================================

  /// Obtenir le profil du chauffeur actuellement connecté
  Future<DriverProfile?> getDriverProfile() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection(driversCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return _mapToDriverProfile(doc.id, data);
    } catch (e) {
      throw Exception('Erreur récupération profil: $e');
    }
  }

  /// Écouter les changements du profil en temps réel
  Stream<DriverProfile?> streamDriverProfile() {
    final userId = currentUser?.uid;
    if (userId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection(driversCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return _mapToDriverProfile(doc.id, doc.data()!);
        });
  }

  /// Mettre à jour le profil du chauffeur
  Future<void> updateDriverProfile(Map<String, dynamic> updates) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _firestore
          .collection(driversCollection)
          .doc(userId)
          .update({
            ...updates,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Erreur mise à jour profil: $e');
    }
  }

  // ============================================
  // STATUT EN LIGNE/HORS LIGNE
  // ============================================

  /// Mettre à jour le statut en ligne/hors ligne
  Future<void> updateOnlineStatus({
    required bool isOnline,
    required bool isAvailable,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final updates = <String, dynamic>{
        'isOnline': isOnline,
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (latitude != null && longitude != null) {
        updates['currentLocation'] = {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Géolocalisation pour les requêtes de proximité
        updates['location'] = GeoPoint(latitude, longitude);
      }

      await _firestore
          .collection(driversCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw Exception('Erreur mise à jour statut: $e');
    }
  }

  // ============================================
  // STATISTIQUES
  // ============================================

  /// Obtenir les statistiques du chauffeur
  Future<DriverStats> getDriverStats() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final doc = await _firestore
          .collection(driversCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('Profil non trouvé');
      }

      final data = doc.data()!;
      return DriverStats.fromJson(data['stats'] ?? {});
    } catch (e) {
      throw Exception('Erreur récupération statistiques: $e');
    }
  }

  // ============================================
  // ABONNEMENTS
  // ============================================

  /// Obtenir les plans d'abonnement disponibles
  Future<List<SubscriptionPlan>> getAvailablePlans(VehicleType vehicleType) async {
    try {
      final query = await _firestore
          .collection(subscriptionPlansCollection)
          .where('vehicleType', isEqualTo: vehicleType.toString())
          .where('isAvailable', isEqualTo: true)
          .orderBy('price')
          .get();

      return query.docs
          .map((doc) {
            final data = doc.data();
            return SubscriptionPlan.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Erreur récupération plans: $e');
    }
  }

  /// Obtenir l'abonnement actuel du chauffeur
  Future<SubscriptionInfo?> getCurrentSubscription() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return null;

      final query = await _firestore
          .collection(subscriptionsCollection)
          .where('driverId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('endDate', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final data = doc.data();
      return SubscriptionInfo.fromJson({
        'id': doc.id,
        ...data,
        'startDate': (data['startDate'] as Timestamp).toDate().toIso8601String(),
        'endDate': (data['endDate'] as Timestamp).toDate().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur récupération abonnement: $e');
    }
  }

  /// Acheter un abonnement
  Future<SubscriptionInfo> purchaseSubscription({
    required String planType,
    required String paymentMethod,
    String? phone,
    bool autoRenew = false,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer le plan
      final planQuery = await _firestore
          .collection(subscriptionPlansCollection)
          .where('type', isEqualTo: planType)
          .limit(1)
          .get();

      if (planQuery.docs.isEmpty) {
        throw Exception('Plan d\'abonnement non trouvé');
      }

      final planDoc = planQuery.docs.first;
      final planData = planDoc.data();

      // Calculer les dates
      final now = DateTime.now();
      final duration = planData['duration'] as int;
      final endDate = now.add(Duration(days: duration));

      // Créer l'abonnement
      final subscriptionRef = await _firestore
          .collection(subscriptionsCollection)
          .add({
            'driverId': userId,
            'planId': planDoc.id,
            'type': planType,
            'name': planData['name'],
            'price': planData['price'],
            'currency': planData['currency'] ?? 'XOF',
            'duration': duration,
            'features': planData['features'] ?? [],
            'status': 'active',
            'startDate': Timestamp.fromDate(now),
            'endDate': Timestamp.fromDate(endDate),
            'paymentMethod': paymentMethod,
            'autoRenew': autoRenew,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Mettre à jour le profil du chauffeur
      await _firestore
          .collection(driversCollection)
          .doc(userId)
          .update({
            'subscription': {
              'id': subscriptionRef.id,
              'type': planType,
              'status': 'active',
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Récupérer l'abonnement créé
      final subscriptionDoc = await subscriptionRef.get();
      final subscriptionData = subscriptionDoc.data()!;
      
      return SubscriptionInfo.fromJson({
        'id': subscriptionDoc.id,
        ...subscriptionData,
        'startDate': (subscriptionData['startDate'] as Timestamp).toDate().toIso8601String(),
        'endDate': (subscriptionData['endDate'] as Timestamp).toDate().toIso8601String(),
        'isActive': true,
        'isExpiringSoon': endDate.difference(now).inDays <= 3,
      });
    } catch (e) {
      throw Exception('Erreur achat abonnement: $e');
    }
  }

  // ============================================
  // COURSES
  // ============================================

  /// Obtenir les courses à proximité
  Stream<List<Ride>> streamNearbyRides({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 20,
  }) {
    // Firestore ne supporte pas directement les requêtes de proximité géographique
    // Solution: utiliser une approximation avec bounding box
    // Pour une solution complète, utiliser GeoFirestore ou une extension
    final latDelta = radiusKm / 111.0; // Approximation: 1 degré ≈ 111 km
    final lngDelta = radiusKm / (111.0 * (latitude / 90.0).abs());

    final minLat = latitude - latDelta;
    final maxLat = latitude + latDelta;
    final minLng = longitude - lngDelta;
    final maxLng = longitude + lngDelta;

    return _firestore
        .collection(ridesCollection)
        .where('status', whereIn: ['requested', 'searching'])
        .where('pickup.coordinates.latitude', isGreaterThanOrEqualTo: minLat)
        .where('pickup.coordinates.latitude', isLessThanOrEqualTo: maxLat)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return null;
                
                // Filtrer par longitude (Firestore ne supporte pas plusieurs inégalités)
                final pickup = data['pickup'] as Map<String, dynamic>?;
                final coordinates = pickup?['coordinates'] as Map<String, dynamic>?;
                final rideLat = (coordinates?['latitude'] as num?)?.toDouble() ?? 0.0;
                final rideLng = (coordinates?['longitude'] as num?)?.toDouble() ?? 0.0;
                
                if (rideLng < minLng || rideLng > maxLng) return null;
                
                // Calculer la distance réelle
                final distance = _calculateDistance(
                  latitude,
                  longitude,
                  rideLat,
                  rideLng,
                );
                
                if (distance > radiusKm) return null;
                
                return Ride.fromJson({
                  'id': doc.id,
                  ...data,
                  'requestedAt': (data['requestedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
                });
              })
              .where((ride) => ride != null)
              .cast<Ride>()
              .toList();
        });
  }

  /// Obtenir les courses du chauffeur
  Stream<List<Ride>> streamDriverRides({
    String status = 'all',
    int limit = 20,
  }) {
    final userId = currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection(ridesCollection)
        .where('driver', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .limit(limit);

    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return Ride.fromJson({
              'id': doc.id,
              ...data,
              'requestedAt': (data['requestedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
            });
          })
          .where((ride) => ride != null)
          .cast<Ride>()
          .toList();
    });
  }

  /// Accepter une course
  Future<Ride> acceptRide(String rideId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final rideRef = _firestore.collection(ridesCollection).doc(rideId);
      
      await rideRef.update({
        'driver': userId,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final doc = await rideRef.get();
      final data = doc.data()!;
      
      return Ride.fromJson({
        'id': doc.id,
        ...data,
        'requestedAt': (data['requestedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur acceptation course: $e');
    }
  }

  /// Mettre à jour le statut d'une course
  Future<Ride> updateRideStatus(String rideId, String status) async {
    try {
      final rideRef = _firestore.collection(ridesCollection).doc(rideId);
      
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Ajouter les timestamps selon le statut
      switch (status) {
        case 'arrived':
          updates['arrivedAt'] = FieldValue.serverTimestamp();
          break;
        case 'started':
          updates['startedAt'] = FieldValue.serverTimestamp();
          break;
        case 'completed':
          updates['completedAt'] = FieldValue.serverTimestamp();
          break;
        case 'cancelled':
          updates['cancelledAt'] = FieldValue.serverTimestamp();
          break;
      }

      await rideRef.update(updates);

      final doc = await rideRef.get();
      final data = doc.data()!;
      
      return Ride.fromJson({
        'id': doc.id,
        ...data,
        'requestedAt': (data['requestedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur mise à jour course: $e');
    }
  }

  /// Obtenir les détails d'une course
  Future<Ride?> getRideDetails(String rideId) async {
    try {
      final doc = await _firestore
          .collection(ridesCollection)
          .doc(rideId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return Ride.fromJson({
        'id': doc.id,
        ...data,
        'requestedAt': (data['requestedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur récupération course: $e');
    }
  }

  /// Écouter les changements d'une course en temps réel
  Stream<Ride?> streamRide(String rideId) {
    return _firestore
        .collection(ridesCollection)
        .doc(rideId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data()!;
          return Ride.fromJson({
            'id': doc.id,
            ...data,
            'requestedAt': (data['requestedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
          });
        });
  }

  // ============================================
  // MÉTHODES UTILITAIRES
  // ============================================

  /// Mapper les données Firestore vers DriverProfile
  DriverProfile _mapToDriverProfile(String id, Map<String, dynamic> data) {
    // Convertir les Timestamps en DateTime
    final subscriptionData = data['subscription'];
    SubscriptionInfo? subscription;
    
    if (subscriptionData != null) {
      subscription = SubscriptionInfo.fromJson({
        'id': subscriptionData['id'] ?? '',
        'type': subscriptionData['type'] ?? '',
        'name': subscriptionData['name'] ?? '',
        'price': subscriptionData['price'] ?? 0.0,
        'currency': subscriptionData['currency'] ?? 'XOF',
        'duration': subscriptionData['duration'] ?? 30,
        'features': subscriptionData['features'] ?? [],
        'status': subscriptionData['status'] ?? 'active',
        'startDate': (subscriptionData['startDate'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
        'endDate': (subscriptionData['endDate'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'isActive': subscriptionData['status'] == 'active',
        'isExpiringSoon': false,
      });
    }

    final locationData = data['currentLocation'];
    LocationInfo? location;
    
    if (locationData != null && locationData['timestamp'] != null) {
      location = LocationInfo.fromJson({
        'latitude': locationData['latitude'] ?? 0.0,
        'longitude': locationData['longitude'] ?? 0.0,
        'address': locationData['address'],
        'accuracy': locationData['accuracy'],
        'timestamp': (locationData['timestamp'] as Timestamp).toDate().toIso8601String(),
      });
    }

    return DriverProfile(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      vehicleType: VehicleType.fromString(data['vehicleType'] ?? 'car'),
      vehicle: VehicleInfo.fromJson(data['vehicle'] ?? {}),
      subscription: subscription,
      stats: DriverStats.fromJson(data['stats'] ?? {}),
      isOnline: data['isOnline'] ?? false,
      isAvailable: data['isAvailable'] ?? false,
      currentLocation: location,
    );
  }

  /// Calculer la distance entre deux points (formule de Haversine)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

