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
import 'package:kidsecure/features/admin/data/repositories/firebase_stats_repository.dart';
import 'package:kidsecure/features/bus_tracking/data/repositories/bus_tracking_repository_impl.dart';
import 'package:kidsecure/core/services/fcm_v1_service.dart';

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
        statsRepository: FirebaseStatsRepository(),
        busTrackingRepository: BusTrackingRepositoryImpl(),
        fcmV1Service: FcmV1Service(
          projectId: 'kid-86bbc',
          clientEmail: 'firebase-adminsdk-fbsvc@kid-86bbc.iam.gserviceaccount.com',
          privateKey: '-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQChtZvfmQBUDphp\nJQAleipvPvV4XOPk0GJAWGphyP5r4So8n/3ZrT24JSLOfuHlpkxQXvuOLXgkeqQ9\ncHc8uz0Rp14EoWT6+Su+7IoQ9xG/vGhnBWxREWjt+elJBtCdNjcyLK3LyspM3LrZ\n9++ieKiKkwcLAPNOWBo9pRRtLeNuR9OFKJU/0TjzPDGh9OEG7+tpcKF9CV3Kuw1f\nb5ZaHQIfeyymNk/cOnEKBrUktkT5TMMOpfM/VeplYmwzT4FgeHlbMAvdBaUdm70i\n95T4wPGo/dyaE4eLZCg0T8DXVke1Y0eZQTEMiXHZ/xHCy2nqJ1nPMwdJfZ1bYSOC\nDcrc1CKhAgMBAAECggEAGmd5/SeRayg68Kgu/u+UsDd6g12/hGQWNuV48WCNUnYg\nnGePXpSwCDpgFZGYNxRRT6pCrvNzs5km6jVL8umrzg8jBeSIhYZcAz/CR4TgLAuK\njI/RIOeT14+/7MGlHJZ2qsWq1yTUpXpBNEgMo93Jv17EfqJ4F+nA1yH2VOFySlZD\nmrmLSp4YEJ707+KNkq0DjYfOt2uIRQ7A7GJHLJjJ06P60QIs6v0Ra3EwQUTJymH4\nGRKjqZsg4Aj18limXv0WybtzXMNUxnp+z5MgjyvgnZ2PyRB1mvhu/uk3t09nj0Dm\n0fMC99J5ABnJ2N2LzGOofUTFrEb7S8LRROJWgW0NhQKBgQDOc93fgmoBBeX0cuxG\nlXkcr75c+dvJm5s7gqP6xqvVkxOAZBdCx7+y1c1gBPdY/Qqa2UJ+UkgSVAPu9tCk\nYmxKE979/Wzbit9yqPcPjx95kNtPDRVi0rQ+VxZnXFOht10b0g/50k4nuqfN9gTm\n+jXWDvhQmcCfFaFK0BOkX/P+UwKBgQDIhMncOmRCdcTq2DSQFD79XLkUa/d/EePM\nJD+e87uo/FJGWLqNZiclcYYoEOmZWew20xI+l0uNyHSqkCPXz0qCak9s17WmSpPI\nSTNas/L0uKdvgy2vtCovTeuPlOqDYkY8Kz4EOkTWzMOEhRe887x68vCaAGo0ujQu\n67yWTz20uwKBgQC3xXnNuEflyztLonThy7H4MBQSrTLQvluq2HphAzH4NihY1D/E\naQwiA6ECBMmsg+pJtnUy/sk6z2CE+Vz1xsrAEfogOtMIhhCq/u6VAgCxdJlTP8E2\nq3pYN6swrIWhYRhXaGBiL6r0QHmYo5Lvi/AaME8naAWHVnixoJCrc+I8EwKBgQCX\nJUDjeEBKuGsOeppkYF56rIH2GswcRGfpYQlzz1UNM+TwkcFNBEtNthzh5p2uslGT\nodaGx5Rz8z29s5jQ+7e2RlxINvD9wAlVV5gWLr5cKTRMohy17KA/uARv3lhHYLSA\ndjfxB9sL7p0SLyCNlUvlgWpLKzTjOdhL5fXpdyGUMQKBgQCxVqnVCr98aMsVGZyK\nzkXmkfhrSw2sFxh2Z5JVNhlqSkJEbx4WJdbmSoUEX5VEKZtzDwqJZRJ1UsOX0YnR\nAuJlDqH1RXRgnaD97uyug2y8IVpd7PskbuHQRkF3pugO9UBM/M8u3IWZHg9ElpKB\nj2E6s9oNzFcpq62yk7utvVFTyQ==\n-----END PRIVATE KEY-----\n',
        ),
        prefs: prefs,
      ),
    );

    // Basic check that app builds
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
