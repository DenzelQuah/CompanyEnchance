// lib/model/dashboard_model.dart
// Data models for the Analytics Dashboard.

// ─── Radar / Readiness ────────────────────────────────────────────────────────

class RadarScore {
  final String axis;
  final double current; // 0.0 – 1.0
  final double target;  // 0.0 – 1.0

  const RadarScore({
    required this.axis,
    required this.current,
    required this.target,
  });

  int get currentPct => (current * 100).round();
  int get targetPct  => (target  * 100).round();
}

// ─── Gantt Task ───────────────────────────────────────────────────────────────

class GanttTask {
  final String label;
  final String text;
  final double startFraction; // 0.0 = week 1 start, 1.0 = week 4 end
  final double widthFraction;
  final int colorHex;

  const GanttTask({
    required this.label,
    required this.text,
    required this.startFraction,
    required this.widthFraction,
    required this.colorHex,
  });

  static const List<GanttTask> defaults = [
    GanttTask(
      label: 'Bank\nStatements',
      text: 'Upload Docs',
      startFraction: 0.0,
      widthFraction: 0.25,
      colorHex: 0xFF2E7D32,
    ),
    GanttTask(
      label: 'Grant\nApplication',
      text: 'BPMB Form',
      startFraction: 0.25,
      widthFraction: 0.5,
      colorHex: 0xFF1565C0,
    ),
    GanttTask(
      label: 'Shopee\nOptimize',
      text: 'SEO + Photos',
      startFraction: 0.0,
      widthFraction: 0.75,
      colorHex: 0xFFF59E0B,
    ),
    GanttTask(
      label: 'Export\nResearch',
      text: 'MATRADE Reg',
      startFraction: 0.5,
      widthFraction: 0.5,
      colorHex: 0xFF7C3AED,
    ),
  ];
}

// ─── Metric Tile ──────────────────────────────────────────────────────────────

class MetricTile {
  final String icon;
  final String value;
  final String label;
  final String trend;
  final bool isPositive;

  const MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.trend,
    this.isPositive = true,
  });

  static const List<MetricTile> defaults = [
    MetricTile(icon: '💼', value: 'RM 48K', label: 'Est. Revenue',      trend: '↑ 12%'),
    MetricTile(icon: '🤝', value: '2',      label: 'ASEAN Partners',    trend: 'New this week'),
    MetricTile(icon: '📱', value: '3',      label: 'Digital Channels',  trend: 'Shopee pending', isPositive: false),
    MetricTile(icon: '🏆', value: '#47',   label: 'State Ranking',      trend: '↑ 5 places'),
  ];
}

// ─── Dashboard Summary (aggregated from SurveyModel) ─────────────────────────

class DashboardSummary {
  final int readinessScore;
  final int milestonesComplete;
  final int totalXp;
  final int level;
  final String levelLabel;
  final List<RadarScore> radarScores;
  final List<GanttTask> ganttTasks;
  final List<MetricTile> metrics;

  const DashboardSummary({
    required this.readinessScore,
    required this.milestonesComplete,
    required this.totalXp,
    required this.level,
    required this.levelLabel,
    required this.radarScores,
    required this.ganttTasks,
    required this.metrics,
  });

  double get xpProgress => (totalXp % 1000) / 1000;

  static const DashboardSummary placeholder = DashboardSummary(
    readinessScore: 62,
    milestonesComplete: 3,
    totalXp: 350,
    level: 2,
    levelLabel: 'Emerging Business',
    radarScores: [
      RadarScore(axis: 'Finance',      current: 0.45, target: 0.80),
      RadarScore(axis: 'Digital',      current: 0.72, target: 0.90),
      RadarScore(axis: 'Supply Chain', current: 0.55, target: 0.80),
      RadarScore(axis: 'Operations',   current: 0.60, target: 0.85),
      RadarScore(axis: 'Compliance',   current: 0.38, target: 0.75),
    ],
    ganttTasks: GanttTask.defaults,
    metrics: MetricTile.defaults,
  );
}
