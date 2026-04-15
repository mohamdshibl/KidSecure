import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service that sends real device push notifications via the FCM HTTP v1 API.
///
/// SETUP REQUIRED:
/// 1. Firebase Console → Project Settings → Service Accounts → Generate new private key.
/// 2. From the downloaded JSON, copy the values below.
class FcmV1Service {
  // ─── YOU MUST FILL THESE THREE IN ──────────────────────────────────────────
  static const String _projectId = 'kid-86bbc'; 
  static const String _clientEmail = 'YOUR_SERVICE_ACCOUNT_EMAIL';
  static const String _privateKey = '''
-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_HERE
-----END PRIVATE KEY-----
''';
  // ──────────────────────────────────────────────────────────────────────────

  static const String _fcmUrl =
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  /// Returns a fresh OAuth2 access token using the service-account JWT flow.
  Future<String?> _getAccessToken() async {
    // Check cache
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(seconds: 60)))) {
      return _cachedAccessToken;
    }

    // If placeholders are still there, skip
    if (_clientEmail.contains('YOUR') || _privateKey.contains('YOUR')) {
      if (kDebugMode) {
        print('[FcmV1Service] ⚠️ FCM Credentials are empty. Push notifications will be skipped.');
      }
      return null;
    }

    try {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      final jwt = JWT(
        {
          'iss': _clientEmail,
          'scope': 'https://www.googleapis.com/auth/firebase.messaging',
          'aud': 'https://oauth2.googleapis.com/token',
          'iat': now.millisecondsSinceEpoch ~/ 1000,
          'exp': expiry.millisecondsSinceEpoch ~/ 1000,
        },
      );

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
        return _cachedAccessToken;
      } else {
        if (kDebugMode) print('[FcmV1Service] OAuth failed: ${response.body}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('[FcmV1Service] Error getting access token: $e');
      return null;
    }
  }

  /// Sends a push notification to a single device token.
  Future<bool> sendToToken({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'HIGH',
              'notification': {
                'channel_id': 'high_importance_channel_v2',
                'sound': 'default',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'alert': {'title': title, 'body': body},
                  'sound': 'default',
                  'badge': 1,
                },
              },
            },
            'data': data ?? {},
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendToParent({
    required String parentId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .get();

      final token = doc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;

      await sendToToken(fcmToken: token, title: title, body: body, data: data);
    } catch (e) {}
  }
}
