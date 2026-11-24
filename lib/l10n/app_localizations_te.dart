// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'సౌస్మార్ట్';

  @override
  String get tagline => 'వాతావరణ ఆధారిత పంట ప్రణాళిక మరియు లాభాల ట్రాకర్';

  @override
  String get login => 'లాగిన్';

  @override
  String get signInWithGoogle => 'Google తో సైన్ ఇన్ చేయండి';

  @override
  String get continueDemo => 'డెమో మోడ్‌లో కొనసాగండి';

  @override
  String get signOut => 'సైన్ అవుట్';

  @override
  String get settings => 'సెట్టింగ్‌లు';

  @override
  String get language => 'భాష';

  @override
  String get selectLanguage => 'భాషను ఎంచుకోండి';

  @override
  String get english => 'English';

  @override
  String get telugu => 'తెలుగు';

  @override
  String get themeMode => 'థీమ్ మోడ్';

  @override
  String get themeLight => 'లైట్';

  @override
  String get themeDark => 'డార్క్';

  @override
  String get themeSystem => 'సిస్టమ్ డిఫాల్ట్';

  @override
  String get dailyReminder => 'రోజువారీ రిమైండర్ సమయం';

  @override
  String get notificationPermission => 'నోటిఫికేషన్ అనుమతి';

  @override
  String get home => 'హోమ్';

  @override
  String get welcome => 'స్వాగతం';

  @override
  String signedInAs(String email) {
    return '$email గా లాగిన్ అయ్యారు';
  }

  @override
  String get todaysTasks => 'నేటి పనులు';

  @override
  String get cropCalendar => 'పంట క్యాలెండర్';

  @override
  String get fields => 'పొలాలు';

  @override
  String get startPlanting => 'విత్తనం వేయి';

  @override
  String get profitFinance => 'లాభం & ఆర్థికం';

  @override
  String get activePlantings => 'క్రియాశీల పంటలు';

  @override
  String get newCrop => '+ కొత్త పంట';

  @override
  String get noActivePlantings => 'ఇంకా క్రియాశీల పంటలు లేవు.';

  @override
  String get startFirstPlanting =>
      'మీ మొదటి పంట చక్రం ప్రారంభించడానికి \'విత్తనం వేయి\' నొక్కండి.';

  @override
  String get addField => 'పొలం జోడించు';

  @override
  String get editField => 'పొలం సవరించు';

  @override
  String get fieldName => 'పొలం పేరు';

  @override
  String get areaAcres => 'విస్తీర్ణం (ఎకరాలు)';

  @override
  String get soilType => 'మట్టి రకం';

  @override
  String get soilLoamy => 'గోరు నేల';

  @override
  String get soilClay => 'బంకమట్టి నేల';

  @override
  String get soilSandy => 'ఇసుక నేల';

  @override
  String get useMyLocation => 'నా స్థానాన్ని వాడు';

  @override
  String get locationAcquired => 'స్థానం పొందబడింది';

  @override
  String get noFields => 'ఇంకా పొలాలు జోడించబడలేదు.';

  @override
  String get addFirstField => 'మీ మొదటి పొలం జోడించడానికి \'+\' నొక్కండి.';

  @override
  String get deleteField => 'పొలం తొలగించు';

  @override
  String get confirmDeleteField => 'ఈ పొలం మరియు దాని అన్ని పంటలను తొలగించాలా?';

  @override
  String get selectCrop => 'పంటను ఎంచుకోండి';

  @override
  String get selectField => 'పొలాన్ని ఎంచుకోండి';

  @override
  String get sowingDate => 'విత్తన తేదీ';

  @override
  String get seasonLabel => 'సీజన్ పేరు';

  @override
  String get schedulePreview => 'షెడ్యూల్ ముందుచూపు';

  @override
  String get createPlanting => 'పంట రూపొందించు';

  @override
  String get generatingSchedule => 'షెడ్యూల్ తయారవుతోంది…';

  @override
  String get cultivationTasks => 'సాగు పనులు';

  @override
  String get stageProgress => 'దశ పురోగతి';

  @override
  String get recordHarvest => 'పంట కోత నమోదు చేయి';

  @override
  String get harvestCompleted => 'పంట కోత పూర్తయింది';

  @override
  String get viewPL => 'లాభనష్టాలు చూడు';

  @override
  String harvestedOn(String date) {
    return '$date న పంట కోయబడింది';
  }

  @override
  String yieldLabel(String qty, String unit) {
    return 'దిగుబడి: $qty $unit';
  }

  @override
  String get overdueTasks => 'గడువు మించిన పనులు';

  @override
  String get dueToday => 'నేడు చేయవలసినవి';

  @override
  String get noPendingTasks => 'నేటికి పెండింగ్ పనులు లేవు 🌱';

  @override
  String get markDone => 'పూర్తయినట్లు గుర్తించు';

  @override
  String get postponeOneDay => '+1 రోజు';

  @override
  String get postponed => 'వాయిదా వేయబడింది';

  @override
  String get done => 'పూర్తయింది';

  @override
  String get pending => 'పెండింగ్';

  @override
  String get weatherSummary => 'నేటి వాతావరణం';

  @override
  String get skipIrrigation => 'సేద్యం వద్దు';

  @override
  String get sprayWarning => 'పిచికారీ హెచ్చరిక';

  @override
  String get heatAlert => 'వేడి హెచ్చరిక';

  @override
  String get weatherGuidance =>
      'మార్గదర్శకత్వం మాత్రమే — స్థానిక వ్యవసాయ శాఖతో ధృవీకరించండి.';

  @override
  String get addTransaction => 'లావాదేవీ జోడించు';

  @override
  String get expense => 'ఖర్చు';

  @override
  String get income => 'ఆదాయం';

  @override
  String get cropPlanting => 'పంట';

  @override
  String get costCategory => 'ఖర్చు వర్గం';

  @override
  String get incomeCategory => 'ఆదాయ వర్గం';

  @override
  String get amount => 'మొత్తం (₹)';

  @override
  String get transactionDate => 'లావాదేవీ తేదీ';

  @override
  String get notes => 'గమనికలు (ఐచ్ఛికం)';

  @override
  String get saveTransaction => 'లావాదేవీ సేవ్ చేయి';

  @override
  String get totalRevenue => 'మొత్తం ఆదాయం';

  @override
  String get totalExpenses => 'మొత్తం ఖర్చులు';

  @override
  String get netProfit => 'నికర లాభం';

  @override
  String get netMargin => 'నికర మార్జిన్';

  @override
  String get perAcre => '/ ఎకరా';

  @override
  String get costBreakdown => 'వర్గం వారీగా ఖర్చుల వివరణ';

  @override
  String get recentTransactions => 'ఇటీవలి లావాదేవీలు';

  @override
  String get noTransactions => 'ఇంకా లావాదేవీలు నమోదు కాలేదు.';

  @override
  String get deleteTransaction => 'లావాదేవీ తొలగించు';

  @override
  String get allCropsSeasons => 'అన్ని పంటలు & సీజన్లు (మొత్తం)';

  @override
  String get actualHarvestDate => 'అసలు కోత తేదీ';

  @override
  String get totalYield => 'మొత్తం దిగుబడి';

  @override
  String get totalSaleIncome => 'మొత్తం విక్రయ ఆదాయం (₹)';

  @override
  String get completeHarvest => 'పంట కోత పూర్తి చేసి చక్రం మూయి';

  @override
  String get harvestNote =>
      'పంట కోత నమోదు చేయడం ద్వారా ఈ పంట చక్రం మూయబడుతుంది మరియు విక్రయ ఆదాయం లాభాల ట్రాకర్‌లో నమోదవుతుంది.';

  @override
  String get cancel => 'రద్దు';

  @override
  String get delete => 'తొలగించు';

  @override
  String get save => 'సేవ్ చేయి';

  @override
  String get confirm => 'నిర్ధారించు';

  @override
  String get loading => 'లోడవుతోంది…';

  @override
  String get error => 'దోషం';

  @override
  String get retry => 'మళ్ళీ ప్రయత్నించు';

  @override
  String get noData => 'డేటా అందుబాటులో లేదు.';

  @override
  String get demoMode => 'డెమో మోడ్';

  @override
  String get demoModeNote =>
      'డేటా మెమరీలో మాత్రమే నిల్వ చేయబడుతుంది మరియు రీస్టార్ట్ అయినప్పుడు రీసెట్ అవుతుంది.';
}
