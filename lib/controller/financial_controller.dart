import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/financial_model.dart';
import '../services/financial_api_service.dart';

String _monthKey(DateTime dt) {
  final m = dt.month.toString().padLeft(2, '0');
  return '${dt.year}-$m';
}

class FinancialState {
  final FinancialSummary? summary;
  final FinancialTarget? target;
  final FinancialGrowthGraphData? graph;
  final List<DailyFinancialLog> logs;
  final DateTime selectedMonth;
  final bool isLoading;
  final bool isSavingTarget;
  final bool isSavingLog;
  final String error;

  const FinancialState({
    this.summary,
    this.target,
    this.graph,
    this.logs = const [],
    required this.selectedMonth,
    this.isLoading = true,
    this.isSavingTarget = false,
    this.isSavingLog = false,
    this.error = '',
  });

  factory FinancialState.initial() => FinancialState(selectedMonth: DateTime.now());

  FinancialState copyWith({
    FinancialSummary? summary,
    FinancialTarget? target,
    FinancialGrowthGraphData? graph,
    List<DailyFinancialLog>? logs,
    DateTime? selectedMonth,
    bool? isLoading,
    bool? isSavingTarget,
    bool? isSavingLog,
    String? error,
  }) {
    return FinancialState(
      summary: summary ?? this.summary,
      target: target ?? this.target,
      graph: graph ?? this.graph,
      logs: logs ?? this.logs,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      isLoading: isLoading ?? this.isLoading,
      isSavingTarget: isSavingTarget ?? this.isSavingTarget,
      isSavingLog: isSavingLog ?? this.isSavingLog,
      error: error ?? this.error,
    );
  }
}

class FinancialController extends StateNotifier<FinancialState> {
  FinancialController()
    : _api = FinancialApiService(),
      _supabase = Supabase.instance.client,
      super(FinancialState.initial()) {
    loadAll();
  }

  final FinancialApiService _api;
  final SupabaseClient _supabase;
  String? _loadedUserId;

  String get selectedMonthKey => _monthKey(state.selectedMonth);

  Future<String?> _resolveActiveUserId() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId != null && authId.isNotEmpty) return authId;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('survey_session_id');
  }

  Future<void> ensureLoadedForCurrentUser() async {
    final currentId = await _resolveActiveUserId();
    if (currentId == _loadedUserId && !state.isLoading) return;
    _loadedUserId = currentId;
    await loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final userId = await _resolveActiveUserId();
      if (userId == null || userId.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Missing user identity. Please complete survey/login first.',
        );
        return;
      }
      _loadedUserId = userId;

      final month = selectedMonthKey;
      final summary = await _api.fetchSummary(userId: userId);
      final target = await _api.fetchTarget(userId: userId, month: month);
      final logs = await _api.fetchDailyLogs(userId: userId, month: month);
      final graph = await _api.fetchGrowthGraph(userId: userId, month: month);

      state = state.copyWith(
        summary: summary,
        target: target,
        logs: logs,
        graph: graph,
        isLoading: false,
        error: '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load financial data: $e',
      );
    }
  }

  Future<void> changeMonth(DateTime monthDate) async {
    state = state.copyWith(selectedMonth: DateTime(monthDate.year, monthDate.month, 1));
    await loadAll();
  }

  Future<void> saveTarget({
    required double monthlyBudgetRm,
    required double targetGrowthPct,
  }) async {
    state = state.copyWith(isSavingTarget: true, error: '');
    try {
      final userId = await _resolveUserId();
      if (userId == null || userId.isEmpty) {
        state = state.copyWith(
          isSavingTarget: false,
          error: 'Unable to save target without a user id.',
        );
        return;
      }

      final target = await _api.upsertTarget(
        userId: userId,
        month: selectedMonthKey,
        monthlyBudgetRm: monthlyBudgetRm,
        targetGrowthPct: targetGrowthPct,
      );
      final graph = await _api.fetchGrowthGraph(userId: userId, month: selectedMonthKey);
      state = state.copyWith(
        target: target,
        graph: graph,
        isSavingTarget: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSavingTarget: false,
        error: 'Unable to save monthly target: $e',
      );
    }
  }

  Future<void> saveDailyLog({
    required DateTime logDate,
    required double revenueRm,
    required double expenseRm,
    String? note,
  }) async {
    state = state.copyWith(isSavingLog: true, error: '');
    try {
      final userId = await _resolveUserId();
      if (userId == null || userId.isEmpty) {
        state = state.copyWith(
          isSavingLog: false,
          error: 'Unable to save log without a user id.',
        );
        return;
      }

      final day = logDate.day.toString().padLeft(2, '0');
      final month = logDate.month.toString().padLeft(2, '0');
      final dateStr = '${logDate.year}-$month-$day';

      await _api.upsertDailyLog(
        userId: userId,
        logDate: dateStr,
        revenueRm: revenueRm,
        expenseRm: expenseRm,
        note: note,
      );

      final logs = await _api.fetchDailyLogs(userId: userId, month: selectedMonthKey);
      final graph = await _api.fetchGrowthGraph(userId: userId, month: selectedMonthKey);
      state = state.copyWith(
        logs: logs,
        graph: graph,
        isSavingLog: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSavingLog: false,
        error: 'Unable to save daily log: $e',
      );
    }
  }

  Future<String?> _resolveUserId() => _resolveActiveUserId();
}

final financialControllerProvider =
    StateNotifierProvider<FinancialController, FinancialState>(
      (_) => FinancialController(),
    );
