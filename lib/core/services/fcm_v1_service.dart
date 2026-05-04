import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service that sends real device push notifications via the FCM HTTP v1 API.
///
/// SETUP REQUIRED:
/// Pass credentials via constructor (load from environment or secure storage).
class FcmV1Service {
  // Constants for Firestore field names
  static const String _firebaseUsersCollection = 'users';
  static const String _firebaseRoleField = 'role';
  static const String _firebaseDriverRole = 'driver';
  static const String _firebaseBusIdField = 'busId';
  static const String _firebaseFcmTokenField = 'fcmToken';
  static const String _androidChannelId = 'kidsecure_critical_alerts_v4';

  late final String _projectId;
  late final String _clientEmail;
  late final String _privateKey;

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  /// Creates a new FCM service instance.
  ///
  /// [projectId] - Firebase project ID
  /// [clientEmail] - Service account email
  /// [privateKey] - Service account private key (PEM format)
  FcmV1Service({
    required String projectId,
    required String clientEmail,
    required String privateKey,
  }) {
    _projectId = projectId;
    _clientEmail = clientEmail;
    // Strip carriage returns which can break PEM parsing on Windows
    _privateKey = privateKey.replaceAll('\r', '');
  }

  /// Returns a fresh OAuth2 access token using the service-account JWT flow.
  Future<String?> _getAccessToken() async {
    // Check cache
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(
          _tokenExpiry!.subtract(const Duration(seconds: 60)),
        )) {
      return _cachedAccessToken;
    }

    // Validate credentials
    if (_clientEmail.isEmpty || _privateKey.isEmpty) {
      if (kDebugMode) {
        print('[FcmV1Service] ❌ ERROR: FCM credentials are MISSING.');
        print('[FcmV1Service] Email: ${_clientEmail.isEmpty ? "EMPTY" : "OK"}');
        print('[FcmV1Service] Key: ${_privateKey.isEmpty ? "EMPTY" : "OK"}');
        print('[FcmV1Service] Make sure you are passing --dart-define=FCM_PRIVATE_KEY=... or hardcoding it for testing.');
      }
      return null;
    }

    try {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      // Validate private key format
      if (!_privateKey.contains('BEGIN PRIVATE KEY') || !_privateKey.contains('END PRIVATE KEY')) {
        if (kDebugMode) {
          print('[FcmV1Service] ❌ Private key format invalid - missing BEGIN/END markers');
          print('[FcmV1Service] Key length: ${_privateKey.length}');
          print('[FcmV1Service] First 100 chars: ${_privateKey.substring(0, _privateKey.length > 100 ? 100 : _privateKey.length)}');
        }
        return null;
      }

      final jwt = JWT({
        'iss': _clientEmail,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': 'https://oauth2.googleapis.com/token',
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': expiry.millisecondsSinceEpoch ~/ 1000,
      });

      final token = jwt.sign(RSAPrivateKey(_privateKey));

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedAccessToken = data['access_token'];
        _tokenExpiry = expiry;
        if (kDebugMode) print('[FcmV1Service] ✅ Access token obtained successfully');
        return _cachedAccessToken;
      } else {
        if (kDebugMode) {
          print(
            '[FcmV1Service] OAuth failed: ${response.statusCode} ${response.body}',
          );
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[FcmV1Service] ❌ Error getting access token: $e');
        print('[FcmV1Service] Stack trace: $stackTrace');
        print('[FcmV1Service] Private key length: ${_privateKey.length}');
        print('[FcmV1Service] Client email: $_clientEmail');
      }
      return null;
    }
  }

  /// Sends a push notification to a single device token with exponential backoff.
  Future<bool> sendToToken({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
    int maxRetries = 3,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      if (kDebugMode) print('[FcmV1Service] ❌ ABORT: No access token available. Check your Private Key format.');
      return false;
    }

    if (kDebugMode) print('[FcmV1Service] 🚀 Attempting to send to token: ${fcmToken.substring(0, 10)}...');

    final fcmUrl = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
    final payload = jsonEncode({
      'message': {
        'token': fcmToken,
        // DO NOT set root 'notification' here. We use data messages
        // so we can intercept them in FirebaseMessaging.onBackgroundMessage
        // and show them manually with flutter_local_notifications for guaranteed sound!
        'data': {
          'title': title,
          'body': body,
          ...data ?? {},
        },
        'android': {
          'priority': 'HIGH',
          'notification': {
            'channel_id': _androidChannelId,
            'title': title,
            'body': body,
            'sound': 'alert',
          },
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
          },
          'payload': {
            'aps': {
              'alert': {'title': title, 'body': body},
              'sound': 'alert.wav',
              'badge': 1,
              'mutable-content': 1,
            },
          },
        },
      },
    });

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(fcmUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: payload,
        );

        if (response.statusCode == 200) {
          if (kDebugMode) print('[FcmV1Service] ✅ SUCCESS: Notification sent successfully!');
          return true;
        }

        if (kDebugMode) {
          print(
            '[FcmV1Service] ❌ FAIL on attempt ${attempt + 1}: ${response.statusCode}',
          );
          print('[FcmV1Service] Response body: ${response.body}');
        }

        // Stop retrying on permanent client errors except 429 Too Many Requests
        if (response.statusCode >= 400 && response.statusCode < 500 && response.statusCode != 429) {
          return false;
        }
      } catch (e) {
        if (kDebugMode) print('[FcmV1Service] Error sending notification on attempt ${attempt + 1}: $e');
      }

      if (attempt < maxRetries) {
        // Exponential backoff: 1s, 2s, 4s...
        final delayMs = (1000 * (1 << attempt));
        if (kDebugMode) print('[FcmV1Service] Retrying in ${delayMs}ms...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    return false;
  }

  Future<bool> sendToParent({
    required String parentId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_firebaseUsersCollection)
          .doc(parentId)
          .get();

      final token = doc.data()?[_firebaseFcmTokenField] as String?;
      if (token == null || token.isEmpty) {
        if (kDebugMode)
          print('[FcmV1Service] No FCM token for parent: $parentId');
        return false;
      }

      return await sendToToken(
        fcmToken: token,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      if (kDebugMode)
        print('[FcmV1Service] Error sending to parent $parentId: $e');
      return false;
    }
  }

  Future<void> sendToBus({
    required String busId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_firebaseUsersCollection)
          .where(_firebaseRoleField, isEqualTo: _firebaseDriverRole)
          .where(_firebaseBusIdField, isEqualTo: busId)
          .get();

      // Send concurrently instead of sequentially
      final futures = <Future<bool>>[];
      for (var doc in snapshot.docs) {
        final token = doc.data()[_firebaseFcmTokenField] as String?;
        if (token != null && token.isNotEmpty) {
          futures.add(
            sendToToken(fcmToken: token, title: title, body: body, data: data),
          );
        }
      }

      if (futures.isNotEmpty) {
        final results = await Future.wait(futures);
        if (kDebugMode) {
          print(
            '[FcmV1Service] Sent to bus $busId: ${results.where((r) => r).length}/${results.length} succeeded',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('[FcmV1Service] Error sending to bus $busId: $e');
    }
  }
}
