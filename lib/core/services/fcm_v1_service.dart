import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service that sends real device push notifications via the FCM HTTP v1 API.
///
/// SETUP REQUIRED:
/// Pass credentials via constructor (load from environment or secure storage).
///
/// When passing the private key via --dart-define, newlines are often escaped
/// as literal \n sequences. This service normalizes the key automatically.
class FcmV1Service {
  // ── Firestore field constants ───────────────────────────────────────────────
  static const String _firebaseUsersCollection = 'users';
  static const String _firebaseRoleField = 'role';
  static const String _firebaseDriverRole = 'driver';
  static const String _firebaseBusIdField = 'busId';
  static const String _firebaseFcmTokenField = 'fcmToken';
  static const String _androidChannelId = 'kidsecure_critical_alerts_v8';

  // ── FCM error codes that mean the token is permanently dead ────────────────
  static const _unrecoverableErrors = {
    'UNREGISTERED',
    'INVALID_ARGUMENT',
    'NOT_FOUND',
  };

  late final String _projectId;
  late final String _clientEmail;
  late final String _privateKey;

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  /// Creates a new FCM service instance.
  ///
  /// [projectId]    – Firebase project ID.
  /// [clientEmail]  – Service account email.
  /// [privateKey]   – Service account private key (PEM format).
  ///                  Handles keys with literal \n escape sequences (--dart-define).
  FcmV1Service({
    required String projectId,
    required String clientEmail,
    required String privateKey,
  }) {
    _projectId = projectId;
    _clientEmail = clientEmail;
    _privateKey = _normalizePem(privateKey);
  }

  // ── Private key normalisation ───────────────────────────────────────────────

  /// Converts any well-known broken PEM format into a properly formatted PEM
  /// string that dart_jsonwebtoken's RSAPrivateKey constructor accepts.
  ///
  /// Handles:
  ///   • Literal \n sequences produced by --dart-define / shell quoting
  static String _normalizePem(String key) {
    // 1. Convert literal \n sequences (from JSON keys) to real newlines, then strip all whitespace
    String cleanKey = key
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(RegExp(r'\s+'), '');

    const beginMarker = '-----BEGIN PRIVATE KEY-----';
    const endMarker = '-----END PRIVATE KEY-----';

    // Markers without spaces for matching the stripped key
    const cleanBegin = '-----BEGINPRIVATEKEY-----';
    const cleanEnd = '-----ENDPRIVATEKEY-----';

    // 2. Extract raw Base64 content
    String base64Content;
    final start = cleanKey.indexOf(cleanBegin);
    final end   = cleanKey.indexOf(cleanEnd);

    if (start != -1 && end != -1 && start < end) {
      base64Content = cleanKey.substring(start + cleanBegin.length, end);
    } else {
      // Fallback – try to remove the dashed markers with their spaces intact
      base64Content = key
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll('-----BEGINPRIVATEKEY-----', '')
          .replaceAll('-----ENDPRIVATEKEY-----',   '');
    }

    // 3. Keep only valid Base64 characters
    base64Content = base64Content.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

    if (kDebugMode) {
      print('[FcmV1Service] Base64 length after clean: ${base64Content.length}');
    }

    // 4. Re-chunk into 64-character lines – dart_jsonwebtoken's PEM parser
    //    requires this exact RFC-7468 format.
    final buf = StringBuffer()..writeln(beginMarker);
    for (var i = 0; i < base64Content.length; i += 64) {
      buf.writeln(base64Content.substring(
          i, (i + 64).clamp(0, base64Content.length)));
    }
    buf.write(endMarker);

    return buf.toString();
  }

  // ── OAuth2 access token ─────────────────────────────────────────────────────

  /// Returns a valid OAuth2 access token, refreshing it when needed.
  Future<String?> _getAccessToken() async {
    // Return cached token if still valid (with a 60-second safety margin).
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(
          _tokenExpiry!.subtract(const Duration(seconds: 60)),
        )) {
      return _cachedAccessToken;
    }

    // Guard: empty credentials.
    if (_clientEmail.isEmpty || _privateKey.isEmpty) {
      _log(
        '❌ FCM credentials are missing.\n'
        '  email: ${_clientEmail.isEmpty ? "EMPTY" : "OK"}\n'
        '  key  : ${_privateKey.isEmpty ? "EMPTY" : "OK"}',
      );
      return null;
    }

    // Guard: PEM markers must be present after normalisation.
    if (!_privateKey.contains('-----BEGIN PRIVATE KEY-----') ||
        !_privateKey.contains('-----END PRIVATE KEY-----')) {
      _log(
        '❌ Private key is missing PEM markers after normalisation.\n'
        '  key length : ${_privateKey.length}\n'
        '  first 80ch : ${_privateKey.substring(0, _privateKey.length.clamp(0, 80))}',
      );
      return null;
    }

    try {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      final jwt = JWT({
        'iss': _clientEmail,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': 'https://oauth2.googleapis.com/token',
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': expiry.millisecondsSinceEpoch ~/ 1000,
      });

      // Sign with RSA-SHA256 (RS256) — required for service account JWTs
      final signedJwt = jwt.sign(RSAPrivateKey(_privateKey), algorithm: JWTAlgorithm.RS256);

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': signedJwt,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedAccessToken = data['access_token'] as String?;
        _tokenExpiry = expiry;
        _log('✅ Access token obtained successfully.');
        return _cachedAccessToken;
      }

      _log(
        '❌ OAuth token exchange failed: ${response.statusCode}\n'
        '  body: ${response.body}',
      );
      return null;
    } catch (e, stackTrace) {
      _log(
        '❌ Exception while obtaining access token: $e\n'
        '  key length   : ${_privateKey.length}\n'
        '  client email : $_clientEmail\n'
        '  stack        : $stackTrace',
      );
      return null;
    }
  }

  // ── Core send primitive ─────────────────────────────────────────────────────

  /// Sends a push notification to a single FCM device token.
  ///
  /// Returns `true` on success.
  /// Returns `false` and optionally calls [onStaleToken] when FCM reports the
  /// token as permanently invalid (UNREGISTERED / NOT_FOUND).
  Future<bool> sendToToken({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
    int maxRetries = 3,

    /// Called when FCM says the token is permanently invalid so the caller
    /// can remove it from Firestore (or any other store).
    Future<void> Function(String token)? onStaleToken,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      _log('❌ ABORT: No access token. Check your private key format.');
      return false;
    }

    _log('🚀 Sending to token ${_mask(fcmToken)}');

    final fcmUrl =
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

    final payload = jsonEncode({
      'message': {
        'token': fcmToken,
        'data': {
          'title': title,
          'body': body,
          'type': 'broadcast',
          ...?data,
        },
        'android': {
          'priority': 'HIGH',
          'notification': {
            'channel_id': _androidChannelId,
            'title': title,
            'body': body,
            'notification_priority': 'PRIORITY_MAX',
            // No custom sound = use device default
          },
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          'payload': {
            'aps': {
              'alert': {'title': title, 'body': body},
              'sound': 'default',
              'badge': 1,
              'content-available': 1,
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
          _log('✅ Notification sent to ${_mask(fcmToken)}');
          return true;
        }

        _log(
          '❌ Attempt ${attempt + 1} failed: ${response.statusCode}\n'
          '  body: ${response.body}',
        );

        // Check for permanent token invalidity and clean up if requested.
        if (response.statusCode == 404 || response.statusCode == 400) {
          final errorCode = _extractFcmErrorCode(response.body);
          if (_unrecoverableErrors.contains(errorCode)) {
            _log(
              '🗑️  Token ${_mask(fcmToken)} is stale ($errorCode). Cleaning up.',
            );
            await onStaleToken?.call(fcmToken);
            return false;
          }
        }

        // Stop retrying on any other 4xx (except 429 Too Many Requests).
        if (response.statusCode >= 400 &&
            response.statusCode < 500 &&
            response.statusCode != 429) {
          return false;
        }
      } catch (e) {
        _log('❌ Exception on attempt ${attempt + 1}: $e');
      }

      if (attempt < maxRetries) {
        final delayMs = 1000 * (1 << attempt); // 1s → 2s → 4s
        _log('⏳ Retrying in ${delayMs}ms…');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    return false;
  }

  /// Sends a push notification to a Firebase topic (e.g. 'all_users').
  Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
    int maxRetries = 3,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) return false;

    _log('🚀 Sending to topic: $topic');

    final fcmUrl = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

    final payload = jsonEncode({
      'message': {
        'topic': topic,
        'data': {
          'title': title,
          'body': body,
          'type': 'broadcast',
          ...?data,
        },
        'android': {
          'priority': 'HIGH',
          'notification': {
            'channel_id': _androidChannelId,
            'title': title,
            'body': body,
            'notification_priority': 'PRIORITY_MAX',
            // No custom sound = use device default
          },
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          'payload': {
            'aps': {
              'alert': {'title': title, 'body': body},
              'sound': 'default',
              'badge': 1,
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
          _log('✅ Notification sent to topic: $topic');
          return true;
        }

        _log('❌ Topic attempt ${attempt + 1} failed: ${response.statusCode} - ${response.body}');
      } catch (e) {
        _log('❌ Exception on topic attempt ${attempt + 1}: $e');
      }

      if (attempt < maxRetries) {
        await Future.delayed(Duration(milliseconds: 1000 * (1 << attempt)));
      }
    }

    return false;
  }

  // ── High-level helpers ──────────────────────────────────────────────────────

  /// Sends a notification to a parent user by Firestore user ID.
  ///
  /// Automatically removes stale FCM tokens from Firestore.
  Future<bool> sendToParent({
    required String parentId,
    required String title,
    required String body,
    Map<String, String>? data,
    int maxRetries = 3,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_firebaseUsersCollection)
          .doc(parentId)
          .get();

      final token = doc.data()?[_firebaseFcmTokenField] as String?;
      if (token == null || token.isEmpty) {
        _log('⚠️  No FCM token for parent: $parentId');
        return false;
      }

      return await sendToToken(
        fcmToken: token,
        title: title,
        body: body,
        data: data,
        maxRetries: maxRetries,
        onStaleToken: (_) => _clearFcmToken(parentId),
      );
    } catch (e) {
      _log('❌ Error sending to parent $parentId: $e');
      return false;
    }
  }

  /// Sends a notification to all drivers assigned to [busId], concurrently.
  ///
  /// Returns a summary of how many sends succeeded.
  Future<({int sent, int total})> sendToBus({
    required String busId,
    required String title,
    required String body,
    Map<String, String>? data,
    int maxRetries = 3,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_firebaseUsersCollection)
          .where(_firebaseRoleField, isEqualTo: _firebaseDriverRole)
          .where(_firebaseBusIdField, isEqualTo: busId)
          .get();

      final futures = <Future<bool>>[];

      for (final doc in snapshot.docs) {
        final token = doc.data()[_firebaseFcmTokenField] as String?;
        if (token != null && token.isNotEmpty) {
          futures.add(
            sendToToken(
              fcmToken: token,
              title: title,
              body: body,
              data: data,
              maxRetries: maxRetries,
              onStaleToken: (_) => _clearFcmToken(doc.id),
            ),
          );
        }
      }

      if (futures.isEmpty) {
        _log('⚠️  No driver tokens found for bus $busId');
        return (sent: 0, total: 0);
      }

      // eagerError: false ensures all futures run even if one throws.
      final results = await Future.wait(futures, eagerError: false);
      final sent = results.where((r) => r).length;

      _log('📊 Bus $busId: $sent/${results.length} notifications sent.');
      return (sent: sent, total: results.length);
    } catch (e) {
      _log('❌ Error sending to bus $busId: $e');
      return (sent: 0, total: 0);
    }
  }

  // ── Firestore helpers ───────────────────────────────────────────────────────

  /// Clears the FCM token field for a user document (stale token clean-up).
  Future<void> _clearFcmToken(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_firebaseUsersCollection)
          .doc(userId)
          .update({_firebaseFcmTokenField: FieldValue.delete()});
      _log('🗑️  Cleared stale FCM token for user $userId');
    } catch (e) {
      _log('⚠️  Could not clear FCM token for user $userId: $e');
    }
  }

  // ── Utilities ───────────────────────────────────────────────────────────────

  /// Extracts the FCM error code string from a failed response body, e.g.
  /// `"UNREGISTERED"` from `{"error":{"details":[{"errorCode":"UNREGISTERED"}]}}`.
  String? _extractFcmErrorCode(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final details = error?['details'] as List<dynamic>?;
      if (details != null) {
        for (final detail in details) {
          final code = (detail as Map<String, dynamic>)['errorCode'] as String?;
          if (code != null) return code;
        }
      }
      // Fallback: sometimes the status field is enough.
      return error?['status'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Returns the first [n] chars of a token followed by '…' (safe for logs).
  String _mask(String token, [int n = 10]) =>
      token.length > n ? '${token.substring(0, n)}…' : token;

  /// Prints only in debug mode.
  void _log(String message) {
    if (kDebugMode) print('[FcmV1Service] $message');
  }
}
