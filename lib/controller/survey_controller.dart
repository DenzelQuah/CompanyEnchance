// lib/controller/survey_controller.dart
// Riverpod StateNotifier — owns all survey navigation & response state.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/survey_model.dart';
import '../../model/dashboard_model.dart';

class SurveyController extends StateNotifier<SurveyModel> {
  SurveyController() : super(const SurveyModel());

  // ── Navigation ──────────────────────────────────────────────────────────────

  /// Advance to next question, or mark complete if on last step.
  void nextStep() {
    if (state.currentStep < SurveyModel.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    } else {
      state = state.copyWith(isComplete: true);
    }
  }

  /// Go back one step (minimum step 0).
  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // ── Q1: Business Identity ───────────────────────────────────────────────────

  void updateBusinessName(String value) =>
      state = state.copyWith(businessName: value);

  void updateSector(String value) =>
      state = state.copyWith(sector: value);

  // ── Q2: Location ─────────────────────────────────────────────────────────────

  void updateLocation(String value) =>
      state = state.copyWith(location: value);

  // ── Q3: Sales Tracking ───────────────────────────────────────────────────────

  void updateSalesTracking(SalesTracking value) =>
      state = state.copyWith(salesTracking: value);

  // ── Q4: Team Size ────────────────────────────────────────────────────────────

  void incrementTeamSize() =>
      state = state.copyWith(teamSize: state.teamSize + 1);

  void decrementTeamSize() {
    if (state.teamSize > 1) {
      state = state.copyWith(teamSize: state.teamSize - 1);
    }
  }

  // ── Q5: Primary Goal ─────────────────────────────────────────────────────────

  void updatePrimaryGoal(PrimaryGoal value) =>
      state = state.copyWith(primaryGoal: value);

  // ── Q6: Financial Audit ──────────────────────────────────────────────────────

  void toggleAuditedStatements() =>
      state = state.copyWith(
        hasAuditedStatements: !state.hasAuditedStatements,
      );

  // ── Q7: Digital Presence (multi-select) ──────────────────────────────────────

  void toggleDigitalPlatform(String platform) {
    final current = List<String>.from(state.digitalPresence);
    current.contains(platform)
        ? current.remove(platform)
        : current.add(platform);
    state = state.copyWith(digitalPresence: current);
  }

  // ── Q8: Supply Chain ─────────────────────────────────────────────────────────

  void updateSupplyChain(SupplyChain value) =>
      state = state.copyWith(supplyChain: value);

  // ── Q9: Weekly Commitment ────────────────────────────────────────────────────

  void updateWeeklyCommitment(WeeklyCommitment value) =>
      state = state.copyWith(weeklyCommitment: value);

  // ── Q10: Budget Plan ─────────────────────────────────────────────────────────

  void updateBudgetPlan(BudgetPlan value) =>
      state = state.copyWith(budgetPlan: value);

  // ── Computed Scores ──────────────────────────────────────────────────────────

  /// Weighted 0–100 overall readiness score derived from survey responses.
  int get readinessScore {
    int score = 0;
    final s = state;
    if (s.businessName.isNotEmpty) score += 5;
    if (s.sector.isNotEmpty)       score += 5;
    switch (s.salesTracking) {
      case SalesTracking.app:   score += 15; break;
      case SalesTracking.excel: score += 8;  break;
      case SalesTracking.paper: score += 2;  break;
      case null: break;
    }
    if (s.hasAuditedStatements) score += 20;
    score += (s.digitalPresence.length * 5).clamp(0, 20);
    if (s.supplyChain != null) score += 5;
    switch (s.weeklyCommitment) {
      case WeeklyCommitment.moreThan20:  score += 15; break;
      case WeeklyCommitment.tenToTwenty: score += 10; break;
      case WeeklyCommitment.fiveToTen:   score += 5;  break;
      default: break;
    }
    if (s.budgetPlan == BudgetPlan.investmentReady) score += 10;
    else if (s.budgetPlan == BudgetPlan.zeroDollar) score += 5;
    return score.clamp(0, 100);
  }

  /// Returns radar chart axis scores (0.0–1.0) derived from survey answers.
  List<RadarScore> get radarScores => [
    RadarScore(
      axis: 'Finance',
      current: state.hasAuditedStatements ? 0.85 : 0.35,
      target: 0.90,
    ),
    RadarScore(
      axis: 'Digital',
      current: (state.digitalPresence.length / 5).clamp(0.0, 1.0),
      target: 0.90,
    ),
    RadarScore(
      axis: 'Supply\nChain',
      current: state.supplyChain == SupplyChain.mixed
          ? 0.65
          : state.supplyChain == SupplyChain.importHeavy
              ? 0.50
              : 0.45,
      target: 0.80,
    ),
    RadarScore(
      axis: 'Operations',
      current: state.salesTracking == SalesTracking.app
          ? 0.80
          : state.salesTracking == SalesTracking.excel
              ? 0.55
              : 0.30,
      target: 0.85,
    ),
    RadarScore(
      axis: 'Compliance',
      current: state.hasAuditedStatements ? 0.70 : 0.30,
      target: 0.75,
    ),
  ];

  /// Full dashboard summary built from survey responses.
  DashboardSummary get dashboardSummary => DashboardSummary(
    readinessScore: readinessScore,
    milestonesComplete: 3,
    totalXp: 350,
    level: 2,
    levelLabel: 'Emerging Business',
    radarScores: radarScores,
    ganttTasks: GanttTask.defaults,
    metrics: MetricTile.defaults,
  );
}

// ─── Riverpod Provider ────────────────────────────────────────────────────────

final surveyControllerProvider =
    StateNotifierProvider<SurveyController, SurveyModel>(
  (_) => SurveyController(),
);
