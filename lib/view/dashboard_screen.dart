// lib/view/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controller/survey_controller.dart';
import '../model/dashboard_model.dart';
import '../model/app_theme.dart';
import 'action_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveyCtrl = ref.read(surveyControllerProvider.notifier);
    final summary    = surveyCtrl.dashboardSummary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(summary),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero card
                _NextBestActionCard(summary: summary),
                const SizedBox(height: 20),
                _sectionLabel('At a Glance'),
                const SizedBox(height: 12),
                _QuickStatsRow(summary: summary),
                const SizedBox(height: 20),
                _sectionLabel('Key Metrics'),
                const SizedBox(height: 12),
                _MetricsScrollRow(metrics: summary.metrics),
                const SizedBox(height: 20),
                _sectionLabel('Readiness Radar'),
                const SizedBox(height: 12),
                _RadarCard(scores: summary.radarScores),
                const SizedBox(height: 20),
                _sectionLabel('4-Week Sprint'),
                const SizedBox(height: 12),
                _GanttCard(tasks: summary.ganttTasks),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(DashboardSummary summary) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      floating: true,
      elevation: 0,
      expandedHeight: 130,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Good morning,',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
              const Text('Ahmad Razif 👋',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.3)),
              const SizedBox(height: 8),
              // Wrap in FittedBox so the badge never overflows on small screens
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Text(
                    '⭐ Readiness Score: ${summary.readinessScore}/100 · Growing',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

Widget _sectionLabel(String label) => Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.2),
    );

// ─── Hero "Next Best Action" Card ────────────────────────────────────────────

class _NextBestActionCard extends StatelessWidget {
  final DashboardSummary summary;
  const _NextBestActionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'next-best-action',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActionDetailScreen()),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: AppTheme.radiusXl,
              boxShadow: AppTheme.greenGlow(0.3),
            ),
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Positioned(
                  right: -40, top: -40,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: const Text("TODAY'S WORKOUT",
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(10)),
                          child: const Text('+50 XP', style: TextStyle(color: Color(0xFF7C2D12), fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Upload 3 months of receipts to unlock your Credit Profile',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Unlocks 3 micro-financing options and strengthens your Compliance score.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusSm),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Start Now', style: TextStyle(color: AppTheme.green, fontSize: 13, fontWeight: FontWeight.w700)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_outward_rounded, color: AppTheme.green, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Stats ──────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final DashboardSummary summary;
  const _QuickStatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('📦', '${summary.milestonesComplete}', 'Milestones Done', '↑ 1 this week', AppTheme.green),
      ('🌐', '${summary.readinessScore}%', 'Digital Readiness', '↑ 8% this month', AppTheme.blue),
    ];
    return Row(
      children: stats.asMap().entries.map((e) {
        final s = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key == 0 ? 8 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 8),
                Text(s.$2, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                Text(s.$3, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(s.$4, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: s.$5)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Scrollable Metrics ───────────────────────────────────────────────────────

class _MetricsScrollRow extends StatelessWidget {
  final List<MetricTile> metrics;
  const _MetricsScrollRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 130 gives enough room for icon + value + label + trend without overflow
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Prevent the horizontal list from intercepting vertical scroll
        physics: const ClampingScrollPhysics(),
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m = metrics[i];
          return Container(
            width: 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.radiusLg,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Use mainAxisSize.min + no Spacer so content doesn't overflow
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(m.value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                Text(m.label,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(m.trend,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: m.isPositive ? AppTheme.green : AppTheme.blue)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Radar Chart Card ─────────────────────────────────────────────────────────

class _RadarCard extends StatelessWidget {
  final List<RadarScore> scores;
  const _RadarCard({required this.scores});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('5-axis business health overview',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  // Target polygon (dashed appearance via low opacity)
                  RadarDataSet(
                    fillColor: AppTheme.blue.withOpacity(0.08),
                    borderColor: AppTheme.blue.withOpacity(0.7),
                    borderWidth: 1.5,
                    entryRadius: 3,
                    dataEntries: scores.map((s) => RadarEntry(value: s.target * 100)).toList(),
                  ),
                  // Current polygon
                  RadarDataSet(
                    fillColor: AppTheme.green.withOpacity(0.2),
                    borderColor: AppTheme.green,
                    borderWidth: 2.5,
                    entryRadius: 5,
                    dataEntries: scores.map((s) => RadarEntry(value: s.current * 100)).toList(),
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: AppTheme.border, width: 1),
                gridBorderData: const BorderSide(color: AppTheme.border, width: 1),
                tickCount: 4,
                ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
                tickBorderData: const BorderSide(color: Colors.transparent),
                getTitle: (index, angle) => RadarChartTitle(
                  text: scores[index].axis,
                  angle: 0,
                  positionPercentageOffset: 0.15,
                ),
                titleTextStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              _legendItem(AppTheme.green, AppTheme.green.withOpacity(0.2), 'Current'),
              const SizedBox(width: 16),
              _legendItem(AppTheme.blue, AppTheme.blue.withOpacity(0.08), 'Target'),
            ],
          ),
          const SizedBox(height: 12),
          // Score pills
          Wrap(
            spacing: 8, runSpacing: 8,
            children: scores.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.greenPale, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${s.axis.replaceAll('\n', ' ')}: ${s.currentPct}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.green),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color border, Color fill, String label) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: Border.all(color: border, width: 2)),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
      ],
    );
  }
}

// ─── Gantt Card ───────────────────────────────────────────────────────────────

class _GanttCard extends StatelessWidget {
  final List<GanttTask> tasks;
  const _GanttCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your personalised action timeline',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 14),
          // Week headers
          Padding(
            padding: const EdgeInsets.only(left: 82),
            child: Row(
              children: List.generate(4, (i) => Expanded(
                child: Text('WK ${i + 1}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
              )),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (ctx, constraints) {
            final trackWidth = constraints.maxWidth - 82;
            return Column(
              children: tasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(t.label,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                          maxLines: 2),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: trackWidth,
                      height: 28,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Positioned(
                            left: t.startFraction * trackWidth,
                            child: Container(
                              width: t.widthFraction * trackWidth,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Color(t.colorHex),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                t.text,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
      ),
                    ),
                  ],
                ),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }
}