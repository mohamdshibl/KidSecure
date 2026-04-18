// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KidSecure';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get parent => 'Parent';

  @override
  String get gateOfficer => 'Gate Officer';

  @override
  String get driver => 'Bus Driver';

  @override
  String get home => 'Home';

  @override
  String get notifications => 'Notifications';

  @override
  String get tracking => 'Tracking';

  @override
  String get profile => 'Profile';

  @override
  String get welcome => 'Welcome';

  @override
  String get trackBus => 'Track Bus';

  @override
  String get history => 'History';

  @override
  String get addStudent => 'Add Student';

  @override
  String get children => 'My Children';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get adminConsole => 'Admin Console';

  @override
  String get emergency => 'Emergency';

  @override
  String get criticalAlerts => 'Critical alerts';

  @override
  String get broadcast => 'Broadcast';

  @override
  String get generalUpdates => 'General updates';

  @override
  String get stats => 'Stats';

  @override
  String get viewActivity => 'View activity';

  @override
  String get sentBroadcasts => 'Sent broadcasts';

  @override
  String get all => 'All';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get schoolAdministrator => 'School Administrator';

  @override
  String get addStaff => 'Add Staff';

  @override
  String get logout => 'Logout';

  @override
  String get pickupRequest => 'Pickup Request';

  @override
  String get requestSentSuccessfully => 'Pickup request sent successfully!';

  @override
  String get inSchool => 'In School';

  @override
  String get leftSchool => 'Left';

  @override
  String get onBus => 'On Bus';

  @override
  String get notSpecified => 'Not Specified';

  @override
  String get requests => 'Requests';

  @override
  String get dismissalRequests => 'Dismissal Requests';

  @override
  String get liveConnected => 'Live Connected';

  @override
  String get searchStudentHint => 'Search by student name or ID...';

  @override
  String get activeRequests => 'Active Requests';

  @override
  String get viewAll => 'View All';

  @override
  String get errorFetchingData => 'Error fetching data';

  @override
  String get createFirestoreIndex =>
      'Please create the required index in Firestore console.';

  @override
  String get noActiveRequests => 'No active requests currently';

  @override
  String get parentLocationRadar => 'Parent Locations (Geofence)';

  @override
  String get mainGate => 'Main Gate';

  @override
  String get autoUpdate => 'Auto Update';

  @override
  String get pending => 'Pending';

  @override
  String get arrivingSoon => 'Arriving Soon';

  @override
  String get atGate => 'At Gate';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get authorizedPerson => 'Authorized Person';

  @override
  String get confirmDismissal => 'Confirm Dismissal';

  @override
  String get requestsHistory => 'Requests History';

  @override
  String get latestCompletedRequests => 'Latest Completed Requests';

  @override
  String get historyEmpty => 'History is currently empty';

  @override
  String get quickQrScanner => 'Quick QR Scanner';

  @override
  String get qrScannerDesc =>
      'Scan student\'s QR code for instant verification and attendance registration.';

  @override
  String get startCamera => 'Start Camera';

  @override
  String get manualChildSearch => 'Manual Child Search';

  @override
  String get profileScreen => 'Profile Screen';

  @override
  String get gateOfficerRoleLong => 'Gate Security Officer';

  @override
  String get appSettings => 'App';

  @override
  String get supportAndHelp => 'Support & Help';

  @override
  String get aboutApp => 'About App';

  @override
  String get manualStudentSearch => 'Manual Student Search';

  @override
  String get enterStudentName => 'Enter student name...';

  @override
  String get typeTwoCharsToSearch => 'Type at least two characters to search';

  @override
  String get noResults => 'No results';

  @override
  String get checkIn => 'Check-in';

  @override
  String get checkOut => 'Check-out';

  @override
  String get close => 'Close';

  @override
  String attendanceCheckInSuccess(Object name) {
    return 'Attendance check-in success for $name';
  }

  @override
  String attendanceCheckOutSuccess(Object name) {
    return 'Attendance check-out success for $name';
  }

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get scanner => 'Scanner';

  @override
  String get languageSetting => 'Language';

  @override
  String get busDriverDashboard => 'Bus Driver Dashboard';

  @override
  String get studentManifest => 'Student Manifest';

  @override
  String get noStudentsAssigned => 'No students assigned to this bus.';

  @override
  String busIdLabel(String id) {
    return 'Bus ID: $id';
  }

  @override
  String get liveTrackingEnabled => 'Live Tracking Enabled';

  @override
  String get liveStudentList => 'Live Student List';

  @override
  String get pickup => 'Pick-up';

  @override
  String get dropoff => 'Drop-off';

  @override
  String get notifyNearArrival => 'Notify Near Arrival';

  @override
  String get arrivalNotificationSent => 'Arrival notification sent';

  @override
  String get busUpdate => 'Bus Update';

  @override
  String onBusNow(String name) {
    return '$name is on the bus now';
  }

  @override
  String offBusNow(String name) {
    return '$name is off the bus now';
  }

  @override
  String get pickedUpSuccessfully => 'Picked up successfully';

  @override
  String get droppedOffSuccessfully => 'Dropped off successfully';

  @override
  String get busArrivalAlert => 'Bus Arrival Alert';

  @override
  String busApproachingBody(String name) {
    return '$name\'s bus is approaching, will arrive in about a minute.';
  }

  @override
  String get scanStudentQr => 'Scan Student QR';

  @override
  String get alignQrCode => 'Align student QR code within the frame';

  @override
  String get studentNotFound => 'Student not found';

  @override
  String get errorProcessingScan => 'Error processing scan';

  @override
  String gradeLabel(String grade) {
    return 'Grade: $grade';
  }

  @override
  String get checkInAction => 'Check In';

  @override
  String get checkOutAction => 'Check Out';

  @override
  String scanSuccess(Object status) {
    return 'Scan Success: $status';
  }

  @override
  String get startTripStatus => 'Trip Status';

  @override
  String get tripInProgress => 'Trip in Progress';

  @override
  String get inactive => 'Inactive';

  @override
  String get scan => 'Scan';
}
