import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en')
  ];

  String get appTitle;
  String get settings;
  String get themeSettings;
  String get languageSettings;
  String get chooseTheme;
  String get followSystem;
  String get followSystemSubtitle;
  String get lightMode;
  String get lightModeSubtitle;
  String get darkMode;
  String get darkModeSubtitle;
  String get featureSettings;
  String get quickReportMode;
  String get quickReportModeSubtitle;
  String get chooseLanguage;
  String get chinese;
  String get english;
  String get login;
  String get username;
  String get password;
  String get serverAddress;
  String get pleaseEnterServerAddress;
  String get pleaseEnterUsername;
  String get pleaseEnterPassword;
  String get loginFailed;
  String get networkError;
  String get add;
  String get save;
  String get cancel;
  String get confirm;
  String get delete;
  String get edit;
  String get loading;
  String get noData;
  String get selectChild;
  String get noChildSelected;
  String get addChild;
  String get childName;
  String get birthday;
  String get feeding;
  String get sleep;
  String get diaper;
  String get pumping;
  String get tummyTime;
  String get temperature;
  String get weight;
  String get height;
  String get headCircumference;
  String get startTimer;
  String get quickAdd;
  String get timer;
  String get quickReport;
  String get about;
  String get logout;
  String get confirmLogout;
  String get refresh;
  String get error;
  String get success;
  String get notes;
  String get amount;
  String get duration;
  String get startTime;
  String get endTime;
  String get breastMilk;
  String get formula;
  String get fortifiedBreastMilk;
  String get pumpedMilk;
  String get leftBreast;
  String get rightBreast;
  String get bothBreasts;
  String get bottle;
  String get spoon;
  String get nap;
  String get sleeping;
  String get wet;
  String get solid;
  String get wetAndSolid;
  String get change;
  String get milkType;
  String get feedingMethod;
  String get unit;
  String get milestone;
  String get timerRestarted;
  String get timerStopped;
  String get recordFeeding;
  String get recordSleep;
  String get recordTummyTime;
  String get restartTimer;
  String get stopTimer;
  String get feedingRecorded;
  String get feedingUpdated;
  String get sleepRecorded;
  String get sleepUpdated;
  String get tummyTimeRecorded;
  String get tummyTimeUpdated;
  String get addFailed;
  String get updateFailed;
  String get noPermission;
  String get confirmDelete;
  String get confirmDeleteRecord;
  String get typeNotSupported;
  String get typeNotSupportedDelete;
  String get deleteSuccess;
  String get loadTimelineFailed;
  String get startTimerFailed;
  String get timerStarted;
  String get cannotOpenUrl;
  String get linkCopied;
  String get clickMenuSelectChild;
  String get reload;
  String get loadFailed;
  String get noRecords;
  String get clickAddRecord;
  String get currentBaby;
  String get notSelected;
  String get clickCopyLink;
  String get longPressCopyLink;
  String get addRecord;
  String get moreOptions;
  String get note;
  String get content;
  String get date;
  String get time;
  String get color;
  String get unknown;
  String get yellow;
  String get brown;
  String get green;
  String get other;
  String get type;
  String get method;
  String get weightKg;
  String get heightCm;
  String get headCircumferenceCm;
  String get temperatureC;
  String get babyGrowthAssistant;
  String get author;
  String get sourceRepo;
  String get projectIntro;
  String get projectDesc;
  String get copyrightInfo;
  String get copyrightText;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }
  return AppLocalizationsEn();
}
