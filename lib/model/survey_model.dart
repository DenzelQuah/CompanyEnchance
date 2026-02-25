// lib/model/survey_model.dart
// All data models / enums for the ASEAN Nexus diagnostic survey.

// ─── Enums ────────────────────────────────────────────────────────────────────

enum SalesTracking {
  paper('Paper', '📄', 'Handwritten records & receipts'),
  excel('Excel', '📊', 'Spreadsheets & manual tracking'),
  app('App', '📱', 'POS system or accounting app');

  const SalesTracking(this.label, this.icon, this.subtitle);
  final String label;
  final String icon;
  final String subtitle;
}

enum PrimaryGoal {
  expandLocal('Expand local market share', '📈', 'Grow your customer base in Malaysia'),
  exportAsean('Export to ASEAN', '🌏', 'Access markets in Singapore, Thailand & beyond'),
  getInvestmentReady('Get investment-ready', '💼', 'Prepare for VCs, angels & formal funding'),
  improveOps('Improve operations', '⚙️', 'Streamline processes & reduce costs');

  const PrimaryGoal(this.label, this.icon, this.subtitle);
  final String label;
  final String icon;
  final String subtitle;
}

enum SupplyChain {
  fullyLocal('Fully Local', '🏠', 'All suppliers & customers are domestic'),
  mixed('Mixed', '🔀', 'Some imports or cross-border sales'),
  importHeavy('Import-Heavy', '🚢', 'Significant portion from overseas');

  const SupplyChain(this.label, this.icon, this.subtitle);
  final String label;
  final String icon;
  final String subtitle;
}

enum WeeklyCommitment {
  lessThan5('< 5 hours', '🐢', 'Side hustle / exploring'),
  fiveToTen('5–10 hours', '🚶', 'Part-time commitment'),
  tenToTwenty('10–20 hours', '🏃', 'Serious about growth'),
  moreThan20('20+ hours', '🚀', 'Full-time hustle');

  const WeeklyCommitment(this.label, this.icon, this.subtitle);
  final String label;
  final String icon;
  final String subtitle;
}

enum BudgetPlan {
  zeroDollar('Zero-Dollar Growth', '🆓', 'Bootstrap with free tools & grants only'),
  investmentReady('Investment-Ready', '💎', 'Willing to spend for faster scaling');

  const BudgetPlan(this.label, this.icon, this.subtitle);
  final String label;
  final String icon;
  final String subtitle;
}

// ─── Digital Platform Model ───────────────────────────────────────────────────

class DigitalPlatform {
  final String name;
  final String icon;

  const DigitalPlatform(this.name, this.icon);

  static const List<DigitalPlatform> all = [
    DigitalPlatform('Facebook', '👍'),
    DigitalPlatform('Shopee', '🛒'),
    DigitalPlatform('WhatsApp', '💬'),
    DigitalPlatform('Instagram', '📸'),
    DigitalPlatform('TikTok Shop', '🎵'),
    DigitalPlatform('Own Website', '🌐'),
    DigitalPlatform('None', '❌'),
  ];
}

// ─── Location Model ───────────────────────────────────────────────────────────

class LocationOption {
  final String name;
  final String flag;

  const LocationOption(this.name, this.flag);

  static const List<LocationOption> all = [
    LocationOption('Selangor, Malaysia', '🇲🇾'),
    LocationOption('Kuala Lumpur, Malaysia', '🇲🇾'),
    LocationOption('Penang, Malaysia', '🇲🇾'),
    LocationOption('Johor, Malaysia', '🇲🇾'),
    LocationOption('Sabah, Malaysia', '🇲🇾'),
    LocationOption('Singapore', '🇸🇬'),
    LocationOption('Thailand', '🇹🇭'),
    LocationOption('Indonesia', '🇮🇩'),
    LocationOption('Philippines', '🇵🇭'),
    LocationOption('Vietnam', '🇻🇳'),
  ];
}

// ─── Sector Model ─────────────────────────────────────────────────────────────

const List<String> kSectors = [
  'Food & Beverage',
  'Retail & E-commerce',
  'Manufacturing',
  'Agriculture',
  'Technology',
  'Services',
  'Handicraft & Creative',
  'Health & Beauty',
];

// ─── Survey State ─────────────────────────────────────────────────────────────

class SurveyModel {
  // Q1
  final String businessName;
  final String sector;
  // Q2
  final String location;
  // Q3
  final SalesTracking? salesTracking;
  // Q4
  final int teamSize;
  // Q5
  final PrimaryGoal? primaryGoal;
  // Q6
  final bool hasAuditedStatements;
  // Q7
  final List<String> digitalPresence;
  // Q8
  final SupplyChain? supplyChain;
  // Q9
  final WeeklyCommitment? weeklyCommitment;
  // Q10
  final BudgetPlan? budgetPlan;
  // Navigation
  final int currentStep;
  final bool isComplete;

  const SurveyModel({
    this.businessName = '',
    this.sector = '',
    this.location = '',
    this.salesTracking,
    this.teamSize = 5,
    this.primaryGoal,
    this.hasAuditedStatements = false,
    this.digitalPresence = const [],
    this.supplyChain,
    this.weeklyCommitment,
    this.budgetPlan,
    this.currentStep = 0,
    this.isComplete = false,
  });

  static const int totalSteps = 10;

  double get progress => (currentStep + 1) / totalSteps;

  /// Show AI Export insight bubble on Q5
  bool get showExportInsight => primaryGoal == PrimaryGoal.exportAsean;

  SurveyModel copyWith({
    String? businessName,
    String? sector,
    String? location,
    SalesTracking? salesTracking,
    int? teamSize,
    PrimaryGoal? primaryGoal,
    bool? hasAuditedStatements,
    List<String>? digitalPresence,
    SupplyChain? supplyChain,
    WeeklyCommitment? weeklyCommitment,
    BudgetPlan? budgetPlan,
    int? currentStep,
    bool? isComplete,
  }) {
    return SurveyModel(
      businessName: businessName ?? this.businessName,
      sector: sector ?? this.sector,
      location: location ?? this.location,
      salesTracking: salesTracking ?? this.salesTracking,
      teamSize: teamSize ?? this.teamSize,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      hasAuditedStatements: hasAuditedStatements ?? this.hasAuditedStatements,
      digitalPresence: digitalPresence ?? this.digitalPresence,
      supplyChain: supplyChain ?? this.supplyChain,
      weeklyCommitment: weeklyCommitment ?? this.weeklyCommitment,
      budgetPlan: budgetPlan ?? this.budgetPlan,
      currentStep: currentStep ?? this.currentStep,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  String toString() => 'SurveyModel(step: $currentStep, goal: $primaryGoal, '
      'digital: $digitalPresence, complete: $isComplete)';
}
