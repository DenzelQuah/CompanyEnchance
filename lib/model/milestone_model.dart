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

    milestones.add(
      MilestoneModel(
        id: 'm1',
        title: 'Business Diagnostic Complete',
        description: 'Profile assessed for ${survey.businessName}. Score: 62/100.',
        weekLabel: 'Week 0',
        xpReward: 100,
        status: MilestoneStatus.done,
        emoji: '📋',
      ),
    );

    // 2. OPERATIONS: Tailored to Sales Tracking
    if (survey.salesTracking == SalesTracking.paper) {
      milestones.add(MilestoneModel(
        id: 'm_ops',
        title: 'Digitize Sales Records',
        description: 'Move from paper to a digital POS. Essential for loan approvals.',
        weekLabel: 'Week ${week++}',
        xpReward: 150,
        status: MilestoneStatus.current, // Start here!
        emoji: '📱',
      ));
    } else {
      milestones.add(MilestoneModel(
        id: 'm_ops',
        title: 'Optimize Data Analytics',
        description: 'Use your ${survey.salesTracking?.label} data to find top-selling items.',
        weekLabel: 'Week ${week++}',
        xpReward: 100,
        status: MilestoneStatus.current,
        emoji: '📊',
      ));
    }

    // 3. FINANCE: Tailored to Audited Statements
    if (!survey.hasAuditedStatements) {
      milestones.add(MilestoneModel(
        id: 'm_fin',
        title: 'Prepare Management Accounts',
        description: 'Upload 3 months of bank statements to build credit history.',
        weekLabel: 'Week ${week++}',
        xpReward: 120,
        status: MilestoneStatus.locked,
        emoji: '💰',
      ));
    } else {
      milestones.add(MilestoneModel(
        id: 'm_fin',
        title: 'Apply for SME Grant',
        description: 'Use your audited statements to apply for the Digital Grant.',
        weekLabel: 'Week ${week++}',
        xpReward: 200,
        status: MilestoneStatus.locked,
        emoji: '🏦',
      ));
    }

    // 4. GOAL: Tailored to Primary Goal
    if (survey.primaryGoal == PrimaryGoal.exportAsean) {
      milestones.add(MilestoneModel(
        id: 'm_goal',
        title: 'MATRADE Export Registration',
        description: 'Register for the Market Development Grant (MDG).',
        weekLabel: 'Week ${week++}',
        xpReward: 300,
        status: MilestoneStatus.locked,
        emoji: '🌏',
      ));
    } else {
      milestones.add(MilestoneModel(
        id: 'm_goal',
        title: 'Expand Local Market',
        description: 'Launch a marketing campaign to increase local footfall.',
        weekLabel: 'Week ${week++}',
        xpReward: 250,
        status: MilestoneStatus.locked,
        emoji: '🚀',
      ));
    }

    return milestones;
  }
}