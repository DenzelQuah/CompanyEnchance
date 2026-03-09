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

  // ─────────────────────────────────────────────────────────────────────────
  // Load
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadUserRoadmap() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    final savedId = user?.id ?? prefs.getString('survey_session_id');

    if (savedId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // 1. Load survey
      final surveyData = await supabase
          .from('survey_responses')
          .select()
          .eq('id', savedId)
          .maybeSingle();

      if (surveyData == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final survey = SurveyModel.fromMap(surveyData, savedId);

      // 2. Check for saved milestones
      final dbMilestones = await supabase
          .from('user_milestones')
          .select()
          .eq('user_id', savedId)
          .order('created_at', ascending: true);

      if ((dbMilestones as List).isEmpty) {
        // No data — generate fresh
        print('✨ No saved roadmap. Generating AI roadmap...');
        await _fetchAndSaveAiMilestones(survey);
        _generateAiStrategy(survey); // fire-and-forget
        return;
      }

      // 3. Map DB rows to MilestoneModel with complete field mapping
      final savedList = dbMilestones.map<MilestoneModel>((m) {
        MilestoneStatus statusEnum = MilestoneStatus.locked;
        if (m['status'] == 'done') statusEnum = MilestoneStatus.done;
        if (m['status'] == 'current') statusEnum = MilestoneStatus.current;

        List<String> loadedSteps = [];
        if (m['steps'] != null) {
          loadedSteps = List<String>.from(m['steps'] as List);
        }

        List<String> altSteps = [];
        if (m['alternative_steps'] != null) {
          altSteps = List<String>.from(m['alternative_steps'] as List);
        }

        // micro_tasks: nested array — micro_tasks[i] = sub-actions for steps[i]
        List<List<String>> microTasks = [];
        if (m['micro_tasks'] != null) {
          microTasks = (m['micro_tasks'] as List)
              .map((e) => List<String>.from(e as List? ?? []))
              .toList();
        }

        List<MilestoneResource> resources = [];
        if (m['resources'] != null) {
          resources = (m['resources'] as List)
              .whereType<Map<String, dynamic>>()
              .map((r) => MilestoneResource.fromMap(r))
              .toList();
        }

        return MilestoneModel(
          id: m['id']?.toString() ?? '',
          title: m['title'] ?? '',
          description: m['description'] ?? '',
          weekLabel: m['week_label'] ?? '',        // snake_case DB column
          xpReward: m['xp_reward'] ?? 100,
          status: statusEnum,
          emoji: m['emoji'] ?? '🎯',
          tool: m['tool'] ?? '',
          toolUrl: m['tool_url'] ?? '',
          estimatedTime: m['estimated_time'] ?? '',
          source: m['source'] ?? '',
          sourceInsight: m['source_insight'] ?? '',
          relevanceReason: m['relevance_reason'] ?? '',
          steps: loadedSteps,
          alternativeSteps: altSteps,
          currentStep: m['current_step'] ?? 0,
          microTasks: microTasks,
          resources: resources,
        );
      }).toList();

      // 4. Self-heal: legacy rows have no steps — delete and regenerate once
      if (savedList.isNotEmpty && savedList.first.steps.isEmpty) {
        print('⚠ Legacy roadmap (empty steps). Deleting and regenerating...');
        state = state.copyWith(isLoading: true);
        await supabase
            .from('user_milestones')
            .delete()
            .eq('user_id', savedId);
        await _fetchAndSaveAiMilestones(survey);
        return;
      }

      print('📂 Loaded valid roadmap (${savedList.length} milestones)');
      state = state.copyWith(milestones: savedList, isLoading: false);

      // Backfill micro_tasks for existing rows that were saved before this
      // feature was added. Runs silently in background — UI is already showing.
      final needsBackfill = savedList.any((m) => m.microTasks.isEmpty && m.steps.isNotEmpty);
      if (needsBackfill) _backfillMicroTasks(savedList);

      if (state.detailedStrategy == null) _generateAiStrategy(survey);
    } catch (e) {
      print('❌ Error loading roadmap: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Backfill micro_tasks for existing DB rows (one-time, fire-and-forget)
  // Triggered on load when any milestone has steps but empty micro_tasks.
  // Safe to run multiple times — skips rows that already have micro_tasks.
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _backfillMicroTasks(List<MilestoneModel> milestones) async {
    try {
      final supabase = Supabase.instance.client;
      int patched = 0;

      for (final m in milestones) {
        // Skip rows that already have micro_tasks or have no steps to work from
        if (m.microTasks.isNotEmpty || m.steps.isEmpty || m.id.startsWith('temp_')) continue;

        final microTasks = m.steps.map((s) => _buildMicroTasksForStep(s)).toList();

        await supabase
            .from('user_milestones')
            .update({'micro_tasks': microTasks})
            .eq('id', m.id);

        patched++;
      }

      if (patched > 0) {
        print('✅ Backfilled micro_tasks for $patched milestone(s)');
        // Update in-memory state so the model is consistent without a reload
        final updated = state.milestones.map((m) {
          if (m.microTasks.isNotEmpty || m.steps.isEmpty) return m;
          return MilestoneModel(
            id: m.id, title: m.title, description: m.description,
            weekLabel: m.weekLabel, xpReward: m.xpReward, status: m.status,
            emoji: m.emoji, tool: m.tool, toolUrl: m.toolUrl,
            estimatedTime: m.estimatedTime, source: m.source,
            sourceInsight: m.sourceInsight, relevanceReason: m.relevanceReason,
            steps: m.steps, alternativeSteps: m.alternativeSteps,
            currentStep: m.currentStep,
            microTasks: m.steps.map((s) => _buildMicroTasksForStep(s)).toList(),
            resources: m.resources,
          );
        }).toList();
        state = state.copyWith(milestones: updated);
      }
    } catch (e) {
      // Non-fatal — backfill will retry on next app load
      print('⚠ micro_tasks backfill failed (will retry next load): $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI generation + DB save
  // BUG FIX: No longer calls _loadUserRoadmap() — avoids infinite loop and
  // the "blank screen stays forever" bug. Instead we:
  //   1. Set UI state immediately after parsing (isLoading: false)
  //   2. Insert to DB and silently patch temp IDs with real UUIDs
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _fetchAndSaveAiMilestones(SurveyModel survey) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final prompt = RoadmapPromptBuilder.buildJsonSystemPrompt(survey);

      final model = GenerativeModel(
        model: 'models/gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text;

      if (rawText == null || rawText.isEmpty) {
        print('❌ Empty AI response');
        state = state.copyWith(isLoading: false);
        return;
      }

      final startIndex = rawText.indexOf('[');
      final endIndex = rawText.lastIndexOf(']');
      if (startIndex == -1 || endIndex == -1) {
        print('❌ No JSON array in AI response');
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
      final List<MilestoneModel> uiMilestones = [];

      for (int i = 0; i < jsonList.length; i++) {
        final item = jsonList[i] as Map<String, dynamic>;

        // Steps
        List<String> steps = [];
        if (item['steps'] is List) {
          steps = List<String>.from(
              (item['steps'] as List).map((s) => s.toString()));
        }
        if (steps.isEmpty) {
          steps = [
            'Review this milestone carefully',
            'Prepare all necessary documents',
            'Execute the action described above',
            'Verify completion before marking done',
          ];
        }

        // Alternative steps
        List<String> altSteps = [];
        if (item['alternativeSteps'] is List) {
          altSteps = List<String>.from(
              (item['alternativeSteps'] as List).map((s) => s.toString()));
        }

        // Micro-tasks — generated from each step text, stored for RAG embedding
        // microTasks[i] = sub-action checklist for steps[i]
        final List<List<String>> microTasks =
            steps.map((s) => _buildMicroTasksForStep(s)).toList();

        // Resources
        List<Map<String, dynamic>> resources = [];
        if (item['resources'] is List) {
          resources = (item['resources'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        }

        final title = _s(item['title'], 'Milestone ${i + 1}');
        final description = _s(item['description'], '');
        final weekLabel =
            _s(item['week_label'] ?? item['weekLabel'], 'Week ${i + 1}');
        final xpReward = item['xp'] is int ? item['xp'] as int : 100;
        final emoji = _s(item['emoji'], '🎯');
        final tool = _s(item['tool'], '');
        final toolUrl = _s(item['tool_url'] ?? item['toolUrl'], '');
        final estTime =
            _s(item['estimated_time'] ?? item['estimatedTime'], '');
        final source = _s(item['source'], '');
        final sourceInsight =
            _s(item['source_insight'] ?? item['sourceInsight'], '');
        final relevanceReason =
            _s(item['relevance_reason'] ?? item['relevanceReason'], '');
        final status = i == 0 ? 'current' : 'locked';
        final statusEnum =
            i == 0 ? MilestoneStatus.current : MilestoneStatus.locked;

        uiMilestones.add(MilestoneModel(
          id: 'temp_$i',
          title: title,
          description: description,
          weekLabel: weekLabel,
          xpReward: xpReward,
          status: statusEnum,
          emoji: emoji,
          tool: tool,
          toolUrl: toolUrl,
          estimatedTime: estTime,
          source: source,
          sourceInsight: sourceInsight,
          relevanceReason: relevanceReason,
          steps: steps,
          alternativeSteps: altSteps,
          microTasks: microTasks,
          resources:
              resources.map((r) => MilestoneResource.fromMap(r)).toList(),
        ));

        dbRecords.add({
          'user_id': survey.uniqueId,
          'title': title,
          'description': description,
          'week_label': weekLabel,
          'xp_reward': xpReward,
          'status': status,
          'emoji': emoji,
          'tool': tool,
          'tool_url': toolUrl,
          'estimated_time': estTime,
          'source': source,
          'source_insight': sourceInsight,
          'relevance_reason': relevanceReason,
          'steps': steps,
          'alternative_steps': altSteps,
          'micro_tasks': microTasks,
          'resources': resources,
        });
      }

      // ── Show milestones immediately — user sees content right away ─────────
      state = state.copyWith(milestones: uiMilestones, isLoading: false);
      print('✅ Showing ${uiMilestones.length} milestones in UI');

      if (dbRecords.isEmpty) return;

      // ── Persist to DB then silently swap temp IDs for real UUIDs ──────────
      try {
        final inserted = await Supabase.instance.client
            .from('user_milestones')
            .insert(dbRecords)
            .select('id');
        print('✅ Saved ${dbRecords.length} milestones to Supabase');

        if (inserted.length == uiMilestones.length) {
          final patched =
              List<MilestoneModel>.generate(uiMilestones.length, (idx) {
            final realId =
                (inserted[idx])['id'] as String?;
            final m = uiMilestones[idx];
            if (realId == null) return m;
            return MilestoneModel(
              id: realId,
              title: m.title,
              description: m.description,
              weekLabel: m.weekLabel,
              xpReward: m.xpReward,
              status: m.status,
              emoji: m.emoji,
              tool: m.tool,
              toolUrl: m.toolUrl,
              estimatedTime: m.estimatedTime,
              source: m.source,
              sourceInsight: m.sourceInsight,
              relevanceReason: m.relevanceReason,
              steps: m.steps,
              alternativeSteps: m.alternativeSteps,
              microTasks: m.microTasks,
              resources: m.resources,
            );
          });
          state = state.copyWith(milestones: patched);
          print('✅ Patched temp IDs with real Supabase UUIDs');
        }
      } catch (e) {
        // UI is already showing — a DB failure here is non-fatal
        print('⚠ DB insert failed (UI unaffected): $e');
      }
    } catch (e) {
      print('❌ AI Fetch Failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _s(dynamic value, String fallback) {
    if (value == null) return fallback;
    return value.toString().trim();
  }

  /// Generates micro-task sub-actions for a single step.
  /// Mirrors the logic in milestone_detail_screen.dart — kept in sync manually.
  /// Stored in DB as micro_tasks[i] for RAG embedding alongside steps[i].
  List<String> _buildMicroTasksForStep(String stepText) {
    final lower = stepText.toLowerCase();

    String? extractExamples() {
      final m = RegExp(r'\(e\.?g\.?,?\s*([^)]+)\)').firstMatch(stepText);
      return m?.group(1)?.trim();
    }

    String? extractQuoted() {
      final m = RegExp(r'"([^"]{3,40})"').firstMatch(stepText);
      return m?.group(1)?.trim();
    }

    final examples = extractExamples();
    final quoted   = extractQuoted();

    if (lower.contains('register') || lower.contains('sign up') || lower.contains('create account')) {
      final platform = examples ?? quoted ?? 'the platform';
      return [
        'Open $platform using the link in Recommended Tool below',
        'Fill in your business name, registration number and contact details',
        'Upload required documents (IC, SSM cert, bank statement if asked)',
        'Submit and screenshot or save your confirmation number',
      ];
    }
    if ((lower.contains('identify') || lower.contains('list') || lower.contains('select')) && examples != null) {
      return [
        'The step has already identified the options: $examples',
        'Open your notes app, Google Doc, or spreadsheet',
        'Write down each option and one reason why it fits your business',
        'Rank them by priority — put the easiest to act on first',
        'Save the list so you can reference it in later steps',
      ];
    }
    if (lower.contains('research') || lower.contains('identify') || lower.contains('find')) {
      final topic = examples ?? quoted ?? 'the options for this step';
      return [
        'Open Google or the tool linked in Recommended Tool below',
        'Search specifically for: $topic',
        'Open at least 3 results and note the key details from each',
        'Write your shortlist in a notes app or spreadsheet',
        'Pick the one best fit and note your reasoning',
      ];
    }
    if (lower.contains('go to') || lower.contains('visit') || lower.contains('open the')) {
      final dest = quoted ?? examples ?? 'the website in Recommended Tool below';
      return [
        'Open $dest in your browser',
        'Find the specific section or form mentioned in the step',
        'Complete what the page asks for — do not skip any required fields',
        'Screenshot or save confirmation before closing the page',
      ];
    }
    if (lower.contains('contact') || lower.contains('reach out') || lower.contains('email') || lower.contains('call')) {
      final who = examples ?? quoted ?? 'the contact';
      return [
        'Find the correct contact details for $who (website, LinkedIn, or WhatsApp)',
        'Write a 3-sentence message: who you are, what you need, and your ask',
        'Send the message or make the call now — do not draft and delay',
        'Log the date sent and expected reply timeframe in your notes',
      ];
    }
    if (lower.contains('set up') || lower.contains('configure') || lower.contains('install') ||
        lower.contains('create your') || lower.contains('open your')) {
      final tool = quoted ?? examples ?? 'the tool in Recommended Tool below';
      return [
        'Open $tool using the link in Recommended Tool below',
        'Complete the account creation or onboarding flow',
        'Enter your business name, sector and contact details',
        'Do one test action (create a record, post, or invoice) to confirm it works',
      ];
    }
    if (lower.contains('write') || lower.contains('draft') || lower.contains('prepare') ||
        lower.contains('create a') || lower.contains('build a')) {
      final doc = examples ?? quoted ?? 'the document';
      return [
        'Open Google Docs, Word, or your notes app',
        'Start with a title and the key sections needed for $doc',
        'Fill in the content — write quickly, fix later',
        'Review once for missing info or errors',
        'Save and share with anyone who needs to see it',
      ];
    }
    if (lower.contains('post') || lower.contains('publish') || lower.contains('upload') || lower.contains('share')) {
      final platform = examples ?? quoted ?? 'the platform';
      return [
        'Prepare your content (image, caption, or file) before opening $platform',
        'Log in and go to the upload or create section',
        'Fill in all required fields — title, description, category',
        'Hit publish and confirm it is publicly visible',
      ];
    }
    if (lower.contains('analys') || lower.contains('review') || lower.contains('check') ||
        lower.contains('measure') || lower.contains('track')) {
      final what = examples ?? quoted ?? 'the data for this step';
      return [
        'Open the tool or report that contains $what',
        'Look at the numbers — note what is higher or lower than expected',
        'Write 2–3 observations in plain language',
        'Decide on one action you will take based on what you found',
      ];
    }
    if (lower.contains('apply') || lower.contains('submit') || lower.contains('application') ||
        lower.contains('register for') || lower.contains('enrol')) {
      final programme = examples ?? quoted ?? 'the programme';
      return [
        'Read the eligibility requirements for $programme in the Resources section below',
        'Gather all required documents before starting the form',
        'Fill in the application completely — do not leave fields blank',
        'Submit and immediately save your reference number or confirmation email',
      ];
    }
    if (lower.contains('calculat') || lower.contains('estimat') || lower.contains('forecast')) {
      return [
        'Open a spreadsheet or calculator app',
        'Enter the numbers or data you already have',
        'Apply the formula or method described in the step',
        'Write down the result and what it means for your next decision',
      ];
    }
    return [
      'Re-read the step once to confirm you understand exactly what is needed',
      'Gather any tools, documents or information required',
      'Execute the step completely — do not stop halfway',
      'Verify your result matches what the step asked for before marking done',
    ];
  }

  String _sanitizeJson(String json) {
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
      if (inString && (code == 10 || code == 13 || code == 9)) {
        buffer.write(' ');
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI Strategy (fire-and-forget — never blocks UI)
  // ─────────────────────────────────────────────────────────────────────────

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
      print('⚠ AI strategy generation failed (non-fatal): $e');
    }
  }
  // ─────────────────────────────────────────────────────────────────────────
  // Public actions
  // ─────────────────────────────────────────────────────────────────────────

  void completeMilestone(String milestoneId) {
    // 1. Mark target done
    final updated = state.milestones.map((m) {
      if (m.id == milestoneId && m.status == MilestoneStatus.current) {
        return m.copyWith(status: MilestoneStatus.done);
      }
      return m;
    }).toList();

    // 2. Unlock next locked milestone
    bool unlocked = false;
    final finalMilestones = updated.map((m) {
      if (unlocked) return m;
      if (m.status == MilestoneStatus.locked) {
        unlocked = true;
        _updateMilestoneStatusInDb(m.id, 'current');
        return m.copyWith(status: MilestoneStatus.current);
      }
      return m;
    }).toList();

    _updateMilestoneStatusInDb(milestoneId, 'done');

    final earned = state.milestones
        .firstWhere((m) => m.id == milestoneId,
            orElse: () => state.milestones.first)
        .xpReward;

    state = state.copyWith(
      milestones: finalMilestones,
      totalXp: state.totalXp + earned,
    );
  }

  Future<void> _updateMilestoneStatusInDb(String id, String status) async {
    if (!id.startsWith('temp_')) {
      try {
        await Supabase.instance.client
            .from('user_milestones')
            .update({'status': status}).eq('id', id);
      } catch (e) {
        print('⚠ Status update failed: $e');
      }
    }
  }

  Future<void> updateMilestoneProgress(
      String milestoneId, int newCurrentStep) async {
    // Optimistic UI update
    state = state.copyWith(
      milestones: state.milestones.map((m) {
        if (m.id == milestoneId) return m.copyWith(currentStep: newCurrentStep);
        return m;
      }).toList(),
    );

    if (!milestoneId.startsWith('temp_')) {
      try {
        await Supabase.instance.client
            .from('user_milestones')
            .update({'current_step': newCurrentStep}).eq('id', milestoneId);
      } catch (e) {
        print('⚠ Step progress save failed: $e');
      }
    }
  }
}

final roadmapControllerProvider =
    StateNotifierProvider<RoadmapController, RoadmapState>(
  (_) => RoadmapController(),
);