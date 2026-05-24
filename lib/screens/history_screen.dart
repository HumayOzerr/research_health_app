import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/health_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/fade_slide_in.dart';

typedef _Pt = ({DateTime date, double value});

class _Series {
  final List<_Pt> data;
  final Color color;
  final bool dashed;
  const _Series({required this.data, required this.color, this.dashed = false});
}

// ─── Main screen ─────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  final HealthService healthService;
  final bool healthGranted;

  const HistoryScreen({
    super.key,
    required this.healthService,
    required this.healthGranted,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  List<({DateTime date, int steps})> _liveSteps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final currentId = await SupabaseService().getParticipantId();
    final all = await StorageService().getHistory();
    final h = currentId == null
        ? all
        : all.where((e) {
            final pid = ((e['data'] as Map?)?['participant'] as Map?)?['id'] as String?;
            return pid == currentId;
          }).toList();
    List<({DateTime date, int steps})> ls = [];
    if (widget.healthGranted) ls = await widget.healthService.getLast7DaysSteps();
    if (mounted) setState(() { _history = h; _liveSteps = ls; _loading = false; });
  }

  List<_Pt> _survey(double? Function(Map? sr) fn) {
    final out = <_Pt>[];
    for (final e in _history.reversed) {
      final data = e['data'] as Map?;
      final rawTs = (data?['submission'] as Map?)?['timestamp_utc'] as String?;
      final ts = rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null;
      if (ts == null) continue;
      final v = fn(data?['self_report'] as Map?);
      if (v != null) out.add((date: ts, value: v));
    }
    return out;
  }

  List<_Pt> _metric(String type) {
    final out = <_Pt>[];
    for (final e in _history.reversed) {
      final data = e['data'] as Map?;
      final rawTs = (data?['submission'] as Map?)?['timestamp_utc'] as String?;
      final ts = rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null;
      if (ts == null) continue;
      for (final m in (data?['health_metrics'] as List?) ?? []) {
        if ((m as Map)['type'] == type) {
          final v = (m['value'] as num?)?.toDouble();
          if (v != null) out.add((date: ts, value: v));
          break;
        }
      }
    }
    return out;
  }

  bool get _hasMenstrual => _history.any(
      (e) => ((e['data'] as Map?)?['self_report'] as Map?)?['menstrual_status'] != null);

  Map<String, bool?> get _menstrualDays {
    final map = <String, bool?>{};
    for (final e in _history) {
      final data = e['data'] as Map?;
      final rawTs = (data?['submission'] as Map?)?['timestamp_utc'] as String?;
      final ts = rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null;
      if (ts == null) continue;
      final m = (data?['self_report'] as Map?)?['menstrual_status'] as Map?;
      if (m == null) continue;
      final k = '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
      map[k] = m['on_period'] as bool?;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    if (_history.isEmpty && _liveSteps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: AppBarTitle(l.historyTitle)),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history_rounded, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(l.noSubmissionsYet, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ),
      );
    }

    final wellbeing = _survey((sr) => ((sr?['wellbeing_rating'] as Map?)?['value'] as int?)?.toDouble());
    final sleepQ    = _survey((sr) => ((sr?['sleep_quality'] as Map?)?['value'] as int?)?.toDouble());
    final neuro     = _survey((sr) => (((sr?['pain'] as Map?)?['neuropathic'] as Map?)?['value'] as int?)?.toDouble());
    final musculo   = _survey((sr) => (((sr?['pain'] as Map?)?['musculoskeletal'] as Map?)?['value'] as int?)?.toDouble());
    final weight    = _survey((sr) => (sr?['weight_kg'] as num?)?.toDouble());
    final bmi       = _survey((sr) => (sr?['bmi'] as num?)?.toDouble());
    final hr        = _metric('heart_rate');
    final restHr    = _metric('resting_heart_rate');
    final sleepH    = _metric('sleep_duration');
    final dist      = _metric('distance_walking_running');
    final flights   = _metric('flights_climbed');
    final speed     = _metric('walking_speed');
    final energy    = _metric('active_energy_burned');

    const c1 = Color(0xFF5C6BC0);
    const cNeuro = Color(0xFFEF6C00);
    const cMusculo = Color(0xFFE53935);
    const cHr = Color(0xFFE53935);
    const cRestHr = Color(0xFFEC407A);
    const cSleep = Color(0xFF5C6BC0);
    const cEnergy = Color(0xFFF57C00);
    const cSpeed = Color(0xFF8E24AA);
    const cDist = Color(0xFF43A047);
    const cFlights = Color(0xFF1E88E5);
    const cSteps = Color(0xFF00897B);

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(l.historyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [

          // ── Wellbeing & Sleep Quality ─────────────────────────────────────
          if (wellbeing.isNotEmpty || sleepQ.isNotEmpty) ...[
            FadeSlideIn(
              child: _ChartCard(
                icon: Icons.self_improvement_rounded,
                title: l.chartWellbeingSleep,
                color: cs.primary,
                legend: [
                  if (wellbeing.isNotEmpty) _LegendDot(color: cs.primary, label: l.wellbeing),
                  if (sleepQ.isNotEmpty) _LegendDot(color: c1, label: l.sleepQuality, dashed: true),
                ],
                child: _MultiLineChart(
                  series: [
                    if (wellbeing.isNotEmpty) _Series(data: wellbeing, color: cs.primary),
                    if (sleepQ.isNotEmpty) const _Series(data: [], color: c1, dashed: true),
                  ].where((s) => s.data.isNotEmpty).toList()
                    ..addAll(sleepQ.isNotEmpty ? [_Series(data: sleepQ, color: c1, dashed: true)] : []),
                  minY: 0, maxY: 5, yInterval: 1, unit: '/5',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Pain ─────────────────────────────────────────────────────────
          if (neuro.isNotEmpty || musculo.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 40),
              child: _ChartCard(
                icon: Icons.electric_bolt_rounded,
                title: l.chartPainLevels,
                color: cNeuro,
                legend: [
                  if (neuro.isNotEmpty) _LegendDot(color: cNeuro, label: l.legendNeuropathic),
                  if (musculo.isNotEmpty) _LegendDot(color: cMusculo, label: l.legendMusculoskeletal, dashed: true),
                ],
                child: _MultiLineChart(
                  series: [
                    if (neuro.isNotEmpty) _Series(data: neuro, color: cNeuro),
                    if (musculo.isNotEmpty) _Series(data: musculo, color: cMusculo, dashed: true),
                  ],
                  minY: 0, maxY: 10, yInterval: 2, unit: '/10',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Steps (7-day live) ────────────────────────────────────────────
          if (_liveSteps.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _ChartCard(
                icon: Icons.directions_walk_rounded,
                title: l.stepActivity,
                color: cSteps,
                child: _StepBarChart(data: _liveSteps, color: cSteps),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Heart Rate ────────────────────────────────────────────────────
          if (hr.isNotEmpty || restHr.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _ChartCard(
                icon: Icons.favorite_rounded,
                title: l.labelHeartRate,
                color: cHr,
                legend: [
                  if (hr.isNotEmpty) _LegendDot(color: cHr, label: l.legendActive),
                  if (restHr.isNotEmpty) _LegendDot(color: cRestHr, label: l.legendResting, dashed: true),
                ],
                child: _MultiLineChart(
                  series: [
                    if (hr.isNotEmpty) _Series(data: hr, color: cHr),
                    if (restHr.isNotEmpty) _Series(data: restHr, color: cRestHr, dashed: true),
                  ],
                  unit: ' bpm',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Sleep Hours ───────────────────────────────────────────────────
          if (sleepH.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: _ChartCard(
                icon: Icons.nights_stay_rounded,
                title: l.labelSleep,
                color: cSleep,
                child: _SingleBarChart(data: sleepH, color: cSleep, unit: 'h', maxY: 10),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Active Energy ─────────────────────────────────────────────────
          if (energy.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: _ChartCard(
                icon: Icons.local_fire_department_rounded,
                title: l.labelActiveEnergy,
                color: cEnergy,
                child: _SingleBarChart(data: energy, color: cEnergy, unit: 'kcal'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Walking Speed ─────────────────────────────────────────────────
          if (speed.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _ChartCard(
                icon: Icons.speed_rounded,
                title: l.labelWalkingSpeed,
                color: cSpeed,
                child: _MultiLineChart(
                  series: [_Series(data: speed, color: cSpeed)],
                  unit: ' km/h',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Distance ──────────────────────────────────────────────────────
          if (dist.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 130),
              child: _ChartCard(
                icon: Icons.route_rounded,
                title: l.labelDistance,
                color: cDist,
                child: _MultiLineChart(
                  series: [_Series(data: dist, color: cDist)],
                  unit: ' km',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Weight ───────────────────────────────────────────────────────
          if (weight.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 155),
              child: _ChartCard(
                icon: Icons.monitor_weight_outlined,
                title: l.labelWeight,
                color: const Color(0xFF6D4C41),
                child: _SingleLineChart(
                  data: weight,
                  color: const Color(0xFF6D4C41),
                  unit: ' kg',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── BMI ───────────────────────────────────────────────────────────
          if (bmi.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 158),
              child: _ChartCard(
                icon: Icons.calculate_outlined,
                title: l.bmiTitle,
                color: const Color(0xFF43A047),
                child: _BmiBarChart(data: bmi, l: l),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Flights Climbed ───────────────────────────────────────────────
          if (flights.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: _ChartCard(
                icon: Icons.stairs_rounded,
                title: l.labelFlightsClimbed,
                color: cFlights,
                child: _SingleBarChart(data: flights, color: cFlights, unit: 'fl'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Menstrual ──────────────────────────────────────────────────────
          if (_hasMenstrual) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: _ChartCard(
                icon: Icons.water_drop_rounded,
                title: l.menstrualActivity,
                color: const Color(0xFFB71C1C),
                child: _MenstrualStrip(days: _menstrualDays),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Submissions ────────────────────────────────────────────────────
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 4),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Text(AppLocalizations.of(context).pastSubmissionsHeader,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ..._history.asMap().entries.map((e) => FadeSlideIn(
                  delay: Duration(milliseconds: 180 + e.key * 30),
                  child: _SubmissionCard(entry: e.value),
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Chart card wrapper ───────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  final List<Widget> legend;

  const _ChartCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
    this.legend = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (legend.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: legend.expand((w) => [w, const SizedBox(width: 16)]).toList()..removeLast()),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Legend dot ──────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendDot({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          Row(children: List.generate(3, (i) => Container(
            width: 4, height: 2, margin: const EdgeInsets.only(right: 2),
            color: color,
          )))
        else
          Container(width: 12, height: 3, decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2),
          )),
        const SizedBox(width: 6),
        Text(label, style: tt.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Multi-line chart ─────────────────────────────────────────────────────────

class _MultiLineChart extends StatelessWidget {
  final List<_Series> series;
  final double? minY;
  final double? maxY;
  final double? yInterval;
  final String? unit;

  const _MultiLineChart({
    required this.series,
    this.minY,
    this.maxY,
    this.yInterval,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final allPts = series.expand((s) => s.data).toList();
    if (allPts.isEmpty) return const SizedBox(height: 160);

    double actualMin = minY ?? allPts.map((p) => p.value).reduce(math.min);
    double actualMax = maxY ?? (allPts.map((p) => p.value).reduce(math.max) * 1.2);
    if (actualMin == actualMax) actualMax = actualMin + 1;

    final primaryDates = series.reduce((a, b) => a.data.length >= b.data.length ? a : b).data.map((p) => p.date).toList();
    final count = primaryDates.length;
    final showEvery = count <= 4 ? 1 : count <= 8 ? 2 : 3;

    final bars = series.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      final spots = s.data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList();
      return LineChartBarData(
        spots: spots,
        color: s.color,
        barWidth: 2.5,
        isCurved: true,
        curveSmoothness: 0.3,
        preventCurveOverShooting: true,
        dashArray: s.dashed ? [5, 4] : null,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, pct, data, idx) => FlDotCirclePainter(
            radius: 4,
            color: s.color,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: i == 0
            ? BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [s.color.withValues(alpha: 0.18), s.color.withValues(alpha: 0)],
                ),
              )
            : BarAreaData(show: false),
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: actualMin,
          maxY: actualMax,
          lineBarsData: bars,
          clipData: const FlClipData.all(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= primaryDates.length) return const SizedBox();
                  if (idx % showEvery != 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('d/M').format(primaryDates[idx]),
                        style: tt.labelSmall?.copyWith(fontSize: 9)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: yInterval ?? ((actualMax - actualMin) / 4),
                getTitlesWidget: (v, meta) {
                  if (v == actualMin || v == actualMax) return const SizedBox();
                  return Text(
                    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1),
                    style: tt.labelSmall?.copyWith(fontSize: 9, color: cs.onSurfaceVariant),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval ?? ((actualMax - actualMin) / 4),
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => cs.inverseSurface,
              getTooltipItems: (spots) => spots.map((s) {
                final si = s.barIndex;
                final idx = s.spotIndex;
                String date = '';
                if (si < series.length && idx < series[si].data.length) {
                  date = '\n${DateFormat('d MMM').format(series[si].data[idx].date)}';
                }
                final val = s.y == s.y.roundToDouble()
                    ? s.y.round().toString()
                    : s.y.toStringAsFixed(1);
                return LineTooltipItem(
                  '$val${unit ?? ''}$date',
                  TextStyle(
                    color: cs.onInverseSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Single bar chart (for submissions data) ──────────────────────────────────

class _SingleBarChart extends StatelessWidget {
  final List<_Pt> data;
  final Color color;
  final String? unit;
  final double? maxY;

  const _SingleBarChart({required this.data, required this.color, this.unit, this.maxY});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final vals = data.map((p) => p.value);
    final actualMax = maxY ?? (vals.isEmpty ? 10.0 : vals.reduce(math.max) * 1.3);
    final barW = (260.0 / math.max(data.length, 1)).clamp(10.0, 36.0);

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: actualMax,
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withValues(alpha: 0.75)],
                  ),
                  width: barW,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: actualMax,
                    color: color.withValues(alpha: 0.07),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('d/M').format(data[idx].date),
                        style: tt.labelSmall?.copyWith(fontSize: 9)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => cs.inverseSurface,
              getTooltipItem: (group, gi, rod, ri) {
                final v = rod.toY;
                final str = v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
                return BarTooltipItem(
                  '$str${unit != null ? ' $unit' : ''}\n${DateFormat('d MMM').format(data[gi].date)}',
                  TextStyle(color: cs.onInverseSurface, fontSize: 11),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step bar chart (7-day live from HealthService) ──────────────────────────

class _StepBarChart extends StatelessWidget {
  final List<({DateTime date, int steps})> data;
  final Color color;

  const _StepBarChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxSteps = data.isEmpty ? 10000 : data.map((e) => e.steps).reduce(math.max);
    final maxY = (maxSteps * 1.25).clamp(1000, double.infinity).toDouble();

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.steps.toDouble(),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: color.withValues(alpha: 0.07),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('E').format(data[idx].date),
                        style: tt.labelSmall),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => cs.inverseSurface,
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${rod.toY.toInt()} steps',
                TextStyle(color: cs.onInverseSurface, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Single line chart (convenience wrapper) ──────────────────────────────────

class _SingleLineChart extends StatelessWidget {
  final List<_Pt> data;
  final Color color;
  final String? unit;

  const _SingleLineChart({required this.data, required this.color, this.unit});

  @override
  Widget build(BuildContext context) => _MultiLineChart(
        series: [_Series(data: data, color: color)],
        unit: unit,
      );
}

// ─── BMI bar chart ────────────────────────────────────────────────────────────

class _BmiBarChart extends StatelessWidget {
  final List<_Pt> data;
  final AppLocalizations l;

  const _BmiBarChart({required this.data, required this.l});

  static Color _barColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF1E88E5);
    if (bmi < 25.0) return const Color(0xFF43A047);
    if (bmi < 30.0) return const Color(0xFFF9A825);
    if (bmi < 40.0) return const Color(0xFFEF6C00);
    return const Color(0xFFB71C1C);
  }

  String _category(double bmi) {
    if (bmi < 18.5) return l.bmiUnderweight;
    if (bmi < 25.0) return l.bmiHealthy;
    if (bmi < 30.0) return l.bmiOverweight;
    if (bmi < 40.0) return l.bmiObese;
    return l.bmiMorbidlyObese;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxBmi = data.map((p) => p.value).reduce(math.max);
    final maxY = math.max(maxBmi * 1.15, 45.0);
    final barW = (260.0 / math.max(data.length, 1)).clamp(10.0, 36.0);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 10,
          maxY: maxY,
          barGroups: data.asMap().entries.map((e) {
            final bmi = e.value.value;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  fromY: 10,
                  toY: bmi,
                  color: _barColor(bmi),
                  width: barW,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    fromY: 10,
                    toY: maxY,
                    color: cs.outlineVariant.withValues(alpha: 0.08),
                  ),
                ),
              ],
            );
          }).toList(),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 18.5,
                color: const Color(0xFF1E88E5).withValues(alpha: 0.5),
                strokeWidth: 1.5,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => l.bmiUnderweight,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF1E88E5), fontWeight: FontWeight.w600),
                ),
              ),
              HorizontalLine(
                y: 25,
                color: const Color(0xFFF9A825).withValues(alpha: 0.5),
                strokeWidth: 1.5,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => l.bmiOverweight,
                  style: const TextStyle(fontSize: 9, color: Color(0xFFF9A825), fontWeight: FontWeight.w600),
                ),
              ),
              HorizontalLine(
                y: 30,
                color: const Color(0xFFEF6C00).withValues(alpha: 0.5),
                strokeWidth: 1.5,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => l.bmiObese,
                  style: const TextStyle(fontSize: 9, color: Color(0xFFEF6C00), fontWeight: FontWeight.w600),
                ),
              ),
              HorizontalLine(
                y: 40,
                color: const Color(0xFFB71C1C).withValues(alpha: 0.5),
                strokeWidth: 1.5,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => l.bmiMorbidlyObese,
                  style: const TextStyle(fontSize: 9, color: Color(0xFFB71C1C), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('d/M').format(data[idx].date),
                        style: tt.labelSmall?.copyWith(fontSize: 9)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (v, meta) {
                  if (v == 10 || v == maxY) return const SizedBox();
                  return Text(v.round().toString(),
                      style: tt.labelSmall?.copyWith(fontSize: 9, color: cs.onSurfaceVariant));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.25),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => cs.inverseSurface,
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)} kg/m²\n${_category(rod.toY)}\n${DateFormat('d MMM').format(data[gi].date)}',
                TextStyle(color: cs.onInverseSurface, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Menstrual strip ──────────────────────────────────────────────────────────

class _MenstrualStrip extends StatelessWidget {
  final Map<String, bool?> days;
  const _MenstrualStrip({required this.days});

  static const _red = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = today.subtract(Duration(days: 6 - i));
        final k = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final onPeriod = days[k];
        final isToday = i == 6;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('E').format(day),
                style: tt.labelSmall?.copyWith(
                  color: isToday ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                )),
            const SizedBox(height: 2),
            Text('${day.day}',
                style: tt.labelSmall?.copyWith(
                  color: isToday ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                )),
            const SizedBox(height: 8),
            if (onPeriod == true)
              const Icon(Icons.water_drop, color: _red, size: 22)
            else if (onPeriod == false)
              Icon(Icons.circle_outlined, color: cs.outlineVariant, size: 20)
            else
              Icon(Icons.remove, color: cs.outlineVariant, size: 20),
          ],
        );
      }),
    );
  }
}

// ─── Submission card ──────────────────────────────────────────────────────────

class _SubmissionCard extends StatefulWidget {
  final Map<String, dynamic> entry;
  const _SubmissionCard({required this.entry});

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  bool _expanded = false;
  bool _showJson = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    final status      = widget.entry['status'] as String;
    final data        = widget.entry['data'] as Map<String, dynamic>;
    final submission  = data['submission'] as Map<String, dynamic>?;
    final participant = data['participant'] as Map<String, dynamic>?;
    final selfReport  = data['self_report'] as Map<String, dynamic>?;

    final wellbeing = ((selfReport?['wellbeing_rating'] as Map?)?['value'] as int?);
    final sleepVal  = ((selfReport?['sleep_quality'] as Map?)?['value'] as int?);
    final neuro     = (((selfReport?['pain'] as Map?)?['neuropathic'] as Map?)?['value'] as int?);
    final musculo   = (((selfReport?['pain'] as Map?)?['musculoskeletal'] as Map?)?['value'] as int?);
    final comment   = selfReport?['comment'] as String?;
    final weightKg  = (selfReport?['weight_kg'] as num?)?.toDouble();
    final bmiVal    = (selfReport?['bmi'] as num?)?.toDouble();
    final menstrual = selfReport?['menstrual_status'] as Map?;
    final onPeriod  = menstrual?['on_period'] as bool?;
    final cycleDay  = menstrual?['cycle_day'] as int?;
    final cyclePhase = menstrual?['cycle_phase'] as String?;

    final metrics = (data['health_metrics'] as List?) ?? [];
    final metricMap = <String, num>{};
    for (final m in metrics) {
      final type = (m as Map)['type'] as String?;
      final val = m['value'] as num?;
      if (type != null && val != null) metricMap[type] = val;
    }

    final rawTs = submission?['timestamp_utc'] as String?;
    final timestamp = rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null;
    final dateStr = timestamp != null ? DateFormat('d MMM yyyy, HH:mm').format(timestamp) : '—';

    final isPending = status == 'pending';
    final statusColor = isPending ? cs.error : Colors.green;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() { _expanded = !_expanded; if (!_expanded) _showJson = false; }),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(dateStr,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                  if (onPeriod == true) ...[
                    const Icon(Icons.water_drop, color: Color(0xFFB71C1C), size: 16),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(isPending ? l.statusPending : l.statusSubmitted,
                        style: tt.labelSmall?.copyWith(
                            color: statusColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(children: [
                _Chip('ID: ${participant?['id'] ?? '—'}'),
                const SizedBox(width: 6),
                if (wellbeing != null) _Chip('${l.labelRating}: $wellbeing/5'),
              ]),

              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (!_showJson) ...[
                  if (wellbeing != null)
                    _DetailRow(Icons.mood_rounded, l.wellbeingRating, '$wellbeing / 5'),
                  if (sleepVal != null)
                    _DetailRow(Icons.bedtime_rounded, l.sleepQuality, '$sleepVal / 5'),
                  if (neuro != null)
                    _DetailRow(Icons.electric_bolt_rounded, l.neuropathicPain, '$neuro / 10'),
                  if (musculo != null)
                    _DetailRow(Icons.accessibility_new_rounded, l.musculoskeletalPain, '$musculo / 10'),
                  if (weightKg != null)
                    _DetailRow(Icons.monitor_weight_outlined, l.labelWeight, '${weightKg.toStringAsFixed(1)} kg'),
                  if (bmiVal != null)
                    _DetailRow(Icons.calculate_outlined, l.labelBmi, '${bmiVal.toStringAsFixed(1)} kg/m²'),

                  if (metricMap['step_count'] != null)
                    _DetailRow(Icons.directions_walk_rounded, l.labelStepsToday, '${metricMap['step_count']} steps'),
                  if (metricMap['heart_rate'] != null)
                    _DetailRow(Icons.favorite_rounded, l.labelHeartRate, '${metricMap['heart_rate']} bpm'),
                  if (metricMap['resting_heart_rate'] != null)
                    _DetailRow(Icons.favorite_border_rounded, l.labelRestingHeartRate, '${metricMap['resting_heart_rate']} bpm'),
                  if (metricMap['sleep_duration'] != null)
                    _DetailRow(Icons.nights_stay_rounded, l.labelSleep, '${(metricMap['sleep_duration']! as double).toStringAsFixed(1)} h'),
                  if (metricMap['active_energy_burned'] != null)
                    _DetailRow(Icons.local_fire_department_rounded, l.labelActiveEnergy, '${metricMap['active_energy_burned']} kcal'),
                  if (metricMap['walking_speed'] != null)
                    _DetailRow(Icons.speed_rounded, l.labelWalkingSpeed, '${(metricMap['walking_speed']! as double).toStringAsFixed(1)} km/h'),
                  if (metricMap['distance_walking_running'] != null)
                    _DetailRow(Icons.route_rounded, l.labelDistance, '${(metricMap['distance_walking_running']! as double).toStringAsFixed(2)} km'),
                  if (metricMap['flights_climbed'] != null)
                    _DetailRow(Icons.stairs_rounded, l.labelFlightsClimbed, '${metricMap['flights_climbed']}'),

                  if (menstrual != null) ...[
                    const SizedBox(height: 4),
                    _DetailRow(Icons.water_drop_rounded, l.menstrualHealth,
                        onPeriod == true ? l.yes : l.no,
                        valueColor: onPeriod == true ? const Color(0xFFB71C1C) : null),
                    if (cycleDay != null)
                      _DetailRow(Icons.calendar_today_rounded, l.cycleDay, '$cycleDay'),
                    if (cyclePhase != null)
                      _DetailRow(Icons.auto_awesome_rounded, 'Phase', _phaseLabel(cyclePhase, l)),
                  ],

                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 15, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(child: Text(comment,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
                    ]),
                  ],

                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _showJson = true),
                    icon: const Icon(Icons.data_object_rounded, size: 16),
                    label: Text(l.jsonPayload),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ] else ...[
                  Row(children: [
                    Expanded(child: Text(l.jsonPayload,
                        style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: l.copyToClipboard,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jsonStr));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(l.copied),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ));
                      },
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showJson = false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Icon(Icons.list_rounded, size: 18),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(jsonStr,
                        style: tt.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 11)),
                  ),
                ],
              ],

              Align(
                alignment: Alignment.centerRight,
                child: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _phaseLabel(String phase, AppLocalizations l) => switch (phase) {
        'menstrual'  => l.phaseMenstrual,
        'follicular' => l.phaseFollicular,
        'ovulatory'  => l.phaseOvulatory,
        _            => l.phaseLuteal,
      };
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        Icon(icon, size: 15, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
        Text(value, style: tt.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: valueColor ?? cs.onSurface,
        )),
      ]),
    );
  }
}
