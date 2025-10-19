import '../models/driver_profile.dart';

class TestData {
  // Données de test pour les chauffeurs
  static final Map<String, DriverProfile> testDrivers = {
    '221771234567': DriverProfile(
      id: 'driver_001',
      firstName: 'Amadou',
      lastName: 'Diop',
      phone: '221771234567',
      email: 'amadou.diop@dudu.sn',
      vehicleType: VehicleType.car,
      vehicle: VehicleInfo(
        make: 'Toyota',
        model: 'Corolla',
        year: 2020,
        color: 'Blanc',
        plateNumber: 'DK-1234-AB',
        type: 'standard',
        capacity: 4,
      ),
      subscription: SubscriptionInfo(
        id: 'sub_001',
        type: 'monthly',
        name: 'Forfait Mensuel',
        price: 45000,
        currency: 'FCFA',
        duration: 30,
        features: [
          'Courses illimitées',
          'Support prioritaire',
          'Statistiques avancées',
          'Formation gratuite',
        ],
        status: 'active',
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        isActive: true,
        isExpiringSoon: false,
      ),
      stats: DriverStats(
        totalRides: 245,
        completedRides: 238,
        cancelledRides: 7,
        averageRating: 4.8,
        totalEarnings: 1250000,
        totalDistance: 12500,
        todayRides: 12,
        todayEarnings: 48000,
        weeklyRides: 45,
        weeklyEarnings: 180000,
        bonusEarned: 0,
      ),
      isOnline: false,
      isAvailable: false,
    ),
    
    '221771234568': DriverProfile(
      id: 'driver_002',
      firstName: 'Fatou',
      lastName: 'Sarr',
      phone: '221771234568',
      email: 'fatou.sarr@dudu.sn',
      vehicleType: VehicleType.moto,
      vehicle: VehicleInfo(
        make: 'Honda',
        model: 'CG 125',
        year: 2021,
        color: 'Rouge',
        plateNumber: 'DK-5678-CD',
        type: 'moto_delivery',
        capacity: 1,
      ),
      subscription: SubscriptionInfo(
        id: 'sub_002',
        type: 'daily',
        name: 'Forfait Journalier',
        price: 2000,
        currency: 'FCFA',
        duration: 1,
        features: [
          'Livraisons illimitées',
          'Support 24/7',
          'Statistiques de base',
        ],
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        isActive: true,
        isExpiringSoon: false,
        weeklyBonus: WeeklyBonus(
          type: 'free_subscription',
          amount: 2000,
          lastBonusDate: DateTime.now().subtract(const Duration(days: 2)),
          bonusHistory: [
            BonusHistory(
              type: 'free_subscription',
              amount: 2000,
              date: DateTime.now().subtract(const Duration(days: 2)),
              description: 'Bonus performance - 24h gratuites',
            ),
            BonusHistory(
              type: 'cash_bonus',
              amount: 5000,
              date: DateTime.now().subtract(const Duration(days: 9)),
              description: 'Bonus hebdomadaire - Virement Wave',
            ),
          ],
        ),
        restrictions: SubscriptionRestrictions(
          maxDailyRides: 20,
          allowedPlans: ['daily'],
        ),
      ),
      stats: DriverStats(
        totalRides: 180,
        completedRides: 175,
        cancelledRides: 5,
        averageRating: 4.9,
        totalEarnings: 450000,
        totalDistance: 8500,
        todayRides: 8,
        todayEarnings: 16000,
        weeklyRides: 35,
        weeklyEarnings: 70000,
        bonusEarned: 15000,
      ),
      isOnline: false,
      isAvailable: false,
    ),
  };

  // Méthode pour obtenir un profil de test
  static DriverProfile? getTestDriver(String phone) {
    return testDrivers[phone];
  }

  // Méthode pour simuler une connexion
  static Future<Map<String, dynamic>> simulateLogin(String phone, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simuler délai réseau
    
    final driver = getTestDriver(phone);
    if (driver != null) {
      return {
        'success': true,
        'data': {
          'token': 'test_token_${driver.id}',
          'driver': driver.toJson(),
        },
        'message': 'Connexion réussie',
      };
    } else {
      return {
        'success': false,
        'message': 'Identifiants incorrects',
      };
    }
  }

  // Méthode pour simuler la récupération du profil
  static Future<DriverProfile> simulateGetProfile(String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Extraire l'ID du token
    final driverId = token.replaceAll('test_token_', '');
    
    // Trouver le profil correspondant
    for (final driver in testDrivers.values) {
      if (driver.id == driverId) {
        return driver;
      }
    }
    
    // Si pas trouvé par ID, essayer par téléphone
    if (token.contains('driver_001')) {
      return testDrivers['221771234567']!;
    } else if (token.contains('driver_002')) {
      return testDrivers['221771234568']!;
    }
    
    throw Exception('Profil non trouvé pour le token: $token');
  }
}
