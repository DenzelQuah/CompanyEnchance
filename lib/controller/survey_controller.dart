// lib/controller/survey_controller.dart
// Riverpod StateNotifier — owns all survey navigation & response state.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../model/survey_model.dart';
import '../../model/dashboard_model.dart';

class SurveyController extends StateNotifier<SurveyModel> {
  // Call _loadDraft() the moment the controller is created
  SurveyController() : super(const SurveyModel()) {
    _loadDraft();
  }

// ── Auto-Save & Loading Logic ───────────────────────────────────────────────

  /// Checks local storage for a session ID. If found, fetches data from Supabase.
  /// If not found, generates a new unique ID for the session.
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('survey_session_id');

    if (savedId != null) {
      // 1. We remember them! Fetch their saved data from Supabase.
      try {
        final data = await Supabase.instance.client
            .from('survey_responses')
            .select()
            .eq('id', savedId)
            .maybeSingle(); // Gets 1 row, or null if deleted

        if (data != null) {
          // Hydrate the state so they pick up exactly where they left off
          state = SurveyModel.fromMap(data, savedId);
          return;
        }
      } catch (e) {
        print('Error fetching draft from Supabase: $e');
      }
    }
    
    // 2. If no saved ID (or fetch failed), generate a fresh new session ID
    final newId = const Uuid().v4();
    await prefs.setString('survey_session_id', newId);
    state = state.copyWith(uniqueId: newId);
  }

  /// Silently upserts the current survey state to Supabase in the background
  Future<void> _autoSaveToDatabase() async {
    if (state.uniqueId.isEmpty) return; // Failsafe

    try {
      final data = state.toMap(readinessScore);
      // UPSERT: Updates the row if ID exists, inserts new if it doesn't!
      await Supabase.instance.client
          .from('survey_responses')
          .upsert(data);
    } catch (e) {
      print('Background auto-save failed: $e');
    }
  }

  // ── Validation ──────────────────────────────────────────────────────────────
  
  /// Checks if the current step has the required data before advancing.
  bool _validateCurrentStep() {
    switch (state.currentStep) {
      case 0:
        if (state.businessName.trim().isEmpty) {
          _setError('Please enter your business name.');
          return false;
        }
        if (state.sector.isEmpty) {
          _setError('Please select your business sector.');
          return false;
        }
        return true;
      case 1:
        if (state.location.isEmpty) {
          _setError('Please select your location.');
          return false;
        }
        return true;
      case 2:
        if (state.salesTracking == null) {
          _setError('Please select how you track sales.');
          return false;
        }
        return true;
      case 3:
        return true; // Team size always has a default value (5)
      case 4:
        if (state.primaryGoal == null) {
          _setError('Please select your primary goal.');
          return false;
        }
        return true;
      case 5:
        return true; // Audited statements is a boolean toggle (defaults to false)
      case 6:
        if (state.digitalPresence.isEmpty) {
          _setError('Please select at least one digital platform.');
          return false;
        }
        return true;
      case 7:
        if (state.supplyChain == null) {
          _setError('Please describe your supply chain.');
          return false;
        }
        return true;
      case 8:
        if (state.weeklyCommitment == null) {
          _setError('Please select your weekly commitment.');
          return false;
        }
        return true;
      case 9:
        if (state.budgetPlan == null) {
          _setError('Please select a budget plan.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void clearError() {
    if (state.errorMessage.isNotEmpty) {
      state = state.copyWith(errorMessage: '');
    }
  }



  // ── Navigation ──────────────────────────────────────────────────────────────

  /// Advance to next question, or mark complete if on last step.
  void nextStep() {
    // 1. Block navigation if validation fails
    if (!_validateCurrentStep()) return;

    // 2. Clear any existing errors if valid
    clearError();

    // 3. Move forward or submit
    if (state.currentStep < SurveyModel.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      
      // 🔥 MAGIC HAPPENS HERE: Auto-save the moment they go to the next question
      _autoSaveToDatabase(); 
      
    } else {
      _submitToSupabase();
    }
  }

  Future<void> _submitToSupabase() async {
    // Prevent multiple submissions
    if (state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    try {
      // 1. One final upsert to ensure everything is perfect
      await _autoSaveToDatabase(); 

      // 2. Clear the local session ID so they start fresh next time they open the app
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('survey_session_id');

      // 3. Mark complete to trigger UI navigation
      state = state.copyWith(
        isComplete: true,
        isSubmitting: false,
      );
    } catch (e) {
      // Revert loading state if it fails
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to save to database. Check your connection or RLS policies.',
      );
      print('Error saving to Supabase: $e'); 
    }
  }

  /// Go back one step (minimum step 0).
 void prevStep() {
    if (state.currentStep > 0) {
      clearError(); // Clear error when going back
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // ── Q1: Business Identity ───────────────────────────────────────────────────

  void updateBusinessName(String value) {
    state = state.copyWith(businessName: value);
    clearError();
  }

void updateSector(String value) {
    state = state.copyWith(sector: value);
    clearError();
  }

  // ── Q2: Location ─────────────────────────────────────────────────────────────

  void updateLocation(String value) {
    state = state.copyWith(location: value);
    clearError();
  }

  // ── Q3: Sales Tracking ───────────────────────────────────────────────────────

  void updateSalesTracking(SalesTracking value) {
    state = state.copyWith(salesTracking: value);
    clearError();
  }

  // ── Q4: Team Size ────────────────────────────────────────────────────────────

  void incrementTeamSize() =>
      state = state.copyWith(teamSize: state.teamSize + 1);

  void decrementTeamSize() {
    if (state.teamSize > 1) {
      state = state.copyWith(teamSize: state.teamSize - 1);
    }
  }

  // ── Q5: Primary Goal ─────────────────────────────────────────────────────────

  void updatePrimaryGoal(PrimaryGoal value) {
    state = state.copyWith(primaryGoal: value);
    clearError();
  }

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
    clearError();
  }

  // ── Q8: Supply Chain ─────────────────────────────────────────────────────────

  void updateSupplyChain(SupplyChain value) {
    state = state.copyWith(supplyChain: value);
    clearError();
  }

  // ── Q9: Weekly Commitment ────────────────────────────────────────────────────

  void updateWeeklyCommitment(WeeklyCommitment value) {
    state = state.copyWith(weeklyCommitment: value);
    clearError();
  }

  // ── Q10: Budget Plan ─────────────────────────────────────────────────────────

  void updateBudgetPlan(BudgetPlan value) {
    state = state.copyWith(budgetPlan: value);
    clearError();
  }

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

