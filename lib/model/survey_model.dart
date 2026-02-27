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

  final bool isSubmitting;
  final String errorMessage;
  

  // Navigation
  final int currentStep;
  final bool isComplete;
  final String uniqueId;
  

  const SurveyModel({
    this.uniqueId = '',
    this.errorMessage = '',
    this.businessName = '',
    this.isSubmitting = false,
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
    String? uniqueId,
    String? errorMessage,
    bool? isSubmitting,
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
      uniqueId: uniqueId ?? this.uniqueId,
      errorMessage: errorMessage ?? this.errorMessage,
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
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
  Map<String, dynamic> toMap(int score) {
    return {
      'id': uniqueId,
      'business_name': businessName,
      'sector': sector,
      'location': location,
      // .name extracts the string value of the enum (e.g., 'app', 'excel')
      'sales_tracking': salesTracking?.name,
      'team_size': teamSize,
      'primary_goal': primaryGoal?.name,
      'has_audited_statements': hasAuditedStatements,
      'digital_presence': digitalPresence, 
      'supply_chain': supplyChain?.name,
      'weekly_commitment': weeklyCommitment?.name,
      'budget_plan': budgetPlan?.name,
      'readiness_score': score,
    };
  }
  
  // Create a SurveyModel from a Firestore document map:
  //Reason: to handle cases where fields did not answers will able to detect back the latest results answered by user and show the result page without having to retake the survey again
  factory SurveyModel.fromMap(Map<String, dynamic> map, String id) {
    return SurveyModel(
      uniqueId: id,
      businessName: map['business_name'] ?? '',
      sector: map['sector'] ?? '',
      location: map['location'] ?? '',
      salesTracking: SalesTracking.values.asNameMap()[map['sales_tracking'] ?? ''],
      teamSize: map['team_size'] ?? 5,
      primaryGoal: PrimaryGoal.values.asNameMap()[map['primary_goal'] ?? ''],
      hasAuditedStatements: map['has_audited_statements'] ?? false,
      digitalPresence: List<String>.from(map['digital_presence'] ?? []),
      supplyChain: SupplyChain.values.asNameMap()[map['supply_chain'] ?? ''],
      weeklyCommitment: WeeklyCommitment.values.asNameMap()[map['weekly_commitment'] ?? ''],
      budgetPlan: BudgetPlan.values.asNameMap()[map['budget_plan'] ?? ''],
      currentStep: map['current_step'] ?? 0,
    );
  }

  


  @override
  String toString() => 'SurveyModel(step: $currentStep, goal: $primaryGoal, '
      'digital: $digitalPresence, complete: $isComplete)';
}
