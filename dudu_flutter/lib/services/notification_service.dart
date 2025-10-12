import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  /// Initialiser les notifications
  Future<void> initialize() async {
    if (_initialized) return;

    // Configuration Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander permissions
    await _requestPermissions();

    _initialized = true;
    print('✅ Notifications initialisées');
  }

  /// Demander les permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Obtenir le token FCM (Firebase)
  Future<String?> getFCMToken() async {
    // TODO: Implémenter avec Firebase Messaging
    // final messaging = FirebaseMessaging.instance;
    // _fcmToken = await messaging.getToken();
    // return _fcmToken;
    
    // Pour le moment, retourner un token simulé
    _fcmToken = 'simulated_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
    return _fcmToken;
  }

  /// Enregistrer le token sur le serveur
  Future<void> registerToken(String apiUrl, String authToken) async {
    try {
      final token = await getFCMToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$apiUrl/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcmToken': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM enregistré');
      }
    } catch (e) {
      print('❌ Erreur enregistrement token: $e');
    }
  }

  /// Afficher notification locale
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'dudu_channel',
      'DUDU Notifications',
      channelDescription: 'Notifications de courses et covoiturage',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Notification covoiturage disponible
  Future<void> showCarpoolAvailableNotification({
    required int driversCount,
    required int totalSeats,
    required int savings,
  }) async {
    await showNotification(
      title: '🤝 $driversCount chauffeurs en covoiturage !',
      body: '$totalSeats places disponibles • Économisez $savings FCFA',
      payload: 'carpool_available',
    );
  }

  /// Notification prix réduit
  Future<void> showPriceReductionNotification({
    required int savings,
  }) async {
    await showNotification(
      title: '💰 Prix réduit maintenant !',
      body: 'Économisez $savings FCFA avec le covoiturage',
      payload: 'price_reduction',
    );
  }

  /// Notification chauffeur trouvé
  Future<void> showDriverFoundNotification({
    required String driverName,
    required int eta,
  }) async {
    await showNotification(
      title: '✅ Chauffeur trouvé !',
      body: '$driverName arrive dans $eta minutes',
      payload: 'driver_found',
    );
  }

  /// Notification promotion
  Future<void> showPromotionNotification({
    required String title,
    required String message,
  }) async {
    await showNotification(
      title: '🎉 $title',
      body: message,
      payload: 'promotion',
    );
  }

  /// Callback quand notification reçue (iOS uniquement)
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    print('📱 Notification reçue (iOS): $title');
  }

  /// Callback quand notification tapée
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    print('👆 Notification tapée: $payload');

    // TODO: Navigation selon le type de notification
    switch (payload) {
      case 'carpool_available':
        // Navigator.push vers écran covoiturage
        break;
      case 'driver_found':
        // Navigator.push vers écran tracking
        break;
      case 'promotion':
        // Navigator.push vers écran promotions
        break;
    }
  }

  /// Annuler toutes les notifications
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Annuler une notification spécifique
  Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Simuler notification covoiturage (pour tests)
  Future<void> simulateCarpoolNotification() async {
    await Future.delayed(const Duration(seconds: 2));
    await showCarpoolAvailableNotification(
      driversCount: 5,
      totalSeats: 15,
      savings: 600,
    );
  }
}

