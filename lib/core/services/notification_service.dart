import 'dart:async';
import 'dart:convert';
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

    // 2. Create High Importance Channel for Android (v8 = default system sound)
    const androidChannel = AndroidNotificationChannel(
      'kidsecure_critical_alerts_v8',
      'KidSecure Alerts',
      description: 'Important notifications requiring immediate attention.',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      // No custom sound = use device default notification sound
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

    // Subscribe to general topic for broadcasts
    await _fcm.subscribeToTopic('all_users');

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // 4. Handle App States

    // FOREGROUND: Show local notification banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.data}');
      }
      // Skip broadcast messages — FCM already shows the system notification
      // via the topic delivery. Showing a local one too would cause duplicates.
      final type = message.data['type'] as String? ?? '';
      if (type == 'broadcast') return;

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
    if (kDebugMode) {
      print('Local notification payload: $payload');
    }
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      _navigationStreamController.add(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding notification payload: $e');
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    
    if (title == null && body == null) return;

    final androidDetails = AndroidNotificationDetails(
      'kidsecure_critical_alerts_v8',
      'KidSecure Alerts',
      channelDescription: 'Important notifications requiring immediate attention.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // No custom sound = use device default notification sound
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
      payload: jsonEncode(message.data),
    );
  }

  /// Manually trigger a test notification to verify sounds and channels
  Future<void> triggerTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'kidsecure_critical_alerts_v8',
      'KidSecure Alerts',
      channelDescription: 'Important notifications requiring immediate attention.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // No custom sound = use device default notification sound
      enableVibration: true,
      enableLights: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alert.wav',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      999,
      'Test Alert',
      'If you hear this sound, your alert.wav is working correctly!',
      notificationDetails,
      payload: jsonEncode({'type': 'test'}),
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
