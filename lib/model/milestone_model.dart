// lib/model/milestone_model.dart
// Data model for roadmap milestones.

import 'survey_model.dart';

enum MilestoneStatus { done, current, locked }

class MilestoneModel {
  final String id;
  final String title;
  final String description;
  final String weekLabel;
  final int xpReward;
  final MilestoneStatus status;
  final String emoji;

  const MilestoneModel({
    required this.id,
    required this.title,
    required this.description,
    required this.weekLabel,
    required this.xpReward,
    required this.status,
    required this.emoji,
  });

  int get earnedXp => status == MilestoneStatus.done ? xpReward : 0;

  /// We keep this here just as a fallback in case the database fails to load.
  static const List<MilestoneModel> defaultMilestones = [
    MilestoneModel(
      id: 'm1',
      title: 'Business Diagnostic Complete',
      description: 'Full MSME profile assessed. Readiness score: 62/100.',
      weekLabel: 'Week 0',
      xpReward: 100,
      status: MilestoneStatus.done,
      emoji: '📋',
    ),
    // ... (Keep the rest of your original defaultMilestones here as a fallback)
  ];
}

class MilestoneGenerator {
  /// Generates a highly personalized 5-step journey based on Survey Data.
  static List<MilestoneModel> generateFromSurvey(SurveyModel survey) {
    final List<MilestoneModel> milestones = [];
    int week = 1;

    // ── 1. BUSINESS & OPERATIONS ────────────────────────────────
    if (survey.salesTracking == SalesTracking.paper) {
      milestones.add(MilestoneModel(
        id: 'm_bus_1',
        title: 'Digitize Operations',
        description: 'Transition from paper records to a digital POS. Essential for tracking daily revenue and reducing manual errors.',
        weekLabel: 'Week ${week++}',
        xpReward: 100,
        status: MilestoneStatus.locked,
        emoji: '📱',
      ));
    } else {
      milestones.add(MilestoneModel(
        id: 'm_bus_1',
        title: 'Cloud Analytics & Optimization',
        description: 'Leverage your ${survey.salesTracking?.label} data to generate automated growth analytics and identify top-selling products in the ${survey.sector} sector.',
        weekLabel: 'Week ${week++}',
        xpReward: 150,
        status: MilestoneStatus.locked,
        emoji: '📊',
      ));
    }

    // ── 2. AUDITING & FINANCIAL ─────────────────────────────────
    if (!survey.hasAuditedStatements) {
      milestones.add(MilestoneModel(
        id: 'm_fin_1',
        title: 'Bookkeeping & Digitization',
        description: 'Upload 3 months of bank statements to build a solid credit profile, acting as a stepping stone towards formal audited statements.',
        weekLabel: 'Week ${week++}',
        xpReward: 120,
        status: MilestoneStatus.locked,
        emoji: '🧾',
      ));
    } else {
      milestones.add(MilestoneModel(
        id: 'm_fin_1',
        title: 'Financial Health Review',
        description: 'Use your audited statements to run an automated financial health check, preparing your corporate profile for upcoming grant applications.',
        weekLabel: 'Week ${week++}',
        xpReward: 150,
        status: MilestoneStatus.locked,
        emoji: '📈',
      ));
    }

    // ── 3. MARKETING (AI Video Generator) ───────────────────────
    // Check where they are active. If empty, default to "your social media"
    final platforms = survey.digitalPresence.where((p) => p != 'None').toList();
    final targetPlatforms = platforms.isNotEmpty ? platforms.join(' & ') : 'your social media';
    
    milestones.add(MilestoneModel(
      id: 'm_mkt_1',
      title: 'AI Video Marketing Campaign',
      description: 'Use our AI Video Generator to automatically craft a tailored promo video for your business, and share it to $targetPlatforms in one click.',
      weekLabel: 'Week ${week++}',
      xpReward: 250,
      status: MilestoneStatus.locked,
      emoji: '🎬',
    ));

    // ── 4. LOANS & GRANTS (Comparison Matrix) ───────────────────
    // Tailor the loan suggestions based on their budget goals
    String loanFocus = survey.budgetPlan == BudgetPlan.zeroDollar 
        ? 'zero-equity grants (e.g., SME Corp MDG, MDEC)' 
        : 'SME financing (e.g., SJPP Guarantees, TEKUN, SME Bank)';

    milestones.add(MilestoneModel(
      id: 'm_loan_1',
      title: 'Personalized Loan & Grant Matrix',
      description: 'Access a custom comparison table of Malaysian financial aids focusing on $loanFocus, tailored precisely to your team size of ${survey.teamSize}.',
      weekLabel: 'Week ${week++}',
      xpReward: 300,
      status: MilestoneStatus.locked,
      emoji: '🏦',
    ));

    // ── 5. EXPORT / ULTIMATE GOAL ───────────────────────────────
    if (survey.primaryGoal == PrimaryGoal.exportAsean) {
      milestones.add(MilestoneModel(
        id: 'm_exp_1',
        title: 'ASEAN Export Readiness Assessment',
        description: 'Take the MATRADE Export Readiness Assessment Tool (ERAT) and prepare documentation for the Market Development Grant (MDG) for cross-border sales.',
        weekLabel: 'Week ${week++}',
        xpReward: 400,
        status: MilestoneStatus.locked,
        emoji: '🌏',
      ));
    } else {
      milestones.add(MilestoneModel(
        id: 'm_gro_1',
        title: 'Scale & Dominate Local Market',
        description: 'Execute your business growth plan using your newly acquired capital and AI-driven marketing to capture market share in Malaysia.',
        weekLabel: 'Week ${week++}',
        xpReward: 350,
        status: MilestoneStatus.locked,
        emoji: '🏆',
      ));
    }

    // ── AUTO-UNLOCK THE FIRST TASK ──────────────────────────────
    // The user must have one active task. This finds the first "locked" task and makes it "current"
    if (milestones.isNotEmpty) {
      milestones[0] = MilestoneModel(
        id: milestones[0].id,
        title: milestones[0].title,
        description: milestones[0].description,
        weekLabel: milestones[0].weekLabel,
        xpReward: milestones[0].xpReward,
        status: MilestoneStatus.current, 
        emoji: milestones[0].emoji,
      );
    }

    return milestones;
  }
}