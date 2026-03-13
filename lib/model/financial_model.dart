class MissingRequirement {
  final String code;
  final String label;
  final double current;
  final double max;
  final double missingPoints;
  final String actionTip;

  const MissingRequirement({
    required this.code,
    required this.label,
    required this.current,
    required this.max,
    required this.missingPoints,
    required this.actionTip,
  });

  factory MissingRequirement.fromMap(Map<String, dynamic> map) {
    return MissingRequirement(
      code: (map['code'] as String? ?? '').trim(),
      label: (map['label'] as String? ?? '').trim(),
      current: ((map['current'] as num?) ?? 0).toDouble(),
      max: ((map['max'] as num?) ?? 0).toDouble(),
      missingPoints: ((map['missing_points'] as num?) ?? 0).toDouble(),
      actionTip: (map['action_tip'] as String? ?? '').trim(),
    );
  }
}

class BankReadiness {
  final int score;
  final String tier;
  final int qualifyingThreshold;
  final int pointsToThreshold;
  final List<MissingRequirement> missingRequirements;

  const BankReadiness({
    required this.score,
    required this.tier,
    required this.qualifyingThreshold,
    required this.pointsToThreshold,
    required this.missingRequirements,
  });

  factory BankReadiness.fromMap(Map<String, dynamic> map) {
    final missing = (map['missing_requirements'] as List<dynamic>? ?? [])
        .map(
          (e) =>
              MissingRequirement.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    return BankReadiness(
      score: (map['score'] as num? ?? 0).toInt(),
      tier: (map['tier'] as String? ?? '').trim(),
      qualifyingThreshold: (map['qualifying_threshold'] as num? ?? 80).toInt(),
      pointsToThreshold: (map['points_to_threshold'] as num? ?? 0).toInt(),
      missingRequirements: missing,
    );
  }
}

class GrantMatch {
  final String id;
  final String name;
  final String agency;
  final String country;
  final String state;
  final double maxFundingRm;
  final String deadline;
  final double fitScore;
  final String applicationUrl;
  final List<String> requirements;
  final List<String> unmetRequirements;

  const GrantMatch({
    required this.id,
    required this.name,
    required this.agency,
    required this.country,
    required this.state,
    required this.maxFundingRm,
    required this.deadline,
    required this.fitScore,
    required this.applicationUrl,
    required this.requirements,
    required this.unmetRequirements,
  });

  factory GrantMatch.fromMap(Map<String, dynamic> map) {
    List<String> strList(dynamic raw) =>
        (raw as List<dynamic>? ?? []).map((e) => '$e').toList();
    return GrantMatch(
      id: (map['id'] as String? ?? '').trim(),
      name: (map['name'] as String? ?? '').trim(),
      agency: (map['agency'] as String? ?? '').trim(),
      country: (map['country'] as String? ?? '').trim(),
      state: (map['state'] as String? ?? '').trim(),
      maxFundingRm: ((map['max_funding_rm'] as num?) ?? 0).toDouble(),
      deadline: (map['deadline'] as String? ?? '').trim(),
      fitScore: ((map['fit_score'] as num?) ?? 0).toDouble(),
      applicationUrl: (map['application_url'] as String? ?? '').trim(),
      requirements: strList(map['requirements']),
      unmetRequirements: strList(map['unmet_requirements']),
    );
  }
}

class FinancialSummary {
  final BankReadiness readiness;
  final List<GrantMatch> matchedGrants;

  const FinancialSummary({
    required this.readiness,
    required this.matchedGrants,
  });

  factory FinancialSummary.fromMap(Map<String, dynamic> map) {
    final grants = (map['matched_grants'] as List<dynamic>? ?? [])
        .map((e) => GrantMatch.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return FinancialSummary(
      readiness: BankReadiness.fromMap(
        Map<String, dynamic>.from(map['readiness'] as Map? ?? const {}),
      ),
      matchedGrants: grants,
    );
  }
}

class FinancialTarget {
  final String userId;
  final String month;
  final double monthlyBudgetRm;
  final double targetGrowthPct;

  const FinancialTarget({
    required this.userId,
    required this.month,
    required this.monthlyBudgetRm,
    required this.targetGrowthPct,
  });

  factory FinancialTarget.fromMap(Map<String, dynamic> map) {
    return FinancialTarget(
      userId: (map['user_id'] as String? ?? '').trim(),
      month: (map['month'] as String? ?? '').trim(),
      monthlyBudgetRm: ((map['monthly_budget_rm'] as num?) ?? 0).toDouble(),
      targetGrowthPct: ((map['target_growth_pct'] as num?) ?? 0).toDouble(),
    );
  }
}

class DailyFinancialLog {
  final String id;
  final String userId;
  final String logDate;
  final double revenueRm;
  final double expenseRm;
  final String? note;

  const DailyFinancialLog({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.revenueRm,
    required this.expenseRm,
    this.note,
  });

  factory DailyFinancialLog.fromMap(Map<String, dynamic> map) {
    return DailyFinancialLog(
      id: (map['id'] as String? ?? '').trim(),
      userId: (map['user_id'] as String? ?? '').trim(),
      logDate: (map['log_date'] as String? ?? '').trim(),
      revenueRm: ((map['revenue_rm'] as num?) ?? 0).toDouble(),
      expenseRm: ((map['expense_rm'] as num?) ?? 0).toDouble(),
      note: (map['note'] as String?)?.trim(),
    );
  }
}

class FinancialGrowthGraphData {
  final String month;
  final double monthlyBudgetRm;
  final double targetGrowthPct;
  final List<String> dates;
  final List<double> projectionGrowthPct;
  final List<double> actualGrowthPct;

  const FinancialGrowthGraphData({
    required this.month,
    required this.monthlyBudgetRm,
    required this.targetGrowthPct,
    required this.dates,
    required this.projectionGrowthPct,
    required this.actualGrowthPct,
  });

  factory FinancialGrowthGraphData.fromMap(Map<String, dynamic> map) {
    List<double> toDoubleList(String key) {
      return (map[key] as List<dynamic>? ?? [])
          .map((e) => ((e as num?) ?? 0).toDouble())
          .toList();
    }

    return FinancialGrowthGraphData(
      month: (map['month'] as String? ?? '').trim(),
      monthlyBudgetRm: ((map['monthly_budget_rm'] as num?) ?? 0).toDouble(),
      targetGrowthPct: ((map['target_growth_pct'] as num?) ?? 0).toDouble(),
      dates: (map['dates'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      projectionGrowthPct: toDoubleList('projection_growth_pct'),
      actualGrowthPct: toDoubleList('actual_growth_pct'),
    );
  }
}
