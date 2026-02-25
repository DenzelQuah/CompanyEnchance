// lib/controller/roadmap_controller.dart
// Manages roadmap milestone state and XP tracking.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/milestone_model.dart';

class RoadmapState {
  final List<MilestoneModel> milestones;
  final int totalXp;
  final int level;
  final String levelLabel;

  const RoadmapState({
    required this.milestones,
    required this.totalXp,
    required this.level,
    required this.levelLabel,
  });

  double get xpProgress => (totalXp % 1000) / 1000;
  int get xpToNextLevel => 1000 - (totalXp % 1000);
  int get milestonesComplete =>
      milestones.where((m) => m.status == MilestoneStatus.done).length;

  static const RoadmapState initial = RoadmapState(
    milestones: MilestoneModel.defaultMilestones,
    totalXp: 350,
    level: 2,
    levelLabel: 'Emerging Business',
  );

  RoadmapState copyWith({
    List<MilestoneModel>? milestones,
    int? totalXp,
    int? level,
    String? levelLabel,
  }) {
    return RoadmapState(
      milestones: milestones ?? this.milestones,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      levelLabel: levelLabel ?? this.levelLabel,
    );
  }
}

class RoadmapController extends StateNotifier<RoadmapState> {
  RoadmapController() : super(RoadmapState.initial);

  /// Mark a milestone as complete and award XP.
  void completeMilestone(String milestoneId) {
    final updated = state.milestones.map((m) {
      if (m.id == milestoneId && m.status == MilestoneStatus.current) {
        return MilestoneModel(
          id: m.id,
          title: m.title,
          description: m.description,
          weekLabel: m.weekLabel,
          xpReward: m.xpReward,
          status: MilestoneStatus.done,
          emoji: m.emoji,
        );
      }
      return m;
    }).toList();

    final earned = state.milestones
        .firstWhere((m) => m.id == milestoneId,
            orElse: () => state.milestones.first)
        .xpReward;

    // Unlock next locked milestone → set to current
    final withUnlocked = _unlockNext(updated);

    state = state.copyWith(
      milestones: withUnlocked,
      totalXp: state.totalXp + earned,
    );
  }

  List<MilestoneModel> _unlockNext(List<MilestoneModel> list) {
    bool foundLocked = false;
    return list.map((m) {
      if (!foundLocked && m.status == MilestoneStatus.locked) {
        foundLocked = true;
        return MilestoneModel(
          id: m.id,
          title: m.title,
          description: m.description,
          weekLabel: m.weekLabel,
          xpReward: m.xpReward,
          status: MilestoneStatus.current,
          emoji: m.emoji,
        );
      }
      return m;
    }).toList();
  }
}

final roadmapControllerProvider =
    StateNotifierProvider<RoadmapController, RoadmapState>(
  (_) => RoadmapController(),
);
