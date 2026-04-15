import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FcmSenderService {
  // IMPORTANT: In a production app, this logic should be on the BACKEND (Firebase Cloud Functions).
  // Sending from the client requires including your Service Account or Legacy Key, which is a security risk.
  // This is provided for SIMULATION and TESTING purposes as requested.

  static const String _legacyServerKey = 'YOUR_LEGACY_SERVER_KEY_HERE'; // Replace with your key
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  /// Sends a notification using the Legacy FCM API (easier for client-side testing)
  Future<bool> sendNotification({
    required String to,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_legacyServerKey',
        },
        body: jsonEncode({
          'to': to,
          'notification': {
            'title': title,
            'body': body,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'sound': 'default',
          },
          'data': data ?? {},
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) print('Notification sent successfully');
        return true;
      } else {
        if (kDebugMode) print('Failed to send notification: ${response.body}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error sending notification: $e');
      return false;
    }
  }

  /// Example payload for Student Arrival
  Future<void> sendStudentArrivalNotification({
    required String parentToken,
    required String studentName,
    required String studentId,
  }) async {
    await sendNotification(
      to: parentToken,
      title: 'School Arrival',
      body: '$studentName has arrived at school.',
      data: {
        'type': 'check_in',
        'studentId': studentId,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }

  /// Example payload for Student Departure
  Future<void> sendStudentDepartureNotification({
    required String parentToken,
    required String studentName,
    required String studentId,
  }) async {
    await sendNotification(
      to: parentToken,
      title: 'School Departure',
      body: '$studentName has left school.',
      data: {
        'type': 'check_out',
        'studentId': studentId,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }

  /// Example payload for Bus Approaching
  Future<void> sendBusApproachingNotification({
    required String parentToken,
    required String busNumber,
  }) async {
    await sendNotification(
      to: parentToken,
      title: 'Bus Alert',
      body: 'Bus $busNumber is approaching your location.',
      data: {
        'type': 'bus_approaching',
        'busNumber': busNumber,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }
}
