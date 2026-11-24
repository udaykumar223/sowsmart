import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_te.dart';

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
    Locale('en'),
    Locale('te'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SowSmart'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Weather-Aware Crop Scheduler and Profit Tracker'**
  String get tagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @continueDemo.
  ///
  /// In en, this message translates to:
  /// **'Continue in Demo Mode'**
  String get continueDemo;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu (తెలుగు)'**
  String get telugu;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder Time'**
  String get dailyReminder;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @todaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todaysTasks;

  /// No description provided for @cropCalendar.
  ///
  /// In en, this message translates to:
  /// **'Crop Calendar'**
  String get cropCalendar;

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fields;

  /// No description provided for @startPlanting.
  ///
  /// In en, this message translates to:
  /// **'Start Planting'**
  String get startPlanting;

  /// No description provided for @profitFinance.
  ///
  /// In en, this message translates to:
  /// **'Profit & Finance'**
  String get profitFinance;

  /// No description provided for @activePlantings.
  ///
  /// In en, this message translates to:
  /// **'Active Plantings'**
  String get activePlantings;

  /// No description provided for @newCrop.
  ///
  /// In en, this message translates to:
  /// **'+ New Crop'**
  String get newCrop;

  /// No description provided for @noActivePlantings.
  ///
  /// In en, this message translates to:
  /// **'No active plantings yet.'**
  String get noActivePlantings;

  /// No description provided for @startFirstPlanting.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Start Planting\' to begin your first crop cycle.'**
  String get startFirstPlanting;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get addField;

  /// No description provided for @editField.
  ///
  /// In en, this message translates to:
  /// **'Edit Field'**
  String get editField;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Field Name'**
  String get fieldName;

  /// No description provided for @areaAcres.
  ///
  /// In en, this message translates to:
  /// **'Area (acres)'**
  String get areaAcres;

  /// No description provided for @soilType.
  ///
  /// In en, this message translates to:
  /// **'Soil Type'**
  String get soilType;

  /// No description provided for @soilLoamy.
  ///
  /// In en, this message translates to:
  /// **'Loamy'**
  String get soilLoamy;

  /// No description provided for @soilClay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get soilClay;

  /// No description provided for @soilSandy.
  ///
  /// In en, this message translates to:
  /// **'Sandy'**
  String get soilSandy;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// No description provided for @locationAcquired.
  ///
  /// In en, this message translates to:
  /// **'Location acquired'**
  String get locationAcquired;

  /// No description provided for @noFields.
  ///
  /// In en, this message translates to:
  /// **'No fields added yet.'**
  String get noFields;

  /// No description provided for @addFirstField.
  ///
  /// In en, this message translates to:
  /// **'Tap \'+\' to add your first field.'**
  String get addFirstField;

  /// No description provided for @deleteField.
  ///
  /// In en, this message translates to:
  /// **'Delete Field'**
  String get deleteField;

  /// No description provided for @confirmDeleteField.
  ///
  /// In en, this message translates to:
  /// **'Delete this field and all its plantings?'**
  String get confirmDeleteField;

  /// No description provided for @selectCrop.
  ///
  /// In en, this message translates to:
  /// **'Select Crop'**
  String get selectCrop;

  /// No description provided for @selectField.
  ///
  /// In en, this message translates to:
  /// **'Select Field'**
  String get selectField;

  /// No description provided for @sowingDate.
  ///
  /// In en, this message translates to:
  /// **'Sowing Date'**
  String get sowingDate;

  /// No description provided for @seasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season Label'**
  String get seasonLabel;

  /// No description provided for @schedulePreview.
  ///
  /// In en, this message translates to:
  /// **'Schedule Preview'**
  String get schedulePreview;

  /// No description provided for @createPlanting.
  ///
  /// In en, this message translates to:
  /// **'Create Planting'**
  String get createPlanting;

  /// No description provided for @generatingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Generating schedule…'**
  String get generatingSchedule;

  /// No description provided for @cultivationTasks.
  ///
  /// In en, this message translates to:
  /// **'Cultivation Tasks'**
  String get cultivationTasks;

  /// No description provided for @stageProgress.
  ///
  /// In en, this message translates to:
  /// **'Stage Progress'**
  String get stageProgress;

  /// No description provided for @recordHarvest.
  ///
  /// In en, this message translates to:
  /// **'Record Harvest'**
  String get recordHarvest;

  /// No description provided for @harvestCompleted.
  ///
  /// In en, this message translates to:
  /// **'Harvest Completed'**
  String get harvestCompleted;

  /// No description provided for @viewPL.
  ///
  /// In en, this message translates to:
  /// **'View P&L'**
  String get viewPL;

  /// No description provided for @harvestedOn.
  ///
  /// In en, this message translates to:
  /// **'Harvested on {date}'**
  String harvestedOn(String date);

  /// No description provided for @yieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Yield: {qty} {unit}'**
  String yieldLabel(String qty, String unit);

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue Tasks'**
  String get overdueTasks;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get dueToday;

  /// No description provided for @noPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks for today 🌱'**
  String get noPendingTasks;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get markDone;

  /// No description provided for @postponeOneDay.
  ///
  /// In en, this message translates to:
  /// **'+1 Day'**
  String get postponeOneDay;

  /// No description provided for @postponed.
  ///
  /// In en, this message translates to:
  /// **'Postponed'**
  String get postponed;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @weatherSummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Weather'**
  String get weatherSummary;

  /// No description provided for @skipIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Skip Irrigation'**
  String get skipIrrigation;

  /// No description provided for @sprayWarning.
  ///
  /// In en, this message translates to:
  /// **'Spray Warning'**
  String get sprayWarning;

  /// No description provided for @heatAlert.
  ///
  /// In en, this message translates to:
  /// **'Heat Alert'**
  String get heatAlert;

  /// No description provided for @weatherGuidance.
  ///
  /// In en, this message translates to:
  /// **'Guidance only — verify with local extension office.'**
  String get weatherGuidance;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @cropPlanting.
  ///
  /// In en, this message translates to:
  /// **'Crop Planting'**
  String get cropPlanting;

  /// No description provided for @costCategory.
  ///
  /// In en, this message translates to:
  /// **'Cost Category'**
  String get costCategory;

  /// No description provided for @incomeCategory.
  ///
  /// In en, this message translates to:
  /// **'Income Category'**
  String get incomeCategory;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amount;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date'**
  String get transactionDate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notes;

  /// No description provided for @saveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get saveTransaction;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @netMargin.
  ///
  /// In en, this message translates to:
  /// **'Net Margin'**
  String get netMargin;

  /// No description provided for @perAcre.
  ///
  /// In en, this message translates to:
  /// **'/ acre'**
  String get perAcre;

  /// No description provided for @costBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Cost Breakdown by Category'**
  String get costBreakdown;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions recorded yet.'**
  String get noTransactions;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @allCropsSeasons.
  ///
  /// In en, this message translates to:
  /// **'All Crops & Seasons (Overall)'**
  String get allCropsSeasons;

  /// No description provided for @actualHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'Actual Harvest Date'**
  String get actualHarvestDate;

  /// No description provided for @totalYield.
  ///
  /// In en, this message translates to:
  /// **'Total Yield'**
  String get totalYield;

  /// No description provided for @totalSaleIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Sale Income (₹)'**
  String get totalSaleIncome;

  /// No description provided for @completeHarvest.
  ///
  /// In en, this message translates to:
  /// **'Complete Harvest & Close Cycle'**
  String get completeHarvest;

  /// No description provided for @harvestNote.
  ///
  /// In en, this message translates to:
  /// **'Recording harvest will close this crop cycle and commit the sale revenue to your profit tracker.'**
  String get harvestNote;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get noData;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get demoMode;

  /// No description provided for @demoModeNote.
  ///
  /// In en, this message translates to:
  /// **'Data is stored in memory only and will reset on restart.'**
  String get demoModeNote;
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
      <String>['en', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
