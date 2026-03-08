import 'package:companyenchancer/model/financial_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FinancialSummary.fromMap parses nested payload', () {
    final payload = {
      'readiness': {
        'score': 70,
        'tier': 'Near Ready',
        'qualifying_threshold': 80,
        'points_to_threshold': 10,
        'missing_requirements': [
          {
            'code': 'digital_statements',
            'label': 'Digital statement history',
            'current': 10,
            'max': 20,
            'missing_points': 10,
            'action_tip': 'Need 3 more months',
          },
        ],
      },
      'matched_grants': [
        {
          'id': 'g1',
          'name': 'Grant A',
          'agency': 'Agency',
          'country': 'Malaysia',
          'state': 'Sarawak',
          'max_funding_rm': 100000,
          'deadline': '2026-12-31',
          'fit_score': 91,
          'application_url': 'https://example.com',
          'requirements': ['Business registration'],
          'unmet_requirements': [],
        },
      ],
    };

    final summary = FinancialSummary.fromMap(payload);
    expect(summary.readiness.score, 70);
    expect(summary.matchedGrants.first.id, 'g1');
  });

  test('FinancialTarget and GrowthGraph parse payload', () {
    final target = FinancialTarget.fromMap({
      'user_id': 'u1',
      'month': '2026-03',
      'monthly_budget_rm': 25000,
      'target_growth_pct': 12,
    });
    expect(target.month, '2026-03');
    expect(target.monthlyBudgetRm, 25000);

    final graph = FinancialGrowthGraphData.fromMap({
      'month': '2026-03',
      'monthly_budget_rm': 25000,
      'target_growth_pct': 12,
      'dates': ['2026-03-01', '2026-03-02'],
      'projection_growth_pct': [0.5, 1.0],
      'actual_growth_pct': [0.4, 0.8],
    });
    expect(graph.dates.length, 2);
    expect(graph.actualGrowthPct.last, 0.8);
  });
}
