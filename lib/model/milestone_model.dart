// lib/model/milestone_model.dart
// Data model for roadmap milestones.

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

  /// Static seed data — in production, derive from SurveyModel + backend.
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
    MilestoneModel(
      id: 'm2',
      title: 'Digital Presence Audit',
      description: 'Facebook Business Page, Shopee store & WhatsApp Business all verified.',
      weekLabel: 'Week 1',
      xpReward: 75,
      status: MilestoneStatus.done,
      emoji: '📱',
    ),
    MilestoneModel(
      id: 'm3',
      title: 'Financial Records Digitized',
      description: '3 months of transactions uploaded. Credit profile score: B+.',
      weekLabel: 'Week 2',
      xpReward: 80,
      status: MilestoneStatus.done,
      emoji: '💰',
    ),
    MilestoneModel(
      id: 'm4',
      title: 'Upload Proof of Business Income',
      description:
          'Submit 3 months of bank statements to unlock micro-financing options and strengthen your Credit Profile.',
      weekLabel: 'This Week',
      xpReward: 50,
      status: MilestoneStatus.current,
      emoji: '📤',
    ),
    MilestoneModel(
      id: 'm5',
      title: 'Apply for SME Grant (BPMB)',
      description:
          'Prepare your application using the digitized financial records unlocked in Step 3.',
      weekLabel: 'Week 4',
      xpReward: 120,
      status: MilestoneStatus.locked,
      emoji: '🏦',
    ),
    MilestoneModel(
      id: 'm6',
      title: 'ASEAN Export Readiness Certification',
      description:
          'Complete SSM compliance check, Halal certification review, and MATRADE registration.',
      weekLabel: 'Week 6',
      xpReward: 200,
      status: MilestoneStatus.locked,
      emoji: '🌏',
    ),
    MilestoneModel(
      id: 'm7',
      title: 'First Cross-Border Sale',
      description:
          'List on Lazada SG or Shopee Thailand and fulfil your first ASEAN order.',
      weekLabel: 'Week 8',
      xpReward: 300,
      status: MilestoneStatus.locked,
      emoji: '🚀',
    ),
  ];

  int get earnedXp =>
      status == MilestoneStatus.done ? xpReward : 0;
}
