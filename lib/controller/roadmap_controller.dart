// lib/controller/roadmap_controller.dart
// Manages roadmap milestone state and XP tracking.
import 'dart:convert';

import 'package:companyenchancer/model/survey_model.dart';
import 'package:companyenchancer/services/roadmap_prompt.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../model/milestone_model.dart';

class RoadmapState {
  final List<MilestoneModel> milestones;
  final int totalXp;
  final int level;
  final String levelLabel;
  final bool isLoading;
  final String? detailedStrategy;

  const RoadmapState({
    this.detailedStrategy,
    required this.milestones,
    required this.totalXp,
    required this.level,
    this.isLoading = false,
    required this.levelLabel,
  });

  double get xpProgress => (totalXp % 1000) / 1000;
  int get xpToNextLevel => 1000 - (totalXp % 1000);
  int get milestonesComplete =>
      milestones.where((m) => m.status == MilestoneStatus.done).length;

  static const RoadmapState initial = RoadmapState(
    milestones: [],
    totalXp: 350,
    level: 2,
    levelLabel: 'Emerging Business',
    isLoading: true,
  );

  RoadmapState copyWith({
    List<MilestoneModel>? milestones,
    int? totalXp,
    int? level,
    String? levelLabel,
    bool? isLoading,
    String? detailedStrategy,
  }) {
    return RoadmapState(
      milestones: milestones ?? this.milestones,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      levelLabel: levelLabel ?? this.levelLabel,
      isLoading: isLoading ?? this.isLoading,
      detailedStrategy: detailedStrategy ?? this.detailedStrategy,
    );
  }
}

class RoadmapController extends StateNotifier<RoadmapState> {
  RoadmapController() : super(RoadmapState.initial) {
    _loadUserRoadmap();
  }
  Future<void> _loadUserRoadmap() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    final savedId = user?.id ?? prefs.getString('survey_session_id');

    if (savedId != null) {
      try {
        final supabase = Supabase.instance.client;

        // 1. Get Survey Data
        final surveyData = await supabase
            .from('survey_responses')
            .select()
            .eq('id', savedId)
            .maybeSingle();

        if (surveyData != null) {
          final survey = SurveyModel.fromMap(surveyData, savedId);

          // 2. CHECK: Do we already have saved milestones?
          final dbMilestones = await supabase
              .from('user_milestones')
              .select()
              .eq('user_id', savedId)
              .order('created_at', ascending: true);

          if (dbMilestones.isNotEmpty) {
            // ✅ FOUND SAVED DATA! Load it directly.
            print('📂 Loaded Existing Roadmap from Database');
            final savedList = (dbMilestones as List).map((m) {
              MilestoneStatus statusEnum = MilestoneStatus.locked;
              if (m['status'] == 'done') statusEnum = MilestoneStatus.done;
              if (m['status'] == 'current')
                statusEnum = MilestoneStatus.current;

              return MilestoneModel(
                id: m['id'],
                title: m['title'],
                description: m['description'],
                weekLabel: m['week_label'],
                xpReward: m['xp_reward'],
                status: statusEnum,
                emoji: m['emoji'],
              );
            }).toList();

            state = state.copyWith(milestones: savedList, isLoading: false);
            print('📂 Loaded Existing Roadmap from Database');

            // Still generate strategy text if missing
            if (state.detailedStrategy == null) _generateAiStrategy(survey);

            return;
          }

          // 3. NO DATA FOUND? Generate fresh AI Roadmap
          print('✨ No saved roadmap found. Generating new AI one...');
          await _fetchAndSaveAiMilestones(survey);
          _generateAiStrategy(survey);
          return;

          // Generate & Save
        }
      } catch (e) {
        print('Error loading roadmap: $e');
      }
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> _fetchAndSaveAiMilestones(SurveyModel survey) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return;

      // 1. Call AI
      final prompt = RoadmapPromptBuilder.buildJsonSystemPrompt(survey);
      final model = GenerativeModel(model: 'models/gemini-2.5-flash', apiKey: apiKey);
      final response = await model.generateContent([Content.text(prompt)]);

      final cleanJson = response.text
          ?.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      if (cleanJson != null) {
        final List<dynamic> jsonList = jsonDecode(cleanJson);
        final List<MilestoneModel> aiMilestones = [];
        final List<Map<String, dynamic>> dbRecords = [];

        int index = 0;
        for (var item in jsonList) {
          final isFirst = index == 0;

          // Create UI Object
          final milestone = MilestoneModel(
            id: 'temp_$index', // DB will replace this ID
            title: item['title'] ?? 'New Milestone',
            description: item['description'] ?? '',
            weekLabel: item['weekLabel'] ?? 'Week $index',
            xpReward: item['xp'] ?? 100,
            status: isFirst ? MilestoneStatus.current : MilestoneStatus.locked,
            emoji: item['emoji'] ?? '🚀',
          );
          aiMilestones.add(milestone);

          // Create DB Record
          dbRecords.add({
            'user_id': survey.uniqueId,
            'title': milestone.title,
            'description': milestone.description,
            'week_label': milestone.weekLabel,
            'xp_reward': milestone.xpReward,
            'status': isFirst ? 'current' : 'locked',
            'emoji': milestone.emoji,
          });
          index++;
        }

        // 2. Save to Supabase
        if (dbRecords.isNotEmpty) {
          await Supabase.instance.client
              .from('user_milestones')
              .insert(dbRecords);
          print('✅ AI Roadmap Saved to Supabase!');

          // Reload to get real UUIDs from DB (Optional, but cleaner)
          // For now, just showing the UI state is faster:
          state = state.copyWith(milestones: aiMilestones, isLoading: false);
        }
      }
    } catch (e) {
      print('AI Fetch Failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 2. Generate AI Strategy (Private helper)
  Future<void> _generateAiStrategy(SurveyModel survey) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return;

      final prompt = RoadmapPromptBuilder.buildSystemPrompt(survey);
      final model = GenerativeModel(
        model: 'models/gemini-2.5-flash',
        apiKey: apiKey,
      );
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        state = state.copyWith(detailedStrategy: response.text);
      }
    } catch (e) {
      print('AI Generation failed: $e');
    }
  }

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

    // Unlock next locked milestone → set to current
    final withUnlocked = _unlockNext(updated);
    _updateMilestoneStatusInDb(milestoneId, 'done');
    // Find the new current one to update DB
    final newCurrent = withUnlocked.firstWhere(
      (m) => m.status == MilestoneStatus.current,
      orElse: () => withUnlocked.last,
    );
    if (newCurrent.status == MilestoneStatus.current) {
      _updateMilestoneStatusInDb(newCurrent.id, 'current');
    }
    final earned = state.milestones
        .firstWhere((m) => m.id == milestoneId)
        .xpReward;
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
          emoji: m.emoji,
          status: MilestoneStatus.current,
        );
      }
      return m;
    }).toList();
  }

  Future<void> _updateMilestoneStatusInDb(String id, String status) async {
    // Only update if it's a real UUID (not a temp ID)
    if (!id.startsWith('temp_')) {
      await Supabase.instance.client
          .from('user_milestones')
          .update({'status': status})
          .eq('id', id);
    }
  }
}

final roadmapControllerProvider =
    StateNotifierProvider<RoadmapController, RoadmapState>(
      (_) => RoadmapController(),
    );
