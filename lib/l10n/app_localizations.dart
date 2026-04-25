import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In ar, this message translates to:
  /// **'كيد سيكيور'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @parent.
  ///
  /// In ar, this message translates to:
  /// **'ولي أمر'**
  String get parent;

  /// No description provided for @gateOfficer.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول البوابة'**
  String get gateOfficer;

  /// No description provided for @driver.
  ///
  /// In ar, this message translates to:
  /// **'سائق الحافلة'**
  String get driver;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get notifications;

  /// No description provided for @tracking.
  ///
  /// In ar, this message translates to:
  /// **'تتبع'**
  String get tracking;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف'**
  String get profile;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك'**
  String get welcome;

  /// No description provided for @trackBus.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الحافلة'**
  String get trackBus;

  /// No description provided for @history.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get history;

  /// No description provided for @addStudent.
  ///
  /// In ar, this message translates to:
  /// **'أضف طفل'**
  String get addStudent;

  /// No description provided for @children.
  ///
  /// In ar, this message translates to:
  /// **'أبنائي'**
  String get children;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'المظهر الداكن'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @helpCenter.
  ///
  /// In ar, this message translates to:
  /// **'مركز المساعدة'**
  String get helpCenter;

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get quickActions;

  /// No description provided for @dashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة القيادة'**
  String get dashboard;

  /// No description provided for @adminConsole.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get adminConsole;

  /// No description provided for @emergency.
  ///
  /// In ar, this message translates to:
  /// **'طوارئ'**
  String get emergency;

  /// No description provided for @criticalAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات حرجة'**
  String get criticalAlerts;

  /// No description provided for @broadcast.
  ///
  /// In ar, this message translates to:
  /// **'بث'**
  String get broadcast;

  /// No description provided for @generalUpdates.
  ///
  /// In ar, this message translates to:
  /// **'تحديثات عامة'**
  String get generalUpdates;

  /// No description provided for @stats.
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get stats;

  /// No description provided for @viewActivity.
  ///
  /// In ar, this message translates to:
  /// **'عرض النشاط'**
  String get viewActivity;

  /// No description provided for @sentBroadcasts.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل المرسلة'**
  String get sentBroadcasts;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @noUsersFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على مستخدمين'**
  String get noUsersFound;

  /// No description provided for @schoolAdministrator.
  ///
  /// In ar, this message translates to:
  /// **'مدير المدرسة'**
  String get schoolAdministrator;

  /// No description provided for @addStaff.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موظف'**
  String get addStaff;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @pickupRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب استلام'**
  String get pickupRequest;

  /// No description provided for @requestSentSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب الانصراف بنجاح!'**
  String get requestSentSuccessfully;

  /// No description provided for @inSchool.
  ///
  /// In ar, this message translates to:
  /// **'في المدرسة'**
  String get inSchool;

  /// No description provided for @leftSchool.
  ///
  /// In ar, this message translates to:
  /// **'غادر'**
  String get leftSchool;

  /// No description provided for @onBus.
  ///
  /// In ar, this message translates to:
  /// **'في الحافلة'**
  String get onBus;

  /// No description provided for @notSpecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get notSpecified;

  /// No description provided for @requests.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get requests;

  /// No description provided for @dismissalRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الانصراف'**
  String get dismissalRequests;

  /// No description provided for @liveConnected.
  ///
  /// In ar, this message translates to:
  /// **'متصل مباشر'**
  String get liveConnected;

  /// No description provided for @searchStudentHint.
  ///
  /// In ar, this message translates to:
  /// **'البحث باسم الطالب أو الرقم التعريفي...'**
  String get searchStudentHint;

  /// No description provided for @activeRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات نشطة'**
  String get activeRequests;

  /// No description provided for @viewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get viewAll;

  /// No description provided for @errorFetchingData.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في جلب البيانات'**
  String get errorFetchingData;

  /// No description provided for @createFirestoreIndex.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إنشاء الفهرس المطلوب في Firestore console.'**
  String get createFirestoreIndex;

  /// No description provided for @noActiveRequests.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات نشطة حالياً'**
  String get noActiveRequests;

  /// No description provided for @parentLocationRadar.
  ///
  /// In ar, this message translates to:
  /// **'موقع أولياء الأمور (المنطقة الجغرافية)'**
  String get parentLocationRadar;

  /// No description provided for @mainGate.
  ///
  /// In ar, this message translates to:
  /// **'البوابة الرئيسية'**
  String get mainGate;

  /// No description provided for @autoUpdate.
  ///
  /// In ar, this message translates to:
  /// **'تحديث تلقائي'**
  String get autoUpdate;

  /// No description provided for @pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get pending;

  /// No description provided for @arrivingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قادم قريباً'**
  String get arrivingSoon;

  /// No description provided for @atGate.
  ///
  /// In ar, this message translates to:
  /// **'عند البوابة'**
  String get atGate;

  /// No description provided for @completed.
  ///
  /// In ar, this message translates to:
  /// **'تم الانصراف'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get cancelled;

  /// No description provided for @authorizedPerson.
  ///
  /// In ar, this message translates to:
  /// **'المصرح له'**
  String get authorizedPerson;

  /// No description provided for @confirmDismissal.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الخروج'**
  String get confirmDismissal;

  /// No description provided for @requestsHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الطلبات'**
  String get requestsHistory;

  /// No description provided for @latestCompletedRequests.
  ///
  /// In ar, this message translates to:
  /// **'أحدث الطلبات المنتهية'**
  String get latestCompletedRequests;

  /// No description provided for @historyEmpty.
  ///
  /// In ar, this message translates to:
  /// **'السجل فارغ حالياً'**
  String get historyEmpty;

  /// No description provided for @quickQrScanner.
  ///
  /// In ar, this message translates to:
  /// **'ماسح الرموز السريع'**
  String get quickQrScanner;

  /// No description provided for @qrScannerDesc.
  ///
  /// In ar, this message translates to:
  /// **'قم بمسح الكود الخاص بالطالب للتحقق الفوري وتسجيل الحضور أو الانصراف.'**
  String get qrScannerDesc;

  /// No description provided for @startCamera.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الكاميرا'**
  String get startCamera;

  /// No description provided for @manualChildSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث يدوي عن طفل'**
  String get manualChildSearch;

  /// No description provided for @profileScreen.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profileScreen;

  /// No description provided for @gateOfficerRoleLong.
  ///
  /// In ar, this message translates to:
  /// **'ضابط أمن البوابة'**
  String get gateOfficerRoleLong;

  /// No description provided for @appSettings.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق'**
  String get appSettings;

  /// No description provided for @supportAndHelp.
  ///
  /// In ar, this message translates to:
  /// **'الدعم والمساعدة'**
  String get supportAndHelp;

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutApp;

  /// No description provided for @manualStudentSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث يدوي عن طالب'**
  String get manualStudentSearch;

  /// No description provided for @enterStudentName.
  ///
  /// In ar, this message translates to:
  /// **'ادخل اسم الطالب...'**
  String get enterStudentName;

  /// No description provided for @typeTwoCharsToSearch.
  ///
  /// In ar, this message translates to:
  /// **'اكتب حرفين على الأقل للبحث'**
  String get typeTwoCharsToSearch;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @checkIn.
  ///
  /// In ar, this message translates to:
  /// **'حضور'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In ar, this message translates to:
  /// **'انصراف'**
  String get checkOut;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @attendanceCheckInSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الحضور لـ {name}'**
  String attendanceCheckInSuccess(Object name);

  /// No description provided for @attendanceCheckOutSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الانصراف لـ {name}'**
  String attendanceCheckOutSuccess(Object name);

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get english;

  /// No description provided for @scanner.
  ///
  /// In ar, this message translates to:
  /// **'ماسح'**
  String get scanner;

  /// No description provided for @languageSetting.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageSetting;

  /// No description provided for @busDriverDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة سائق الحافلة'**
  String get busDriverDashboard;

  /// No description provided for @studentManifest.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الطلاب'**
  String get studentManifest;

  /// No description provided for @noStudentsAssigned.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طلاب مسجلين لهذه الحافلة.'**
  String get noStudentsAssigned;

  /// No description provided for @busIdLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الحافلة: {id}'**
  String busIdLabel(String id);

  /// No description provided for @liveTrackingEnabled.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الموقع مفعل'**
  String get liveTrackingEnabled;

  /// No description provided for @liveStudentList.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الطلاب المباشرة'**
  String get liveStudentList;

  /// No description provided for @pickup.
  ///
  /// In ar, this message translates to:
  /// **'ركوب'**
  String get pickup;

  /// No description provided for @dropoff.
  ///
  /// In ar, this message translates to:
  /// **'نزول'**
  String get dropoff;

  /// No description provided for @notifyNearArrival.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه اقتراب'**
  String get notifyNearArrival;

  /// No description provided for @arrivalNotificationSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال تنبيه الاقتراب'**
  String get arrivalNotificationSent;

  /// No description provided for @busUpdate.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الحافلة'**
  String get busUpdate;

  /// No description provided for @onBusNow.
  ///
  /// In ar, this message translates to:
  /// **'{name} ركب الحافلة الآن'**
  String onBusNow(String name);

  /// No description provided for @offBusNow.
  ///
  /// In ar, this message translates to:
  /// **'{name} نزل من الحافلة الآن'**
  String offBusNow(String name);

  /// No description provided for @pickedUpSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الركوب بنجاح'**
  String get pickedUpSuccessfully;

  /// No description provided for @droppedOffSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل النزول بنجاح'**
  String get droppedOffSuccessfully;

  /// No description provided for @busArrivalAlert.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه اقتراب الحافلة'**
  String get busArrivalAlert;

  /// No description provided for @busApproachingBody.
  ///
  /// In ar, this message translates to:
  /// **'حافلة {name} تقترب، ستصل خلال دقيقة تقريباً.'**
  String busApproachingBody(String name);

  /// No description provided for @scanStudentQr.
  ///
  /// In ar, this message translates to:
  /// **'مسح رمز الطالب'**
  String get scanStudentQr;

  /// No description provided for @alignQrCode.
  ///
  /// In ar, this message translates to:
  /// **'ضع كود التلميذ داخل المربع للمسح'**
  String get alignQrCode;

  /// No description provided for @studentNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الطالب غير موجود'**
  String get studentNotFound;

  /// No description provided for @errorProcessingScan.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في معالجة المسح'**
  String get errorProcessingScan;

  /// No description provided for @gradeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصف: {grade}'**
  String gradeLabel(String grade);

  /// No description provided for @checkInAction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حضور'**
  String get checkInAction;

  /// No description provided for @checkOutAction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل انصراف'**
  String get checkOutAction;

  /// No description provided for @scanSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم المسح بنجاح: {status}'**
  String scanSuccess(Object status);

  /// No description provided for @startTripStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الرحلة'**
  String get startTripStatus;

  /// No description provided for @tripInProgress.
  ///
  /// In ar, this message translates to:
  /// **'الرحلة قيد التنفيذ'**
  String get tripInProgress;

  /// No description provided for @inactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get inactive;

  /// No description provided for @scan.
  ///
  /// In ar, this message translates to:
  /// **'المسح'**
  String get scan;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get resetPassword;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.'**
  String get resetPasswordDesc;

  /// No description provided for @sendLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرابط'**
  String get sendLink;

  /// No description provided for @resetPasswordEmailSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط إعادة التعيين! تحقق من بريدك الإلكتروني.'**
  String get resetPasswordEmailSent;

  /// No description provided for @enterEmailError.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال البريد الإلكتروني'**
  String get enterEmailError;

  /// No description provided for @errorTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get errorTitle;

  /// No description provided for @noInternet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.'**
  String get noInternet;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get ok;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صالح.'**
  String get invalidEmail;

  /// No description provided for @userNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حساب مسجل بهذا البريد الإلكتروني.'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور التي أدخلتها غير صحيحة.'**
  String get wrongPassword;

  /// No description provided for @tooManyRequests.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة جداً. يرجى المحاولة مرة أخرى لاحقاً.'**
  String get tooManyRequests;

  /// No description provided for @unknownError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'**
  String get unknownError;

  /// No description provided for @schoolGateUpdate.
  ///
  /// In ar, this message translates to:
  /// **'تحديث البوابة'**
  String get schoolGateUpdate;

  /// No description provided for @enteredSchool.
  ///
  /// In ar, this message translates to:
  /// **'دخل {name} المدرسة للتو'**
  String enteredSchool(String name);

  /// No description provided for @leftSchoolNotification.
  ///
  /// In ar, this message translates to:
  /// **'غادر {name} المدرسة للتو'**
  String leftSchoolNotification(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
