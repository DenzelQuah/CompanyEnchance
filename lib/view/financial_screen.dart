import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/financial_controller.dart';
import '../model/app_theme.dart';
import '../model/financial_model.dart';

class FinancialScreen extends ConsumerStatefulWidget {
  const FinancialScreen({super.key});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen> {
  final _budgetCtrl = TextEditingController();
  final _growthCtrl = TextEditingController();
  final _revenueCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _logDate = DateTime.now();
  String _targetHydrationKey = '';
  final Set<String> _acknowledgedRequirementCodes = <String>{};

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _growthCtrl.dispose();
    _revenueCtrl.dispose();
    _expenseCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialControllerProvider);
    final ctrl = ref.read(financialControllerProvider.notifier);
    final summary = state.summary;
    if (summary != null) {
      final activeCodes =
          summary.readiness.missingRequirements.map((e) => e.code).toSet();
      _acknowledgedRequirementCodes.removeWhere((c) => !activeCodes.contains(c));
    }

    final target = state.target;
    final hydrationKey = '${target?.month ?? ''}|${target?.monthlyBudgetRm ?? 0}|${target?.targetGrowthPct ?? 0}';
    if (hydrationKey != _targetHydrationKey && target != null) {
      _budgetCtrl.text = target.monthlyBudgetRm.toStringAsFixed(0);
      _growthCtrl.text = target.targetGrowthPct.toStringAsFixed(1);
      _targetHydrationKey = hydrationKey;
    }

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (summary == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Financial')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.error.isEmpty ? 'No financial data available.' : state.error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: ctrl.loadAll, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            expandedHeight: 128,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Financial Co-Pilot',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track monthly targets, daily actuals, and growth trend.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickMonth(context, ctrl, state.selectedMonth),
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: Text(_monthLabel(state.selectedMonth)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ReadinessCard(
                  readiness: summary.readiness,
                  acknowledgedCodes: _acknowledgedRequirementCodes,
                  onToggleAcknowledged: _toggleAcknowledgedRequirement,
                ),
                const SizedBox(height: 16),
                _TargetCard(
                  budgetCtrl: _budgetCtrl,
                  growthCtrl: _growthCtrl,
                  isSaving: state.isSavingTarget,
                  onSave: () => _saveTarget(ctrl),
                ),
                const SizedBox(height: 16),
                _DailyLogCard(
                  logDate: _logDate,
                  revenueCtrl: _revenueCtrl,
                  expenseCtrl: _expenseCtrl,
                  noteCtrl: _noteCtrl,
                  isSaving: state.isSavingLog,
                  onPickDate: () => _pickLogDate(context),
                  onSave: () => _saveLog(ctrl),
                ),
                const SizedBox(height: 16),
                _GrowthGraphCard(graph: state.graph),
                const SizedBox(height: 16),
                _RecentLogsCard(logs: state.logs),
                const SizedBox(height: 16),
                _GrantMatcherCard(grants: summary.matchedGrants),
                if (state.error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.error,
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth(
    BuildContext context,
    FinancialController ctrl,
    DateTime currentMonth,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentMonth,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Select any date in target month',
    );
    if (picked != null) {
      await ctrl.changeMonth(DateTime(picked.year, picked.month, 1));
    }
  }

  Future<void> _pickLogDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _logDate = picked;
      });
    }
  }

  Future<void> _saveTarget(FinancialController ctrl) async {
    final budget = double.tryParse(_budgetCtrl.text.trim()) ?? -1;
    final growth = double.tryParse(_growthCtrl.text.trim()) ?? 9999;
    if (budget < 0 || growth < -100 || growth > 500) {
      _showInputError('Enter valid budget (>=0) and growth (-100 to 500).');
      return;
    }
    await ctrl.saveTarget(monthlyBudgetRm: budget, targetGrowthPct: growth);
  }

  Future<void> _saveLog(FinancialController ctrl) async {
    final revenue = double.tryParse(_revenueCtrl.text.trim()) ?? -1;
    final expense = double.tryParse(_expenseCtrl.text.trim()) ?? -1;
    if (revenue < 0 || expense < 0) {
      _showInputError('Enter valid revenue/expense values (>=0).');
      return;
    }
    await ctrl.saveDailyLog(
      logDate: _logDate,
      revenueRm: revenue,
      expenseRm: expense,
      note: _noteCtrl.text.trim(),
    );
    _revenueCtrl.clear();
    _expenseCtrl.clear();
    _noteCtrl.clear();
  }

  void _showInputError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _monthLabel(DateTime dt) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[dt.month - 1]} ${dt.year}';
  }

  void _toggleAcknowledgedRequirement(String code) {
    setState(() {
      if (_acknowledgedRequirementCodes.contains(code)) {
        _acknowledgedRequirementCodes.remove(code);
      } else {
        _acknowledgedRequirementCodes.add(code);
      }
    });
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.readiness,
    required this.acknowledgedCodes,
    required this.onToggleAcknowledged,
  });

  final BankReadiness readiness;
  final Set<String> acknowledgedCodes;
  final ValueChanged<String> onToggleAcknowledged;

  @override
  Widget build(BuildContext context) {
    final value = readiness.score.clamp(0, 100).toDouble();
    final threshold = readiness.qualifyingThreshold.toDouble().clamp(0, 100);
    final thresholdTurns = threshold / 100;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank-Readiness Score',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            readiness.pointsToThreshold > 0
                ? 'Need ${readiness.pointsToThreshold} more points to reach ${readiness.qualifyingThreshold}.'
                : 'You are above the qualifying threshold.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: value / 100,
                      strokeWidth: 12,
                      color: AppTheme.green,
                      backgroundColor: AppTheme.border,
                    ),
                  ),
                  Transform.rotate(
                    angle: (2 * 3.141592653589793 * thresholdTurns) - (3.141592653589793 / 2),
                    child: const Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.flag_rounded,
                        color: AppTheme.blue,
                        size: 18,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${readiness.score}%',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        readiness.tier,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Missing Requirements',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (readiness.missingRequirements.isEmpty)
            const Text(
              'No blockers detected. Keep maintaining digital and compliance discipline.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            )
          else
            ...readiness.missingRequirements.map((req) {
              final checked = acknowledgedCodes.contains(req.code);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: (_) => onToggleAcknowledged(req.code),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            req.actionTip,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Score impact: missing ${req.missingPoints.toStringAsFixed(1)} / ${req.max.toStringAsFixed(1)} points (current ${req.current.toStringAsFixed(1)}).',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.budgetCtrl,
    required this.growthCtrl,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController budgetCtrl;
  final TextEditingController growthCtrl;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Plan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set your monthly budget and target growth.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: budgetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monthly Budget (RM)',
              hintText: 'e.g. 25000',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: growthCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target Growth (%)',
              hintText: 'e.g. 12',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Monthly Target'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyLogCard extends StatelessWidget {
  const _DailyLogCard({
    required this.logDate,
    required this.revenueCtrl,
    required this.expenseCtrl,
    required this.noteCtrl,
    required this.isSaving,
    required this.onPickDate,
    required this.onSave,
  });

  final DateTime logDate;
  final TextEditingController revenueCtrl;
  final TextEditingController expenseCtrl;
  final TextEditingController noteCtrl;
  final bool isSaving;
  final VoidCallback onPickDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Revenue & Expense',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Date:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.event, size: 16),
                label: Text('${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}'),
              ),
            ],
          ),
          TextField(
            controller: revenueCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Revenue (RM)', hintText: 'e.g. 1200'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: expenseCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Expense (RM)', hintText: 'e.g. 640'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Daily Log'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthGraphCard extends StatelessWidget {
  const _GrowthGraphCard({required this.graph});

  final FinancialGrowthGraphData? graph;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Projection vs Actual Growth',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (graph == null || graph!.dates.isEmpty)
            const Text(
              'Set monthly target and add daily logs to render growth chart.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            )
          else ...[
            Text(
              'Budget RM ${graph!.monthlyBudgetRm.toStringAsFixed(0)} | Target ${graph!.targetGrowthPct.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 230,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppTheme.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= graph!.dates.length) {
                            return const SizedBox.shrink();
                          }
                          if (idx % 7 != 0 && idx != graph!.dates.length - 1) {
                            return const SizedBox.shrink();
                          }
                          final day = graph!.dates[idx].split('-').last;
                          return Text(
                            day,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        graph!.projectionGrowthPct.length,
                        (i) => FlSpot(i.toDouble(), graph!.projectionGrowthPct[i]),
                      ),
                      color: AppTheme.blue,
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: List.generate(
                        graph!.actualGrowthPct.length,
                        (i) => FlSpot(i.toDouble(), graph!.actualGrowthPct[i]),
                      ),
                      color: AppTheme.green,
                      isCurved: true,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                _Legend(color: AppTheme.blue, label: 'Projection Growth'),
                SizedBox(width: 16),
                _Legend(color: AppTheme.green, label: 'Actual Growth'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }
}

class _RecentLogsCard extends StatelessWidget {
  const _RecentLogsCard({required this.logs});

  final List<DailyFinancialLog> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Daily Entries',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            const Text(
              'No daily entries yet for this month.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            )
          else
            ...logs.reversed.take(6).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 88,
                          child: Text(
                            item.logDate,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Rev RM ${item.revenueRm.toStringAsFixed(0)} | Exp RM ${item.expenseRm.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _GrantMatcherCard extends StatelessWidget {
  const _GrantMatcherCard({required this.grants});

  final List<GrantMatch> grants;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grant & Funding Matcher',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Matched by sector, location, and readiness.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          if (grants.isEmpty)
            const Text(
              'No matched grants yet. Improve readiness and location/sector fit to unlock options.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            )
          else
            ...grants.take(6).map(
                  (grant) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      title: Text(
                        grant.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${grant.agency} | Fit ${grant.fitScore.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        'RM ${grant.maxFundingRm.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.green,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Deadline: ${grant.deadline}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Application: ${grant.applicationUrl}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
