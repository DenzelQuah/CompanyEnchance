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
              if (m['status'] == 'current') statusEnum = MilestoneStatus.current;

              List<String> loadedSteps = [];
              if (m['steps'] != null) {
                loadedSteps = List<String>.from(m['steps']);
              }

              return MilestoneModel(
                id: m['id'],
                title: m['title'],
                description: m['description'],
                weekLabel: m['week_label'],
                xpReward: m['xp_reward'],
                status: statusEnum,
                emoji: m['emoji'],
                // Detailed fields
                tool: m['tool'] ?? '',
                toolUrl: m['tool_url'] ?? '',
                estimatedTime: m['estimated_time'] ?? '',
                source: m['source'] ?? '',
                sourceInsight: m['source_insight'] ?? '',
                steps: loadedSteps,
              );
            }).toList();
            

            // 🔥 SELF-HEALING FIX:
            // If the loaded data has NO steps (old data), delete it and regenerate!
            if (savedList.isNotEmpty && savedList.first.steps.isEmpty) {
              
              print('⚠ Found legacy roadmap (empty steps). Deleting and regenerating...');
              
              // 1. Set loading state
              state = state.copyWith(isLoading: true);
              
              // 2. Delete old rows
              await supabase.from('user_milestones').delete().eq('user_id', savedId);
              
              // 3. Generate fresh new data
              await _fetchAndSaveAiMilestones(survey);
              return; // Stop here, _fetchAndSaveAiMilestones will update state
            }

            // Otherwise, load normally
            print('📂 Loaded Valid Roadmap from Database');
            state = state.copyWith(milestones: savedList, isLoading: false);

            if (state.detailedStrategy == null) _generateAiStrategy(survey);
            return;
          }

          // 3. NO DATA FOUND? Generate fresh AI Roadmap
          print('✨ No saved roadmap found. Generating new AI one...');
          await _fetchAndSaveAiMilestones(survey);
          _generateAiStrategy(survey);
          return;
        }
      } catch (e) {
        print('Error loading roadmap: $e');
        state = state.copyWith(isLoading: false);
      }
    } else {
        state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _fetchAndSaveAiMilestones(SurveyModel survey) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return;

      final prompt = RoadmapPromptBuilder.buildJsonSystemPrompt(survey);
      
      final model = GenerativeModel(
        model: 'models/gemini-2.5-flash', 
        apiKey: apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      
      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text;

      if (rawText == null || rawText.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final startIndex = rawText.indexOf('[');
      final endIndex = rawText.lastIndexOf(']');

      if (startIndex == -1 || endIndex == -1) {
        print('❌ No JSON array found.');
        state = state.copyWith(isLoading: false);
        return;
      }

      String cleanJson = rawText.substring(startIndex, endIndex + 1);
      cleanJson = _sanitizeJson(cleanJson);

      List<dynamic> jsonList;
      try {
        jsonList = jsonDecode(cleanJson);
      } catch (e) {
        print('❌ JSON decode failed: $e');
        state = state.copyWith(isLoading: false);
        return;
      }

      final List<Map<String, dynamic>> dbRecords = [];
      final List<MilestoneModel> tempUI = [];

      for (int index = 0; index < jsonList.length; index++) {
        final item = jsonList[index] as Map<String, dynamic>;
        
        // Parse Steps safely
        List<String> parsedSteps = [];
        if (item['steps'] != null) {
          parsedSteps = List<String>.from((item['steps'] as List).map((s) => s.toString()));
        }

        // If AI returns no steps, provide a default so we don't trigger the delete loop
        if (parsedSteps.isEmpty) {
          parsedSteps = ['Review this milestone details', 'Prepare necessary documents'];
        }

        final milestone = MilestoneModel(
          id: 'temp_$index',
          title: _safeString(item['title'], 'Milestone ${index + 1}'),
          description: _safeString(item['description'], ''),
          weekLabel: _safeString(item['weekLabel'], 'Week ${index + 1}'),
          xpReward: item['xp'] is int ? item['xp'] : 100,
          status: index == 0 ? MilestoneStatus.current : MilestoneStatus.locked,
          emoji: _safeString(item['emoji'], '🎯'),
          tool: _safeString(item['tool'], ''),
          toolUrl: _safeString(item['toolUrl'], ''),
          estimatedTime: _safeString(item['estimatedTime'], ''),
          source: _safeString(item['source'], ''),
          sourceInsight: _safeString(item['sourceInsight'], ''),
          steps: parsedSteps,
        );

        tempUI.add(milestone);

        dbRecords.add({
          'user_id': survey.uniqueId,
          'title': milestone.title,
          'description': milestone.description,
          'week_label': milestone.weekLabel,
          'xp_reward': milestone.xpReward,
          'status': index == 0 ? 'current' : 'locked',
          'emoji': milestone.emoji,
          'tool': milestone.tool,
          'tool_url': milestone.toolUrl,
          'estimated_time': milestone.estimatedTime,
          'source': milestone.source,
          'source_insight': milestone.sourceInsight,
          'steps': milestone.steps, 
        });
      }

      if (dbRecords.isNotEmpty) {
        await Supabase.instance.client
            .from('user_milestones')
            .insert(dbRecords);
        print('✅ Saved ${dbRecords.length} milestones to Supabase');
        
        // Reload to get real IDs
        _loadUserRoadmap();
      }

    } catch (e) {
      print('AI Fetch Failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  String _safeString(dynamic value, String fallback) {
    if (value == null) return fallback;
    return value.toString().trim();
  }
  String _sanitizeJson(String json) {
    // Remove control characters that break JSON parsing
    // (tab, newline, carriage return inside string values)
    final buffer = StringBuffer();
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < json.length; i++) {
      final char = json[i];
      final code = char.codeUnitAt(0);

      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        buffer.write(char);
        continue;
      }

      if (char == '"') {
        inString = !inString;
        buffer.write(char);
        continue;
      }

      // Inside a string: replace bare newlines/tabs with a space
      if (inString && (code == 10 || code == 13 || code == 9)) {
        buffer.write(' ');
        continue;
      }

      buffer.write(char);
    }

    return buffer.toString();
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
    // 1. Mark target as done
    final updated = state.milestones.map((m) {
      if (m.id == milestoneId && m.status == MilestoneStatus.current) {
        return m.copyWith(status: MilestoneStatus.done);
      }
      return m;
    }).toList();

    // 2. Find next locked and unlock it
    bool foundLocked = false;
    final finalMilestones = updated.map((m) {
      // If we already found the one to unlock, return others as is
      if (foundLocked) return m;

      // Unlock the FIRST locked item found after the update
      if (m.status == MilestoneStatus.locked) {
        foundLocked = true;
        // Update DB for the new current item
        _updateMilestoneStatusInDb(m.id, 'current'); 
        return m.copyWith(status: MilestoneStatus.current);
      }
      return m;
    }).toList();

    // 3. Update DB for the completed item
    _updateMilestoneStatusInDb(milestoneId, 'done');

    // 4. Calculate XP
    final earned = state.milestones
        .firstWhere((m) => m.id == milestoneId, orElse: () => state.milestones.first)
        .xpReward;

    // 5. Update UI
    state = state.copyWith(
      milestones: finalMilestones,
      totalXp: state.totalXp + earned,
    );
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
  Future<void> updateMilestoneProgress(String milestoneId, int newCurrentStep) async {
    // 1. Optimistic Update: Update UI instantly
    state = state.copyWith(
      milestones: state.milestones.map((m) {
        if (m.id == milestoneId) {
          return m.copyWith(currentStep: newCurrentStep);
        }
        return m;
      }).toList(),
    );

    // 2. Persist to Database
    // Only update if it's a real ID (not a temp one)
    if (!milestoneId.startsWith('temp_')) {
      try {
        await Supabase.instance.client
            .from('user_milestones') //
            .update({'current_step': newCurrentStep}) // Matches snake_case column
            .eq('id', milestoneId);
      } catch (e) {
        print('Error saving step progress: $e');
      }
    }
  }

}

final roadmapControllerProvider =
    StateNotifierProvider<RoadmapController, RoadmapState>(
      (_) => RoadmapController(),
    );
