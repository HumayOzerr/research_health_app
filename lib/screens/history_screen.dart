import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

// ── Step chart ──────────────────────────────────────────────────────────────

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

// ── Submission card ──────────────────────────────────────────────────────────

class _SubmissionCard extends StatefulWidget {
  final Map<String, dynamic> entry;

  const _SubmissionCard({required this.entry});

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  bool _expanded = false;

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
    final rating = (selfReport?['wellbeing_rating'] as Map<String, dynamic>?)?['value'];

    final rawTs = submission?['timestamp_utc'] as String?;
    final timestamp = rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null;
    final dateStr = timestamp != null
        ? DateFormat('d MMM yyyy, HH:mm').format(timestamp)
        : '—';

    final isPending = status == 'pending';
    final statusColor = isPending ? cs.error : Colors.green;
    final statusLabel = isPending ? l.statusPending : l.statusSubmitted;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
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
                  if ((selfReport?['menstrual_status'] as Map?)?['on_period'] == true) ...[
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
                  if (rating != null) _Chip('${l.labelRating}: $rating/5'),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(l.jsonPayload,
                    style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(data),
                    style: tt.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
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
