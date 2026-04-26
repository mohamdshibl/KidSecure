// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'كيد سيكيور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get parent => 'ولي أمر';

  @override
  String get gateOfficer => 'مسؤول البوابة';

  @override
  String get driver => 'سائق الحافلة';

  @override
  String get home => 'الرئيسية';

  @override
  String get notifications => 'التنبيهات';

  @override
  String get tracking => 'تتبع';

  @override
  String get profile => 'الملف';

  @override
  String get welcome => 'أهلاً بك';

  @override
  String get trackBus => 'تتبع الحافلة';

  @override
  String get history => 'السجل';

  @override
  String get addStudent => 'أضف طفل';

  @override
  String get children => 'أبنائي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get darkMode => 'المظهر الداكن';

  @override
  String get language => 'اللغة';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get dashboard => 'لوحة القيادة';

  @override
  String get adminConsole => 'لوحة الإدارة';

  @override
  String get emergency => 'طوارئ';

  @override
  String get criticalAlerts => 'تنبيهات حرجة';

  @override
  String get broadcast => 'بث';

  @override
  String get generalUpdates => 'تحديثات عامة';

  @override
  String get stats => 'الإحصائيات';

  @override
  String get viewActivity => 'عرض النشاط';

  @override
  String get sentBroadcasts => 'الرسائل المرسلة';

  @override
  String get all => 'الكل';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get schoolAdministrator => 'مدير المدرسة';

  @override
  String get addStaff => 'إضافة موظف';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get pickupRequest => 'طلب استلام';

  @override
  String get requestSentSuccessfully => 'تم إرسال طلب الانصراف بنجاح!';

  @override
  String get inSchool => 'في المدرسة';

  @override
  String get leftSchool => 'غادر';

  @override
  String get onBus => 'في الحافلة';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get requests => 'الطلبات';

  @override
  String get dismissalRequests => 'طلبات الانصراف';

  @override
  String get liveConnected => 'متصل مباشر';

  @override
  String get searchStudentHint => 'البحث باسم الطالب أو الرقم التعريفي...';

  @override
  String get activeRequests => 'طلبات نشطة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get errorFetchingData => 'حدث خطأ في جلب البيانات';

  @override
  String get createFirestoreIndex =>
      'يرجى إنشاء الفهرس المطلوب في Firestore console.';

  @override
  String get noActiveRequests => 'لا توجد طلبات نشطة حالياً';

  @override
  String get parentLocationRadar => 'موقع أولياء الأمور (المنطقة الجغرافية)';

  @override
  String get mainGate => 'البوابة الرئيسية';

  @override
  String get autoUpdate => 'تحديث تلقائي';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get arrivingSoon => 'قادم قريباً';

  @override
  String get atGate => 'عند البوابة';

  @override
  String get completed => 'تم الانصراف';

  @override
  String get cancelled => 'ملغي';

  @override
  String get authorizedPerson => 'المصرح له';

  @override
  String get confirmDismissal => 'تأكيد الخروج';

  @override
  String get requestsHistory => 'سجل الطلبات';

  @override
  String get latestCompletedRequests => 'أحدث الطلبات المنتهية';

  @override
  String get historyEmpty => 'السجل فارغ حالياً';

  @override
  String get quickQrScanner => 'ماسح الرموز السريع';

  @override
  String get qrScannerDesc =>
      'قم بمسح الكود الخاص بالطالب للتحقق الفوري وتسجيل الحضور أو الانصراف.';

  @override
  String get startCamera => 'تشغيل الكاميرا';

  @override
  String get manualChildSearch => 'بحث يدوي عن طفل';

  @override
  String get profileScreen => 'الملف الشخصي';

  @override
  String get gateOfficerRoleLong => 'ضابط أمن البوابة';

  @override
  String get appSettings => 'التطبيق';

  @override
  String get supportAndHelp => 'الدعم والمساعدة';

  @override
  String get aboutApp => 'عن التطبيق';

  @override
  String get manualStudentSearch => 'بحث يدوي عن طالب';

  @override
  String get enterStudentName => 'ادخل اسم الطالب...';

  @override
  String get typeTwoCharsToSearch => 'اكتب حرفين على الأقل للبحث';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get checkIn => 'حضور';

  @override
  String get checkOut => 'انصراف';

  @override
  String get close => 'إغلاق';

  @override
  String attendanceCheckInSuccess(Object name) {
    return 'تم تسجيل الحضور لـ $name';
  }

  @override
  String attendanceCheckOutSuccess(Object name) {
    return 'تم تسجيل الانصراف لـ $name';
  }

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get scanner => 'ماسح';

  @override
  String get languageSetting => 'اللغة';

  @override
  String get busDriverDashboard => 'لوحة سائق الحافلة';

  @override
  String get studentManifest => 'قائمة الطلاب';

  @override
  String get noStudentsAssigned => 'لا يوجد طلاب مسجلين لهذه الحافلة.';

  @override
  String busIdLabel(String id) {
    return 'رقم الحافلة: $id';
  }

  @override
  String get liveTrackingEnabled => 'تتبع الموقع مفعل';

  @override
  String get liveStudentList => 'قائمة الطلاب المباشرة';

  @override
  String get pickup => 'ركوب';

  @override
  String get dropoff => 'نزول';

  @override
  String get notifyNearArrival => 'تنبيه اقتراب';

  @override
  String get arrivalNotificationSent => 'تم إرسال تنبيه الاقتراب';

  @override
  String get busUpdate => 'تحديث الحافلة';

  @override
  String onBusNow(String name) {
    return '$name ركب الحافلة الآن';
  }

  @override
  String offBusNow(String name) {
    return '$name نزل من الحافلة الآن';
  }

  @override
  String get pickedUpSuccessfully => 'تم تسجيل الركوب بنجاح';

  @override
  String get droppedOffSuccessfully => 'تم تسجيل النزول بنجاح';

  @override
  String get busArrivalAlert => 'تنبيه اقتراب الحافلة';

  @override
  String busApproachingBody(String name) {
    return 'حافلة $name تقترب، ستصل خلال دقيقة تقريباً.';
  }

  @override
  String get scanStudentQr => 'مسح رمز الطالب';

  @override
  String get alignQrCode => 'ضع كود التلميذ داخل المربع للمسح';

  @override
  String get studentNotFound => 'الطالب غير موجود';

  @override
  String get errorProcessingScan => 'خطأ في معالجة المسح';

  @override
  String gradeLabel(String grade) {
    return 'الصف: $grade';
  }

  @override
  String get checkInAction => 'تسجيل حضور';

  @override
  String get checkOutAction => 'تسجيل انصراف';

  @override
  String scanSuccess(Object status) {
    return 'تم المسح بنجاح: $status';
  }

  @override
  String get startTripStatus => 'حالة الرحلة';

  @override
  String get tripInProgress => 'الرحلة قيد التنفيذ';

  @override
  String get inactive => 'غير نشط';

  @override
  String get scan => 'المسح';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordDesc =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.';

  @override
  String get sendLink => 'إرسال الرابط';

  @override
  String get resetPasswordEmailSent =>
      'تم إرسال رابط إعادة التعيين! تحقق من بريدك الإلكتروني.';

  @override
  String get enterEmailError => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get errorTitle => 'خطأ';

  @override
  String get noInternet => 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';

  @override
  String get ok => 'حسناً';

  @override
  String get invalidEmail => 'البريد الإلكتروني غير صالح.';

  @override
  String get userNotFound => 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';

  @override
  String get wrongPassword => 'كلمة المرور التي أدخلتها غير صحيحة.';

  @override
  String get tooManyRequests =>
      'محاولات كثيرة جداً. يرجى المحاولة مرة أخرى لاحقاً.';

  @override
  String get unknownError => 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';

  @override
  String get schoolGateUpdate => 'تحديث البوابة';

  @override
  String enteredSchool(String name) {
    return 'دخل $name المدرسة الان';
  }

  @override
  String leftSchoolNotification(String name) {
    return 'غادر $name المدرسة الان';
  }
}
