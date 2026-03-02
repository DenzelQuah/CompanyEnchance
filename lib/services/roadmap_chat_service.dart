import 'package:supabase_flutter/supabase_flutter.dart';

enum RoadmapIntent { inquiry, action }

class RoadmapActionPlan {
  final String actionType;
  final String implementationPlan;
  final Map<String, dynamic> payload;
  final String? conflictMessage;

  const RoadmapActionPlan({
    required this.actionType,
    required this.implementationPlan,
    required this.payload,
    this.conflictMessage,
  });
}

class RoadmapActionResult {
  final bool success;
  final String message;
  final String? successId;

  const RoadmapActionResult({
    required this.success,
    required this.message,
    this.successId,
  });
}

class RoadmapChatService {
  RoadmapChatService(this._supabase);

  final SupabaseClient _supabase;

  static const String _guide = '''
Roadmap guide:
- Finish Product Development before executing Marketing phase.
- Keep one active "current" milestone at a time.
- Complete operational milestones before expansion milestones when possible.
''';

  RoadmapIntent classifyIntent(String input) {
    final text = input.trim().toLowerCase();
    final inquiryPattern = RegExp(r'^(how|why|what|tell me about)\b');
    final actionPattern = RegExp(r'\b(add|change|complete|delete|move)\b');

    if (inquiryPattern.hasMatch(text)) return RoadmapIntent.inquiry;
    if (actionPattern.hasMatch(text)) return RoadmapIntent.action;
    return RoadmapIntent.inquiry;
  }

  Future<String> searchRoadmapInfo({
    required String userId,
    required String query,
    String? detailedStrategy,
  }) async {
    final milestones = await _fetchMilestones(userId);
    final done = milestones.where((m) => m['status'] == 'done').length;
    final current = milestones.where((m) => m['status'] == 'current').toList();

    final milestoneLines = milestones
        .map((m) => '- ${m['title']} [${m['status']}] (${m['week_label']})')
        .join('\n');

    return '''
Intent: INQUIRY
Tool: search_roadmap_info

Grounded context:
- Total milestones: ${milestones.length}
- Completed milestones: $done
- Current milestone: ${current.isNotEmpty ? current.first['title'] : 'None'}

Roadmap guide context:
$_guide

Your roadmap data:
$milestoneLines

Answer:
${_buildInquiryAnswer(query, done, milestones.length, detailedStrategy)}
''';
  }

  Future<String> search_roadmap_info({
    required String userId,
    required String query,
    String? detailedStrategy,
  }) {
    return searchRoadmapInfo(
      userId: userId,
      query: query,
      detailedStrategy: detailedStrategy,
    );
  }

  Future<RoadmapActionPlan> buildImplementationPlan({
    required String userId,
    required String input,
  }) async {
    final milestones = await _fetchMilestones(userId);
    final lower = input.toLowerCase();
    final quoted = RegExp(r'"([^"]+)"').firstMatch(input)?.group(1)?.trim();
    final actionType = _detectActionType(lower);

    final target = _findTargetMilestone(milestones, lower, quoted);
    final newTitle = _extractAddTitle(input, quoted);
    final moveWeek = _extractWeek(input);
    final isMarketingAdd =
        actionType == 'add' &&
        (newTitle?.toLowerCase().contains('marketing') ?? false);
    final unfinishedProduct = milestones.any((m) {
      final title = (m['title'] as String?)?.toLowerCase() ?? '';
      return title.contains('product') && m['status'] != 'done';
    });

    String? conflict;
    if (isMarketingAdd && unfinishedProduct) {
      conflict =
          "Based on the roadmap guide, it's recommended to finish Product Development first. "
          'Do you still want to add the Marketing phase?';
    }

    final payload = <String, dynamic>{
      'action_type': actionType,
      'target_id': target?['id'],
      'target_title': target?['title'],
      'new_title': newTitle,
      'new_week_label': moveWeek,
      'raw_input': input.trim(),
    };

    final affectedRow = switch (actionType) {
      'add' => 'New row in user_milestones for user_id=$userId',
      'complete' || 'delete' || 'change' || 'move' =>
        target == null
            ? 'No matching row found in user_milestones'
            : 'id=${target['id']} title="${target['title']}"',
      _ => 'No supported action detected',
    };

    final plan =
        '''
Intent: ACTION
Implementation Plan Artifact:
1. Action type: ${actionType.toUpperCase()}
2. Supabase table: user_milestones
3. Affected row: $affectedRow
4. Payload: $payload
''';

    return RoadmapActionPlan(
      actionType: actionType,
      implementationPlan: plan,
      payload: payload,
      conflictMessage: conflict,
    );
  }

  Future<RoadmapActionResult> updateRoadmapDatabase({
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final action = (payload['action_type'] as String? ?? '').toLowerCase();
    final targetId = payload['target_id'] as String?;

    try {
      if (action == 'add') {
        final inserted = await _supabase
            .from('user_milestones')
            .insert({
              'user_id': userId,
              'title': payload['new_title'] ?? 'New Milestone',
              'description': 'Added by AI assistant',
              'week_label': payload['new_week_label'] ?? 'Week TBD',
              'xp_reward': 100,
              'status': 'locked',
              'emoji': '🚀',
            })
            .select()
            .single();

        final successId = inserted['id'] as String?;
        final verification = await _supabase
            .from('user_milestones')
            .select('id,title,status')
            .eq('id', successId ?? '')
            .maybeSingle();

        if (verification != null) {
          return RoadmapActionResult(
            success: true,
            successId: verification['id'] as String?,
            message:
                'Update complete. Verification Read succeeded. Success ID: ${verification['id']}',
          );
        }
      }

      if ((action == 'complete' || action == 'change' || action == 'move') &&
          targetId != null) {
        final updates = <String, dynamic>{};
        if (action == 'complete') updates['status'] = 'done';
        if (action == 'change' && payload['new_title'] != null) {
          updates['title'] = payload['new_title'];
        }
        if (action == 'move' && payload['new_week_label'] != null) {
          updates['week_label'] = payload['new_week_label'];
        }

        if (updates.isEmpty) {
          return const RoadmapActionResult(
            success: false,
            message: 'No valid update fields were found for this action.',
          );
        }

        final updated = await _supabase
            .from('user_milestones')
            .update(updates)
            .eq('id', targetId)
            .select('id')
            .single();

        final verification = await _supabase
            .from('user_milestones')
            .select('id,title,status,week_label')
            .eq('id', targetId)
            .maybeSingle();

        if (verification != null) {
          return RoadmapActionResult(
            success: true,
            successId: verification['id'] as String?,
            message:
                'Update complete. Verification Read succeeded. Success ID: ${verification['id']}',
          );
        }

        return RoadmapActionResult(
          success: false,
          successId: updated['id'] as String?,
          message: 'Update ran, but Verification Read did not find the row.',
        );
      }

      if (action == 'delete' && targetId != null) {
        await _supabase.from('user_milestones').delete().eq('id', targetId);

        final verification = await _supabase
            .from('user_milestones')
            .select('id')
            .eq('id', targetId)
            .maybeSingle();

        if (verification == null) {
          return RoadmapActionResult(
            success: true,
            successId: targetId,
            message:
                'Delete complete. Verification Read confirmed removal. Success ID: $targetId',
          );
        }
      }

      return const RoadmapActionResult(
        success: false,
        message: 'Action could not be completed with the current payload.',
      );
    } catch (e) {
      return RoadmapActionResult(
        success: false,
        message: 'Database update failed: $e',
      );
    }
  }

  Future<RoadmapActionResult> update_roadmap_database({
    required String userId,
    required Map<String, dynamic> payload,
  }) {
    return updateRoadmapDatabase(userId: userId, payload: payload);
  }

  Future<List<Map<String, dynamic>>> _fetchMilestones(String userId) async {
    final rows = await _supabase
        .from('user_milestones')
        .select('id,title,description,week_label,status,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Map<String, dynamic>? _findTargetMilestone(
    List<Map<String, dynamic>> milestones,
    String lowerInput,
    String? quoted,
  ) {
    if (milestones.isEmpty) return null;

    if (quoted != null) {
      final byQuote = milestones.firstWhere(
        (m) =>
            (m['title'] as String).toLowerCase().contains(quoted.toLowerCase()),
        orElse: () => <String, dynamic>{},
      );
      if (byQuote.isNotEmpty) return byQuote;
    }

    for (final m in milestones) {
      final title = (m['title'] as String).toLowerCase();
      if (lowerInput.contains(title)) return m;
    }

    if (lowerInput.contains('current')) {
      for (final m in milestones) {
        if ((m['status'] as String) == 'current') return m;
      }
    }

    return milestones.first;
  }

  String _detectActionType(String lower) {
    if (lower.contains('complete')) return 'complete';
    if (lower.contains('delete')) return 'delete';
    if (lower.contains('move')) return 'move';
    if (lower.contains('change')) return 'change';
    if (lower.contains('add')) return 'add';
    return 'unknown';
  }

  String? _extractAddTitle(String input, String? quoted) {
    if (quoted != null && quoted.isNotEmpty) return quoted;
    final lowered = input.toLowerCase();
    final idx = lowered.indexOf('add');
    if (idx < 0) return null;
    final tail = input.substring(idx + 3).trim();
    if (tail.isEmpty) return null;
    final cleaned = tail
        .replaceAll(RegExp(r'^(a|an|new)\s+', caseSensitive: false), '')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String? _extractWeek(String input) {
    final week = RegExp(
      r'week\s*\d+',
      caseSensitive: false,
    ).firstMatch(input)?.group(0);
    return week == null ? null : _capitalizeWords(week);
  }

  String _capitalizeWords(String text) {
    return text
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _buildInquiryAnswer(
    String query,
    int doneCount,
    int totalCount,
    String? strategy,
  ) {
    if (totalCount == 0) {
      return 'No milestones are available yet. Generate roadmap milestones first.';
    }

    if (query.toLowerCase().contains('progress')) {
      return 'Your roadmap progress is $doneCount/$totalCount milestones completed.';
    }

    if (query.toLowerCase().contains('why')) {
      return 'Roadmap order prioritizes foundational work first to reduce execution risk before scale activities.';
    }

    if (strategy != null && strategy.trim().isNotEmpty) {
      return 'Based on your saved roadmap strategy: ${strategy.trim()}';
    }

    return 'Based on your roadmap data, focus on completing your current milestone before adding expansion tasks.';
  }
}
