import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/fcm_v1_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/auth/presentation/pages/add_staff_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/auth/presentation/pages/access_denied_page.dart';
import 'core/services/storage_service.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/data/repositories/firebase_attendance_repository.dart';
import 'features/attendance/presentation/pages/qr_scanner_page.dart';
import 'features/attendance/presentation/pages/add_student_page.dart';
import 'features/attendance/presentation/pages/student_details_page.dart';
import 'features/attendance/presentation/pages/attendance_history_page.dart';
import 'features/tracking/presentation/pages/bus_tracking_page.dart';
import 'features/attendance/domain/models/student_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/language_cubit.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'features/admin/domain/broadcast_repository.dart';
import 'features/admin/data/firebase_broadcast_repository.dart';
import 'features/admin/presentation/pages/admin_broadcast_page.dart';
import 'features/admin/presentation/pages/broadcast_history_page.dart';
import 'features/admin/presentation/pages/emergency_broadcast_page.dart';
import 'features/attendance/domain/repositories/dismissal_repository.dart';
import 'features/attendance/data/repositories/firebase_dismissal_repository.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/data/firebase_notification_repository.dart';
import 'features/notifications/presentation/pages/notifications_history_page.dart';
import 'features/notifications/presentation/pages/notification_details_page.dart';
import 'features/notifications/domain/models/notification_model.dart';
import 'features/admin/domain/repositories/stats_repository.dart';
import 'features/admin/data/repositories/firebase_stats_repository.dart';
import 'features/admin/presentation/pages/admin_stats_page.dart';
import 'features/attendance/presentation/pages/edit_student_page.dart';
import 'features/admin/presentation/bloc/stats_cubit.dart';
import 'features/bus_tracking/domain/repositories/bus_tracking_repository.dart';
import 'features/bus_tracking/data/repositories/bus_tracking_repository_impl.dart';
import 'features/bus_tracking/presentation/cubit/driver_location_cubit.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM message received: ${message.messageId}');
  
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
  await localNotifications.initialize(initSettings);
  
  const androidChannel = AndroidNotificationChannel(
    'kidsecure_critical_alerts_v4',
    'Critical Alerts',
    description: 'Important notifications requiring immediate attention.',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert'),
    enableVibration: true,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  final androidDetails = AndroidNotificationDetails(
    'kidsecure_critical_alerts_v4',
    'Critical Alerts',
    channelDescription: 'Important notifications requiring immediate attention.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('alert'),
    enableVibration: true,
    enableLights: true,
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'alert.wav',
  );

  final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  final title = message.notification?.title ?? message.data['title'] ?? 'KidSecure';
  final body = message.notification?.body ?? message.data['body'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    await localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized');
    } else {
      rethrow;
    }
  }

  // Register the background handler BEFORE Firebase.initializeApp or runApp.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final notificationService = NotificationService();
  await notificationService.initialize();

  final locationService = LocationService();

  final authRepository = FirebaseAuthRepository();
  final attendanceRepository = FirebaseAttendanceRepository();
  final broadcastRepository = FirebaseBroadcastRepository();
  final dismissalRepository = FirebaseDismissalRepository();
  final notificationRepository = FirebaseNotificationRepository();
  final statsRepository = FirebaseStatsRepository();
  // Replace with your actual Realtime Database URL from Firebase Console
  final busTrackingRepository = BusTrackingRepositoryImpl(
    databaseURL: 'https://kid-86bbc-default-rtdb.europe-west1.firebasedatabase.app/',
  );
  
  // Initialize FCM V1 Service with credentials
  // TODO: Load these from secure configuration (environment variables or secure storage)
  final fcmV1Service = FcmV1Service(
    projectId: 'kid-86bbc',
    clientEmail: 'firebase-adminsdk-fbsvc@kid-86bbc.iam.gserviceaccount.com',
    privateKey: '''-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQChtZvfmQBUDphp
JQAleipvPvV4XOPk0GJAWGphyP5r4So8n/3ZrT24JSLOfuHlpkxQXvuOLXgkeqQ9
Hc8uz0Rp14EoWT6+Su+7IoQ9xG/vGhnBWxREWjt+elJBtCdNjcyLK3LyspM3LrZ
9++ieKiKkwcLAPNOWBo9pRRtLeNuR9OFKJU/0TjzPDGh9OEG7+tpcKF9CV3Kuw1f
b5ZaHQIfeyymNk/cOnEKBrUktkT5TMMOpfM/VeplYmwzT4FgeHlbMAvdBaUdm70i
95T4wPGo/dyaE4eLZCg0T8DXVke1Y0eZQTEMiXHZ/xHCy2nqJ1nPMwdJfZ1bYSOC
Dcrc1CKhAgMBAAECggEAGmd5/SeRayg68Kgu/u+UsDd6g12/hGQWNuV48WCNUnYg
nGePXpSwCDpgFZGYNxRRT6pCrvNzs5km6jVL8umrzg8jBeSIhYZcAz/CR4TgLAuK
jI/RIOeT14+/7MGlHJZ2qsWq1yTUpXpBNEgMo93Jv17EfqJ4F+nA1yH2VOFySlZD
mrmLSp4YEJ707+KNkq0DjYfOt2uIRQ7A7GJHLJjJ06P60QIs6v0Ra3EwQUTJymH4
GRKjqZsg4Aj18limXv0WybtzXMNUxnp+z5MgjyvgnZ2PyRB1mvhu/uk3t09nj0Dm
0fMC99J5ABnJ2N2LzGOofUTFrEb7S8LRROJWgW0NhQKBgQDOc93fgmoBBeX0cuxG
lXkcr75c+dvJm5s7gqP6xqvVkxOAZBdCx7+y1c1gBPdY/Qqa2UJ+UkgSVAPu9tCk
YmxKE979/Wzbit9yqPcPjx95kNtPDRVi0rQ+VxZnXFOht10b0g/50k4nuqfN9gTm
+jXWDvhQmcCfFaFK0BOkX/P+UwKBgQDIhMncOmRCdcTq2DSQFD79XLkUa/d/EePM
JD+e87uo/FJGWLqNZiclcYYoEOmZWew20xI+l0uNyHSqkCPXz0qCak9s17WmSpPI
STNas/L0uKdvgy2vtCovTeuPlOqDYkY8Kz4EOkTWzMOEhRe887x68vCaAGo0ujQu
67yWTz20uwKBgQC3xXnNuEflyztLonThy7H4MBQSrTLQvluq2HphAzH4NihY1D/E
aQwiA6ECBMmsg+pJtnUy/sk6z2CE+Vz1xsrAEfogOtMIhhCq/u6VAgCxdJlTP8E2
q3pYN6swrIWhYRhXaGBiL6r0QHmYo5Lvi/AaME8naAWHVnixoJCrc+I8EwKBgQCX
JUDjeEBKuGsOeppkYF56rIH2GswcRGfpYQlzz1UNM+TwkcFNBEtNthzh5p2uslGT
odaGx5Rz8z29s5jQ+7e2RlxINvD9wAlVV5gWLr5cKTRMohy17KA/uARv3lhHYLSA
djfxB9sL7p0SLyCNlUvlgWpLKzTjOdhL5fXpdyGUMQKBgQCxVqnVCr98aMsVGZyK
zkXmkfhrSw2sFxh2Z5JVNhlqSkJEbx4WJdbmSoUEX5VEKZtzDwqJZRJ1UsOX0YnR
AuJlDqH1RXRgnaD97uyug2y8IVpd7PskbuHQRkF3pugO9UBM/M8u3IWZHg9ElpKB
j2E6s9oNzFcpq62yk7utvVFTyQ==
-----END PRIVATE KEY-----''',
  );

  runApp(
    MyApp(
      authRepository: authRepository,
      attendanceRepository: attendanceRepository,
      notificationService: notificationService,
      notificationRepository: notificationRepository,
      locationService: locationService,
      broadcastRepository: broadcastRepository,
      dismissalRepository: dismissalRepository,
      statsRepository: statsRepository,
      busTrackingRepository: busTrackingRepository,
      fcmV1Service: fcmV1Service,
      prefs: prefs,
    ),
  );
}

class MyApp extends StatelessWidget {
  final FirebaseAuthRepository authRepository;
  final FirebaseAttendanceRepository attendanceRepository;
  final NotificationService notificationService;
  final LocationService locationService;
  final BroadcastRepository broadcastRepository;
  final DismissalRepository dismissalRepository;
  final NotificationRepository notificationRepository;
  final StatsRepository statsRepository;
  final BusTrackingRepository busTrackingRepository;
  final FcmV1Service fcmV1Service;
  final SharedPreferences prefs;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.attendanceRepository,
    required this.notificationService,
    required this.notificationRepository,
    required this.locationService,
    required this.broadcastRepository,
    required this.dismissalRepository,
    required this.statsRepository,
    required this.busTrackingRepository,
    required this.fcmV1Service,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<AttendanceRepository>.value(
          value: attendanceRepository,
        ),
        RepositoryProvider<NotificationService>.value(
          value: notificationService,
        ),
        RepositoryProvider<LocationService>.value(value: locationService),
        RepositoryProvider<BroadcastRepository>.value(
          value: broadcastRepository,
        ),
        RepositoryProvider<DismissalRepository>.value(
          value: dismissalRepository,
        ),
        RepositoryProvider<NotificationRepository>.value(
          value: notificationRepository,
        ),
        RepositoryProvider<StatsRepository>.value(value: statsRepository),
        RepositoryProvider<BusTrackingRepository>.value(
          value: busTrackingRepository,
        ),
        RepositoryProvider<FcmV1Service>.value(
          value: fcmV1Service,
        ),
        RepositoryProvider(create: (context) => StorageService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(
              authRepository: authRepository,
              notificationService: notificationService,
            ),
          ),
          BlocProvider(create: (_) => ThemeCubit(prefs)),
          BlocProvider(create: (_) => LanguageCubit(prefs)),
          BlocProvider(
            create:
                (context) => DriverLocationCubit(
                  locationService: locationService,
                  repository: busTrackingRepository,
                ),
          ),
          BlocProvider(create: (context) => ConnectivityCubit()),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  late final GoRouter _router;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    
    // Listen for notification taps
    final notificationService = context.read<NotificationService>();
    _notificationSubscription = notificationService.navigationStream.listen(_handleNotificationNavigation);

    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: '/denied',
          builder: (context, state) => const AccessDeniedPage(),
        ),
        GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
        GoRoute(
          path: '/admin/add-staff',
          builder: (context, state) => const AddStaffPage(),
        ),
        GoRoute(
          path: '/add-student',
          builder: (context, state) => const AddStudentPage(),
        ),
        GoRoute(
          path: '/student-details',
          builder: (context, state) {
            final student = state.extra as StudentModel;
            return StudentDetailsPage(student: student);
          },
        ),
        GoRoute(
          path: '/admin/edit-student',
          builder: (context, state) {
            final student = state.extra as StudentModel;
            return EditStudentPage(student: student);
          },
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => const QrScannerPage(),
        ),
        GoRoute(
          path: '/tracking',
          builder: (context, state) {
            final busId = state.extra as String;
            return BusTrackingPage(busId: busId);
          },
        ),
        GoRoute(
          path: '/admin/broadcast',
          builder: (context, state) => const AdminBroadcastPage(),
        ),
        GoRoute(
          path: '/admin/broadcast-history',
          builder: (context, state) => const BroadcastHistoryPage(),
        ),
        GoRoute(
          path: '/admin/emergency-broadcast',
          builder: (context, state) => const EmergencyBroadcastPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsHistoryPage(),
        ),
        GoRoute(
          path: '/attendance-history',
          builder: (context, state) => const AttendanceHistoryPage(),
        ),
        GoRoute(
          path: '/notification-details',
          builder: (context, state) {
            final notification = state.extra as AppNotification;
            return NotificationDetailsPage(notification: notification);
          },
        ),
        GoRoute(
          path: '/admin/stats',
          builder: (context, state) => BlocProvider(
            create: (context) =>
                StatsCubit(context.read<StatsRepository>())..loadStats(),
            child: const AdminStatsPage(),
          ),
        ),
      ],
      redirect: (context, state) {
        final authBloc = context.read<AuthBloc>();
        final authStatus = authBloc.state.status;
        final user = authBloc.state.user;

        final isLoggingIn = state.matchedLocation == '/login';
        final isSigningUp = state.matchedLocation == '/signup';
        final isDenied = state.matchedLocation == '/denied';

        if (authStatus == AuthStatus.unauthenticated) {
          if (isLoggingIn || isSigningUp) return null;
          return '/login';
        }

        if (authStatus == AuthStatus.authenticated && user != null) {
          if (!user.isActive) {
            if (isDenied) return null;
            return '/denied';
          }

          if (isLoggingIn || isSigningUp || isDenied) {
            return '/';
          }
        }

        return null;
      },
      refreshListenable: _GoRouterRefreshStream(
        context.read<AuthBloc>().stream,
      ),
    );
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    debugPrint('Navigating based on notification data: $data');
    final type = data['type'];
    
    switch (type) {
      case 'check_in':
      case 'check_out':
        _router.push('/notifications');
        break;
      case 'bus_approaching':
        final busId = data['busId'];
        if (busId != null) {
          _router.push('/tracking', extra: busId);
        }
        break;
      default:
        _router.push('/notifications');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp.router(
              title: 'KidSecure',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ar'), // Arabic
                Locale('en'), // English
              ],
              locale: locale, // Dynamic locale
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: _router,
              builder: (context, child) {
                return BlocListener<ConnectivityCubit, ConnectivityState>(
                  listener: (context, state) {
                    if (state.status == ConnectivityStatus.disconnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)?.noInternet ??
                                'No internet connection',
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(days: 1), // Persistent
                          action: SnackBarAction(
                            label: AppLocalizations.of(context)?.close ?? 'Close',
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                            textColor: Colors.white,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }
                  },
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
