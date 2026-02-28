import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
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
import 'package:intl/date_symbol_data_local.dart';

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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'KidSecure',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: _router,
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
