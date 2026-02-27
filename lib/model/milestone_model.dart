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

  int get earnedXp => status == MilestoneStatus.done ? xpReward : 0;
}

