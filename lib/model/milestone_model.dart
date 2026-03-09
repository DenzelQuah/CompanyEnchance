// lib/model/milestone_model.dart

enum MilestoneStatus { done, current, locked }

class MilestoneResource {
  final String name;
  final String type;         // "Grant" | "Loan" | "Free Service" | "Guarantee" | "Programme"
  final String provider;
  final String eligibility;
  final String maxAmount;
  final String processingTime;
  final String highlight;    // one-line differentiator / why it fits this milestone
  final String url;

  const MilestoneResource({
    required this.name,
    required this.type,
    required this.provider,
    required this.eligibility,
    required this.maxAmount,
    required this.processingTime,
    required this.highlight,
    required this.url,
  });

  factory MilestoneResource.fromMap(Map<String, dynamic> map) {
    return MilestoneResource(
      name:           map['name']            ?? '',
      type:           map['type']            ?? '',
      provider:       map['provider']        ?? map['name'] ?? '',
      eligibility:    map['eligibility']     ?? '',
      maxAmount:      map['maxAmount']       ?? map['max_amount'] ?? 'See website',
      processingTime: map['processingTime']  ?? map['processing_time'] ?? 'See website',
      highlight:      map['highlight']       ?? map['eligibility'] ?? '',
      url:            map['url']             ?? '',
    );
  }
}

class MilestoneModel {
  final String id;
  final String title;
  final String description;
  final String weekLabel;
  final int xpReward;
  final MilestoneStatus status;
  final String emoji;

  final String tool;
  final String toolUrl;
  final String estimatedTime;
  final String source;
  final String sourceInsight;
  final String relevanceReason;
  final List<String> steps;
  final List<String> alternativeSteps; // fallback path if main steps are blocked
  final int currentStep;

  /// micro_tasks[i] = list of sub-actions for steps[i].
  /// Stored in DB as nested JSONB array for RAG embedding.
  /// e.g. [["action 1", "action 2"], ["action 1", "action 2"], ...]
  final List<List<String>> microTasks;

  final List<MilestoneResource> resources;

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
    this.relevanceReason = '',
    this.steps = const [],
    this.alternativeSteps = const [],
    this.currentStep = 0,
    this.microTasks = const [],
    this.resources = const [],
  });

  int get earnedXp => status == MilestoneStatus.done ? xpReward : 0;

  factory MilestoneModel.fromJson(Map<String, dynamic> json, int index) {
    return MilestoneModel(
      id:             json['id']?.toString() ?? 'milestone_$index',
      title:          json['title']          ?? '',
      description:    json['description']    ?? '',
      weekLabel:      json['week_label']     ?? json['weekLabel'] ?? 'Week ${index + 1}',
      emoji:          json['emoji']          ?? '🎯',
      xpReward:       json['xp_reward']      ?? json['xp'] ?? 100,
      status:         _parseStatus(json['status']),
      tool:           json['tool']           ?? '',
      toolUrl:        json['tool_url']       ?? json['toolUrl'] ?? '',
      estimatedTime:  json['estimated_time'] ?? json['estimatedTime'] ?? '',
      source:         json['source']         ?? '',
      sourceInsight:  json['source_insight'] ?? json['sourceInsight'] ?? '',
      relevanceReason: json['relevance_reason'] ?? json['relevanceReason'] ?? '',
      steps:          List<String>.from(json['steps'] ?? []),
      alternativeSteps: List<String>.from(
          json['alternative_steps'] ?? json['alternativeSteps'] ?? []),
      currentStep:    json['current_step']   ?? json['currentStep'] ?? 0,
      microTasks: (json['micro_tasks'] as List<dynamic>? ?? [])
          .map((e) => List<String>.from(e as List<dynamic>? ?? []))
          .toList(),
      resources: (json['resources'] as List<dynamic>? ?? [])
          .map((e) => MilestoneResource.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static MilestoneStatus _parseStatus(String? status) {
    if (status == 'done') return MilestoneStatus.done;
    if (status == 'current') return MilestoneStatus.current;
    return MilestoneStatus.locked;
  }

  MilestoneModel copyWith({
    MilestoneStatus? status,
    int? currentStep,
  }) {
    return MilestoneModel(
      id:              id,
      title:           title,
      description:     description,
      weekLabel:       weekLabel,
      emoji:           emoji,
      xpReward:        xpReward,
      status:          status ?? this.status,
      tool:            tool,
      toolUrl:         toolUrl,
      estimatedTime:   estimatedTime,
      source:          source,
      sourceInsight:   sourceInsight,
      relevanceReason: relevanceReason,
      steps:           steps,
      alternativeSteps: alternativeSteps,
      currentStep:     currentStep ?? this.currentStep,
      microTasks:      microTasks,
      resources:       resources,
    );
  }
}