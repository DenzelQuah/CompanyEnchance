// lib/model/milestone_model.dart

enum MilestoneStatus { done, current, locked }

class MilestoneModel {
  final String id;
  final String title;
  final String description;
  final String weekLabel;
  final int xpReward;
  final MilestoneStatus status;
  final String emoji;

  // ── New fields ──
  final String tool;
  final String toolUrl;
  final String estimatedTime;
  final String source;
  final String sourceInsight;
  final List<String> steps;
  final int currentStep;

  const MilestoneModel({
    required this.id,
    required this.title,
    required this.description,
    required this.weekLabel,
    required this.xpReward,
    required this.status,
    required this.emoji,
    this.tool = '',
    this.toolUrl = '',
    this.estimatedTime = '',
    this.source = '',
    this.sourceInsight = '',
    this.steps = const [],
    this.currentStep = 0,
  });

  int get earnedXp => status == MilestoneStatus.done ? xpReward : 0;

  factory MilestoneModel.fromJson(Map<String, dynamic> json, int index) {
    return MilestoneModel(
      id: 'milestone_$index',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      weekLabel: json['weekLabel'] ?? 'Week ${index + 1}',
      emoji: json['emoji'] ?? '🎯',
      xpReward: json['xp'] ?? 100,
      status: index == 0 ? MilestoneStatus.current : MilestoneStatus.locked,
      tool: json['tool'] ?? '',
      toolUrl: json['toolUrl'] ?? '',
      estimatedTime: json['estimatedTime'] ?? '',
      source: json['source'] ?? '',
      sourceInsight: json['sourceInsight'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      currentStep: 0,
    );
  }

  MilestoneModel copyWith({
    MilestoneStatus? status,
    int? currentStep,
  }) {
    return MilestoneModel(
      id: id,
      title: title,
      description: description,
      weekLabel: weekLabel,
      emoji: emoji,
      xpReward: xpReward,
      status: status ?? this.status,
      tool: tool,
      toolUrl: toolUrl,
      estimatedTime: estimatedTime,
      source: source,
      sourceInsight: sourceInsight,
      steps: steps,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}