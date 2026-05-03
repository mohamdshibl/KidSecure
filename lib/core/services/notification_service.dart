import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream controller to broadcast notification data for navigation
  final StreamController<Map<String, dynamic>> _navigationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get navigationStream =>
      _navigationStreamController.stream;

  Future<void> initialize() async {
    if (kIsWeb) return;

    // 1. Initialize Local Notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          _handleNotificationClick(details.payload!);
        }
      },
    );

    // 2. Create High Importance Channel for Android
    const androidChannel = AndroidNotificationChannel(
      'kidsecure_critical_alerts_v3',
      'Critical Alerts',
      description: 'Important notifications requiring immediate attention.',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alert'),
      // Uses custom alert.wav sound
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 3. Request Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // 4. Handle App States

    // FOREGROUND: Show local notification banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.data}');
      }
      if (message.notification != null || message.data.containsKey('title')) {
        _showLocalNotification(message);
      }
    });

    // BACKGROUND (but not terminated): User taps the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification clicked while app in background: ${message.data}');
      }
      _navigationStreamController.add(message.data);
    });

    // TERMINATED: App was opened by tapping the notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('App opened from terminated state via notification: ${initialMessage.data}');
      }
      _navigationStreamController.add(initialMessage.data);
    }

    // NOTE: onBackgroundMessage is registered as a top-level function in main.dart
    // before runApp() — do NOT register it here.
  }

  void _handleNotificationClick(String payload) {
    // Convert payload string back to Map if needed, or handle directly
    // This is called when a local notification (foreground) is clicked
    if (kDebugMode) {
      print('Local notification payload: $payload');
    }
    // For simplicity, we assume payload is a map-like string or id
    // You can use jsonDecode here if you passed a JSON string as payload
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    
    if (title == null && body == null) return;

    final androidDetails = AndroidNotificationDetails(
      'kidsecure_critical_alerts_v3',
      'Critical Alerts',
      channelDescription: 'Important notifications requiring immediate attention.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alert'),
      enableVibration: true,
      enableLights: true,
      ticker: 'ticker',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alert.wav',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
      payload: message.data.toString(), // Optional: pass data as payload
    );
  }

  Future<String?> getToken() async {
    try {
      String? token = await _fcm.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Listener for token refresh
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  void dispose() {
    _navigationStreamController.close();
  }
}
