import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/health_service.dart';
import '../services/storage_service.dart';
import '../widgets/fade_slide_in.dart';

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
  List<({DateTime date, int steps})> _stepData = [];
  bool _loadingHistory = true;
  bool _loadingChart = true;

  bool get _hasMenstrualData => _history.any((e) {
        final sr = (e['data'] as Map?)?['self_report'] as Map?;
        return sr?['menstrual_status'] != null;
      });

  Map<String, bool?> get _menstrualDays {
    final map = <String, bool?>{};
    for (final entry in _history) {
      final data = entry['data'] as Map<String, dynamic>?;
      final submission = data?['submission'] as Map<String, dynamic>?;
      final selfReport = data?['self_report'] as Map<String, dynamic>?;
      final menstrual = selfReport?['menstrual_status'] as Map?;
      if (menstrual == null) continue;
      final rawTs = submission?['timestamp_utc'] as String?;
      if (rawTs == null) continue;
      final ts = DateTime.tryParse(rawTs)?.toLocal();
      if (ts == null) continue;
      final key =
          '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
      map[key] = menstrual['on_period'] as bool?;
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadStepChart();
  }

  Future<void> _loadHistory() async {
    final history = await StorageService().getHistory();
    if (mounted) setState(() { _history = history; _loadingHistory = false; });
  }

  Future<void> _loadStepChart() async {
    if (widget.healthGranted) {
      final data = await widget.healthService.getLast7DaysSteps();
      if (mounted) setState(() => _stepData = data);
    }
    if (mounted) setState(() => _loadingChart = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.historyTitle)),
      body: _loadingHistory
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty && _stepData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text(l.noSubmissionsYet,
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!_loadingChart && widget.healthGranted) ...[
                      FadeSlideIn(
                        child: Text(l.stepActivity,
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: _StepChart(stepData: _stepData, color: cs.primary),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_hasMenstrualData) ...[
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: Text(l.menstrualActivity,
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: _MenstrualStrip(days: _menstrualDays),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_history.isNotEmpty) ...[
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Text(l.pastSubmissionsHeader,
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      ..._history.asMap().entries.map((e) => FadeSlideIn(
                            delay: Duration(milliseconds: 140 + e.key * 40),
                            child: _SubmissionCard(entry: e.value),
                          )),
                    ],
                  ],
                ),
    );
  }
}


class _StepChart extends StatelessWidget {
  final List<({DateTime date, int steps})> stepData;
  final Color color;

  const _StepChart({required this.stepData, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final maxY = stepData.isEmpty
        ? 10000.0
        : (stepData.map((e) => e.steps).reduce((a, b) => a > b ? a : b) * 1.25)
            .clamp(1000.0, double.infinity);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: stepData.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.steps.toDouble(),
                  color: color,
                  width: 26,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= stepData.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('E').format(stepData[idx].date),
                      style: tt.labelSmall,
                    ),
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
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final steps = rod.toY.toInt();
                return BarTooltipItem(
                  '$steps steps',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


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

    final status = widget.entry['status'] as String;
    final data = widget.entry['data'] as Map<String, dynamic>;
    final submission = data['submission'] as Map<String, dynamic>?;
    final participant = data['participant'] as Map<String, dynamic>?;
    final selfReport = data['self_report'] as Map<String, dynamic>?;

    final wellbeing = (selfReport?['wellbeing_rating'] as Map?)?['value'] as int?;
    final sleepVal = (selfReport?['sleep_quality'] as Map?)?['value'] as int?;
    final pain = selfReport?['pain'] as Map?;
    final neuro = (pain?['neuropathic'] as Map?)?['value'] as int?;
    final musculo = (pain?['musculoskeletal'] as Map?)?['value'] as int?;
    final comment = selfReport?['comment'] as String?;
    final menstrual = selfReport?['menstrual_status'] as Map?;
    final onPeriod = menstrual?['on_period'] as bool?;
    final cycleDay = menstrual?['cycle_day'] as int?;
    final cyclePhase = menstrual?['cycle_phase'] as String?;

    final metrics = (data['health_metrics'] as List?) ?? [];
    int? steps;
    int? heartRate;
    double? sleepHours;
    int? activeEnergy;
    for (final m in metrics) {
      switch ((m as Map)['type'] as String?) {
        case 'step_count': steps = m['value'] as int?;
        case 'heart_rate': heartRate = m['value'] as int?;
        case 'sleep_duration': sleepHours = (m['value'] as num?)?.toDouble();
        case 'active_energy_burned': activeEnergy = m['value'] as int?;
      }
    }

    final rawTs = submission?['timestamp_utc'] as String?;
    final timestamp = rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null;
    final dateStr = timestamp != null
        ? DateFormat('d MMM yyyy, HH:mm').format(timestamp)
        : '—';

    final isPending = status == 'pending';
    final statusColor = isPending ? cs.error : Colors.green;
    final statusLabel = isPending ? l.statusPending : l.statusSubmitted;

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _expanded = !_expanded;
          if (!_expanded) _showJson = false;
        }),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(dateStr,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (onPeriod == true) ...[
                    const Icon(Icons.water_drop, color: Color(0xFFB71C1C), size: 18),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: tt.labelSmall?.copyWith(
                            color: statusColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _Chip('ID: ${participant?['id'] ?? '—'}'),
                  const SizedBox(width: 6),
                  if (wellbeing != null) _Chip('${l.labelRating}: $wellbeing/5'),
                ],
              ),

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

                  if (steps != null)
                    _DetailRow(Icons.directions_walk_rounded, l.labelStepsToday, '$steps steps'),
                  if (heartRate != null)
                    _DetailRow(Icons.favorite_rounded, l.labelHeartRate, '$heartRate bpm'),
                  if (sleepHours != null)
                    _DetailRow(Icons.nights_stay_rounded, l.labelSleep, '${sleepHours.toStringAsFixed(1)} h'),
                  if (activeEnergy != null)
                    _DetailRow(Icons.local_fire_department_rounded, l.labelActiveEnergy, '$activeEnergy kcal'),

                  if (menstrual != null) ...[
                    const SizedBox(height: 4),
                    _DetailRow(
                      Icons.water_drop_rounded,
                      l.menstrualHealth,
                      onPeriod == true ? l.yes : l.no,
                      valueColor: onPeriod == true ? const Color(0xFFB71C1C) : null,
                    ),
                    if (cycleDay != null)
                      _DetailRow(Icons.calendar_today_rounded, l.cycleDay, '$cycleDay'),
                    if (cyclePhase != null)
                      _DetailRow(Icons.auto_awesome_rounded, 'Phase', _phaseLabel(cyclePhase, l)),
                  ],

                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(comment,
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                      ],
                    ),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(l.jsonPayload,
                            style: tt.labelMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      jsonStr,
                      style: tt.bodySmall
                          ?.copyWith(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ],

              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
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
        'luteal'     => l.phaseLuteal,
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

class _MenstrualStrip extends StatelessWidget {
  final Map<String, bool?> days;
  const _MenstrualStrip({required this.days});

  static const _periodColor = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (i) {
            final day = today.subtract(Duration(days: 6 - i));
            final key =
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final onPeriod = days[key];
            final isToday = i == 6;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('E').format(day),
                  style: tt.labelSmall?.copyWith(
                    color: isToday ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.day}',
                  style: tt.labelSmall?.copyWith(
                    color: isToday ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                if (onPeriod == true)
                  const Icon(Icons.water_drop, color: _periodColor, size: 22)
                else if (onPeriod == false)
                  Icon(Icons.circle_outlined, color: cs.outlineVariant, size: 20)
                else
                  Icon(Icons.remove, color: cs.outlineVariant, size: 20),
              ],
            );
          }),
        ),
      ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Text(value,
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? cs.onSurface,
              )),
        ],
      ),
    );
  }
}
