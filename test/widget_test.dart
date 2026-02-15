// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kidsecure/main.dart';
import 'package:kidsecure/features/auth/data/firebase_auth_repository.dart';
import 'package:kidsecure/features/attendance/data/repositories/firebase_attendance_repository.dart';
import 'package:kidsecure/core/services/notification_service.dart';
import 'package:kidsecure/core/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsecure/features/admin/data/firebase_broadcast_repository.dart';
import 'package:kidsecure/features/attendance/data/repositories/firebase_dismissal_repository.dart';
import 'package:kidsecure/features/notifications/data/firebase_notification_repository.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        authRepository: FirebaseAuthRepository(),
        attendanceRepository: FirebaseAttendanceRepository(),
        notificationService: NotificationService(),
        locationService: LocationService(),
        broadcastRepository: FirebaseBroadcastRepository(),
        dismissalRepository: FirebaseDismissalRepository(),
        notificationRepository: FirebaseNotificationRepository(),
        prefs: prefs,
      ),
    );

    // Basic check that app builds
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
