// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SowSmart';

  @override
  String get tagline => 'Weather-Aware Crop Scheduler and Profit Tracker';

  @override
  String get login => 'Login';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get continueDemo => 'Continue in Demo Mode';

  @override
  String get signOut => 'Sign Out';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get telugu => 'Telugu (తెలుగు)';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System Default';

  @override
  String get dailyReminder => 'Daily Reminder Time';

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get home => 'Home';

  @override
  String get welcome => 'Welcome';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get todaysTasks => 'Today\'s Tasks';

  @override
  String get cropCalendar => 'Crop Calendar';

  @override
  String get fields => 'Fields';

  @override
  String get startPlanting => 'Start Planting';

  @override
  String get profitFinance => 'Profit & Finance';

  @override
  String get activePlantings => 'Active Plantings';

  @override
  String get newCrop => '+ New Crop';

  @override
  String get noActivePlantings => 'No active plantings yet.';

  @override
  String get startFirstPlanting =>
      'Tap \'Start Planting\' to begin your first crop cycle.';

  @override
  String get addField => 'Add Field';

  @override
  String get editField => 'Edit Field';

  @override
  String get fieldName => 'Field Name';

  @override
  String get areaAcres => 'Area (acres)';

  @override
  String get soilType => 'Soil Type';

  @override
  String get soilLoamy => 'Loamy';

  @override
  String get soilClay => 'Clay';

  @override
  String get soilSandy => 'Sandy';

  @override
  String get useMyLocation => 'Use My Location';

  @override
  String get locationAcquired => 'Location acquired';

  @override
  String get noFields => 'No fields added yet.';

  @override
  String get addFirstField => 'Tap \'+\' to add your first field.';

  @override
  String get deleteField => 'Delete Field';

  @override
  String get confirmDeleteField => 'Delete this field and all its plantings?';

  @override
  String get selectCrop => 'Select Crop';

  @override
  String get selectField => 'Select Field';

  @override
  String get sowingDate => 'Sowing Date';

  @override
  String get seasonLabel => 'Season Label';

  @override
  String get schedulePreview => 'Schedule Preview';

  @override
  String get createPlanting => 'Create Planting';

  @override
  String get generatingSchedule => 'Generating schedule…';

  @override
  String get cultivationTasks => 'Cultivation Tasks';

  @override
  String get stageProgress => 'Stage Progress';

  @override
  String get recordHarvest => 'Record Harvest';

  @override
  String get harvestCompleted => 'Harvest Completed';

  @override
  String get viewPL => 'View P&L';

  @override
  String harvestedOn(String date) {
    return 'Harvested on $date';
  }

  @override
  String yieldLabel(String qty, String unit) {
    return 'Yield: $qty $unit';
  }

  @override
  String get overdueTasks => 'Overdue Tasks';

  @override
  String get dueToday => 'Due Today';

  @override
  String get noPendingTasks => 'No pending tasks for today 🌱';

  @override
  String get markDone => 'Mark Done';

  @override
  String get postponeOneDay => '+1 Day';

  @override
  String get postponed => 'Postponed';

  @override
  String get done => 'Done';

  @override
  String get pending => 'Pending';

  @override
  String get weatherSummary => 'Today\'s Weather';

  @override
  String get skipIrrigation => 'Skip Irrigation';

  @override
  String get sprayWarning => 'Spray Warning';

  @override
  String get heatAlert => 'Heat Alert';

  @override
  String get weatherGuidance =>
      'Guidance only — verify with local extension office.';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get cropPlanting => 'Crop Planting';

  @override
  String get costCategory => 'Cost Category';

  @override
  String get incomeCategory => 'Income Category';

  @override
  String get amount => 'Amount (₹)';

  @override
  String get transactionDate => 'Transaction Date';

  @override
  String get notes => 'Notes (optional)';

  @override
  String get saveTransaction => 'Save Transaction';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get netMargin => 'Net Margin';

  @override
  String get perAcre => '/ acre';

  @override
  String get costBreakdown => 'Cost Breakdown by Category';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get noTransactions => 'No transactions recorded yet.';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get allCropsSeasons => 'All Crops & Seasons (Overall)';

  @override
  String get actualHarvestDate => 'Actual Harvest Date';

  @override
  String get totalYield => 'Total Yield';

  @override
  String get totalSaleIncome => 'Total Sale Income (₹)';

  @override
  String get completeHarvest => 'Complete Harvest & Close Cycle';

  @override
  String get harvestNote =>
      'Recording harvest will close this crop cycle and commit the sale revenue to your profit tracker.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get noData => 'No data available.';

  @override
  String get demoMode => 'Demo Mode';

  @override
  String get demoModeNote =>
      'Data is stored in memory only and will reset on restart.';
}
