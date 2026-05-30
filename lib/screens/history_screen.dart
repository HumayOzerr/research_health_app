import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/health_service.dart';
import '../services/native_health_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/fade_slide_in.dart';

typedef _Pt = ({DateTime date, double value});
typedef _RangePt = ({DateTime date, double avg, double min, double max});

class _Series {
  final List<_Pt> data;
  final Color color;
  final bool dashed;
  const _Series({required this.data, required this.color, this.dashed = false});
}

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
  List<({DateTime date, int steps})> _weekSteps = [];
  Map<String, dynamic> _weekHealth = {};
  Map<String, List<_RangePt>> _weekNative = {};
  bool _loading = true;
  bool _stepsLoading = false;
  bool _healthLoading = false;
  int _weekOffset = 0;
  int? _userHeightCm;

  DateTime get _weekEnd {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.add(Duration(days: _weekOffset * 7));
  }

  DateTime get _weekStart =>
      DateTime(_weekEnd.year, _weekEnd.month, _weekEnd.day - 6);

  List<Map<String, dynamic>> get _filteredHistory {
    final start = _weekStart;
    final end = _weekEnd.add(const Duration(days: 1));
    return _history.where((e) {
      final rawTs = ((e['data'] as Map?)?['submission'] as Map?)?['timestamp_utc'] as String?;
      final ts = rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null;
      if (ts == null) return false;
      return !ts.isBefore(start) && ts.isBefore(end);
    }).toList();
  }

  bool _healthGranted = false;

  @override
  void initState() {
    super.initState();
    _healthGranted = _healthGranted;
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    if (!_healthGranted) {
      final granted = await widget.healthService.checkPermissionSilently();
      if (mounted && granted) setState(() => _healthGranted = true);
    }
    _load();
  }

  Future<void> _load() async {
    final all = await StorageService().getHistory();
    if (mounted) setState(() { _history = all; _loading = false; });
    SupabaseService().getProfile().timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    ).then((profile) {
      if (!mounted) return;
      final currentId = profile?['participant_id'] as String?;
      _userHeightCm = (profile?['height_cm'] as num?)?.toInt();
      if (currentId != null) {
        final filtered = all.where((e) {
          final pid = ((e['data'] as Map?)?['participant'] as Map?)?['id'] as String?;
          return pid == currentId;
        }).toList();
        setState(() => _history = filtered);
      }
    });
    List<({DateTime date, int steps})> steps = [];
    if (_healthGranted) steps = await widget.healthService.getStepsInRange(_weekStart);
    if (mounted) setState(() => _weekSteps = steps);
    _loadWeekHealthData();
  }

  Future<void> _loadWeekSteps() async {
    if (!_healthGranted) return;
    setState(() => _stepsLoading = true);
    final steps = await widget.healthService.getStepsInRange(_weekStart);
    if (mounted) setState(() { _weekSteps = steps; _stepsLoading = false; });
  }

  Future<void> _loadWeekHealthData() async {
    if (!_healthGranted) return;
    if (mounted) setState(() => _healthLoading = true);
    final health = await widget.healthService.getWeeklyMetrics(_weekStart);
    final nativeData = await NativeHealthService().getWeeklyNativeMetrics(_weekStart);
    if (mounted) {
      setState(() {
        _weekHealth = health;
        _weekNative = nativeData;
        _healthLoading = false;
      });
    }
  }

  void _changeWeek(int delta) {
    setState(() => _weekOffset += delta);
    _loadWeekSteps();
    _loadWeekHealthData();
  }

  Future<void> _openDateJump() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _weekEnd.isAfter(today) ? today : _weekEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    final pickedDay = DateTime(picked.year, picked.month, picked.day);
    final diff = today.difference(pickedDay).inDays;
    final newOffset = diff <= 0 ? 0 : -(diff ~/ 7);
    if (newOffset != _weekOffset) {
      HapticFeedback.selectionClick();
      setState(() => _weekOffset = newOffset);
      _loadWeekSteps();
      _loadWeekHealthData();
    }
  }

  List<_Pt> _survey(List<Map<String, dynamic>> src, double? Function(Map? sr) fn) {
    final out = <_Pt>[];
    for (final e in src) {
      final data = e['data'] as Map?;
      final rawTs = (data?['submission'] as Map?)?['timestamp_utc'] as String?;
      final ts = rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null;
      if (ts == null) continue;
      final v = fn(data?['self_report'] as Map?);
      if (v != null) out.add((date: ts, value: v));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  bool _hasMenstrual(List<Map<String, dynamic>> src) => src.any(
      (e) => ((e['data'] as Map?)?['self_report'] as Map?)?['menstrual_status'] != null);

  Map<String, bool?> _getMenstrualDays(List<Map<String, dynamic>> src) {
    final map = <String, bool?>{};
    for (final e in src) {
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

  Widget _buildWeekNav(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final isCurrentWeek = _weekOffset == 0;

    final locale = Localizations.localeOf(context).languageCode;
    final startStr = DateFormat('d MMM', locale).format(_weekStart);
    final endStr   = DateFormat('d MMM yyyy', locale).format(_weekEnd);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _changeWeek(-1),
              icon: const Icon(Icons.chevron_left_rounded),
              color: cs.primary,
            ),
            Expanded(
              child: InkWell(
                onTap: _openDateJump,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 5),
                          Text(
                            '$startStr – $endStr',
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      if (isCurrentWeek) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l.thisWeek,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: isCurrentWeek ? null : () => _changeWeek(1),
              icon: Icon(
                Icons.chevron_right_rounded,
                color: isCurrentWeek ? cs.outlineVariant : cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _HistorySkeletonScreen();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    if (_history.isEmpty && _weekSteps.isEmpty && _weekHealth.isEmpty && _weekNative.isEmpty && !_stepsLoading && !_healthLoading) {
      return Scaffold(
        appBar: AppBar(
          title: AppBarTitle(l.historyTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: l.jumpToDate,
              onPressed: _openDateJump,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildWeekNav(context),
            const SizedBox(height: 64),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.insert_chart_outlined_rounded,
                      size: 48, color: cs.primary.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 20),
                Text(l.noSubmissionsYet,
                    style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 6),
                Text(l.noDataThisWeek,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredHistory;

    final wellbeing = _survey(filtered, (sr) => ((sr?['wellbeing_rating'] as Map?)?['value'] as int?)?.toDouble());
    final sleepQ    = _survey(filtered, (sr) => ((sr?['sleep_quality'] as Map?)?['value'] as int?)?.toDouble());
    final neuro     = _survey(filtered, (sr) => (((sr?['pain'] as Map?)?['neuropathic'] as Map?)?['value'] as int?)?.toDouble());
    final musculo   = _survey(filtered, (sr) => (((sr?['pain'] as Map?)?['musculoskeletal'] as Map?)?['value'] as int?)?.toDouble());
    final glucose   = _survey(filtered, (sr) => (sr?['blood_glucose_mgdl'] as num?)?.toDouble());
    final weight    = _survey(filtered, (sr) => (sr?['weight_kg'] as num?)?.toDouble());
    final bmi       = _survey(filtered, (sr) {
      final saved = (sr?['bmi'] as num?)?.toDouble();
      if (saved != null) return saved;
      final w = (sr?['weight_kg'] as num?)?.toDouble();
      final h = _userHeightCm;
      if (w == null || h == null) return null;
      final hm = h / 100.0;
      return w / (hm * hm);
    });
    final hr         = (_weekHealth['hr']      as List<_Pt>?) ?? <_Pt>[];
    final restHr     = (_weekHealth['restHr']  as List<_Pt>?) ?? <_Pt>[];
    final sleepH     = (_weekHealth['sleep']   as List<_Pt>?) ?? <_Pt>[];
    final dist       = (_weekHealth['dist']    as List<_Pt>?) ?? <_Pt>[];
    final flights    = (_weekHealth['flights'] as List<_Pt>?) ?? <_Pt>[];
    final energy     = (_weekHealth['energy']  as List<_Pt>?) ?? <_Pt>[];
    final speedRange = (_weekHealth['speed']   as List<_RangePt>?) ?? <_RangePt>[];

    const cGlucose = Color(0xFFD81B60);
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
    const cStepLen = Color(0xFF00897B);
    const cAsym = Color(0xFFAB47BC);
    const cDblSupport = Color(0xFF3949AB);
    const cHeadphone = Color(0xFFFF7043);

        final stepLenRange   = (_weekNative['stepLen'] ?? <_RangePt>[])
        .map((p) => (date: p.date, avg: p.avg * 100, min: p.min * 100, max: p.max * 100))
        .toList();
    final asymmetry      = (_weekNative['asymmetry'] ?? <_RangePt>[])
        .map((p) => (date: p.date, value: p.avg)).toList();
    final dblSupportRange = _weekNative['dblSupport'] ?? <_RangePt>[];
    final headphoneRange  = _weekNative['headphone'] ?? <_RangePt>[];

    final hasChartData = wellbeing.isNotEmpty || sleepQ.isNotEmpty ||
        neuro.isNotEmpty || musculo.isNotEmpty ||
        _weekSteps.isNotEmpty || _stepsLoading || _healthLoading ||
        hr.isNotEmpty || restHr.isNotEmpty ||
        sleepH.isNotEmpty || energy.isNotEmpty ||
        speedRange.isNotEmpty || dist.isNotEmpty ||
        weight.isNotEmpty || bmi.isNotEmpty ||
        flights.isNotEmpty || _hasMenstrual(filtered) ||
        stepLenRange.isNotEmpty || asymmetry.isNotEmpty ||
        dblSupportRange.isNotEmpty ||
        headphoneRange.isNotEmpty || glucose.isNotEmpty ||
        filtered.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(l.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: l.jumpToDate,
            onPressed: _openDateJump,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() { _weekSteps = []; _weekHealth = {}; _weekNative = {}; });
          await _load();
        },
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildWeekNav(context),
          const SizedBox(height: 12),

          if (!hasChartData) ...[
            const SizedBox(height: 36),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today_rounded, size: 48, color: cs.outlineVariant),
                const SizedBox(height: 12),
                Text(l.noDataThisWeek,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ),
          ],

          if (wellbeing.isNotEmpty) ...[
            FadeSlideIn(
              child: _ChartCard(
                icon: Icons.self_improvement_rounded,
                title: l.wellbeingRating,
                color: cs.primary,
                info: l.infoWellbeing,
                child: _MultiLineChart(
                  series: [_Series(data: wellbeing, color: cs.primary)],
                  minY: 0, maxY: 5, yInterval: 1, unit: '/5',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (sleepQ.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 20),
              child: _ChartCard(
                icon: Icons.bedtime_rounded,
                title: l.sleepQuality,
                color: c1,
                info: l.infoSleepQuality,
                child: _MultiLineChart(
                  series: [_Series(data: sleepQ, color: c1)],
                  minY: 0, maxY: 5, yInterval: 1, unit: '/5',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (neuro.isNotEmpty || musculo.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 40),
              child: _ChartCard(
                icon: Icons.electric_bolt_rounded,
                title: l.chartPainLevels,
                color: cNeuro,
                info: l.infoPainLevels,
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

          if (_stepsLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ] else if (_weekSteps.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _ChartCard(
                icon: Icons.directions_walk_rounded,
                title: l.stepActivity,
                color: cSteps,
                info: l.infoStepActivity,
                child: _StepBarChart(data: _weekSteps, color: cSteps),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_healthLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ],

          if (!_healthLoading && (hr.isNotEmpty || restHr.isNotEmpty)) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _ChartCard(
                icon: Icons.favorite_rounded,
                title: l.labelHeartRate,
                color: cHr,
                info: l.infoHeartRate,
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

          if (!_healthLoading && sleepH.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: _ChartCard(
                icon: Icons.nights_stay_rounded,
                title: l.labelSleep,
                color: cSleep,
                info: l.infoSleep,
                child: _SingleBarChart(data: sleepH, color: cSleep, unit: 'h', maxY: 10),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_healthLoading && energy.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: _ChartCard(
                icon: Icons.local_fire_department_rounded,
                title: l.labelActiveEnergy,
                color: cEnergy,
                info: l.infoActiveEnergy,
                child: _SingleBarChart(data: energy, color: cEnergy, unit: 'kcal'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_healthLoading && speedRange.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _ChartCard(
                icon: Icons.speed_rounded,
                title: l.labelWalkingSpeed,
                color: cSpeed,
                info: l.infoWalkingSpeed,
                child: _RangeLineChart(data: speedRange, color: cSpeed, unit: ' km/h'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_healthLoading && dist.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 130),
              child: _ChartCard(
                icon: Icons.route_rounded,
                title: l.labelDistance,
                color: cDist,
                info: l.infoDistance,
                child: _MultiLineChart(
                  series: [_Series(data: dist, color: cDist)],
                  unit: ' km',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (weight.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 155),
              child: _ChartCard(
                icon: Icons.monitor_weight_outlined,
                title: l.labelWeight,
                color: const Color(0xFF6D4C41),
                info: l.infoWeight,
                child: _SingleLineChart(
                  data: weight,
                  color: const Color(0xFF6D4C41),
                  unit: ' kg',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (bmi.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 158),
              child: _ChartCard(
                icon: Icons.calculate_outlined,
                title: l.bmiTitle,
                color: const Color(0xFF43A047),
                info: l.infoBmi,
                child: _BmiBarChart(data: bmi, l: l),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (glucose.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 159),
              child: _ChartCard(
                icon: Icons.bloodtype_rounded,
                title: l.labelBloodGlucose,
                color: cGlucose,
                info: l.infoBloodGlucose,
                child: _GlucoseLineChart(data: glucose, color: cGlucose),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_healthLoading && flights.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: _ChartCard(
                icon: Icons.stairs_rounded,
                title: l.labelFlightsClimbed,
                color: cFlights,
                info: l.infoFlights,
                child: _SingleBarChart(data: flights, color: cFlights, unit: 'fl'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_healthLoading && stepLenRange.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 143),
              child: _ChartCard(
                icon: Icons.straighten_rounded,
                title: l.chartStepLength,
                color: cStepLen,
                info: l.infoStepLength,
                child: _RangeLineChart(data: stepLenRange, color: cStepLen, unit: ' cm'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_healthLoading && asymmetry.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 146),
              child: _ChartCard(
                icon: Icons.swap_horiz_rounded,
                title: l.legendAsymmetry,
                color: cAsym,
                info: l.infoAsymmetry,
                child: _MultiLineChart(
                  series: [_Series(data: asymmetry, color: cAsym)],
                  minY: 0, maxY: 100, yInterval: 25, unit: '%',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_healthLoading && dblSupportRange.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 147),
              child: _ChartCard(
                icon: Icons.directions_walk_rounded,
                title: l.legendDoubleSupport,
                color: cDblSupport,
                info: l.infoDblSupport,
                child: _RangeLineChart(
                  data: dblSupportRange, color: cDblSupport,
                  unit: '%', minY: 0, maxY: 100, yInterval: 25,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_healthLoading && headphoneRange.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 149),
              child: _ChartCard(
                icon: Icons.headphones_rounded,
                title: l.chartHeadphoneAudio,
                color: cHeadphone,
                info: l.infoHeadphoneAudio,
                child: _RangeLineChart(data: headphoneRange, color: cHeadphone, unit: ' dB'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_hasMenstrual(filtered)) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: _ChartCard(
                icon: Icons.water_drop_rounded,
                title: l.menstrualActivity,
                color: const Color(0xFFB71C1C),
                info: l.infoMenstrual,
                child: _MenstrualStrip(days: _getMenstrualDays(filtered), weekEnd: _weekEnd),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (filtered.isNotEmpty) ...[
            const SizedBox(height: 4),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Text(l.pastSubmissionsHeader,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ...filtered.asMap().entries.map((e) => FadeSlideIn(
                  delay: Duration(milliseconds: 180 + e.key * 30),
                  child: _SubmissionCard(
                    key: ValueKey(
                      ((e.value['data'] as Map?)?['submission']?['id'] as String?) ?? e.key.toString(),
                    ),
                    entry: e.value,
                    onDelete: () => setState(() => _history.remove(e.value)),
                  ),
                )),
          ],
        ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  final List<Widget> legend;
  final String? info;

  const _ChartCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
    this.legend = const [],
    this.info,
  });

  void _showInfo(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
        ]),
        content: Text(info!, style: tt.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.5,
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
                if (info != null)
                  IconButton(
                    onPressed: () => _showInfo(context),
                    icon: Icon(Icons.info_outline_rounded,
                        size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    visualDensity: VisualDensity.compact,
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
    double actualMax = maxY ?? allPts.map((p) => p.value).reduce(math.max);
    if (actualMin == actualMax) { actualMin -= 1; actualMax += 1; }
    final vRange = actualMax - actualMin;
    if (minY == null) actualMin = math.max(0, actualMin - vRange * 0.2);
    if (maxY == null) actualMax = actualMax + vRange * 0.2;

    final primaryDates = series.reduce((a, b) => a.data.length >= b.data.length ? a : b).data.map((p) => p.date).toList();
    final count = primaryDates.length;
    final showEvery = count <= 4 ? 1 : count <= 8 ? 2 : 3;

    final seenDays = <String>{};
    final labelDates = primaryDates.map((d) {
      final key = '${d.year}-${d.month}-${d.day}';
      if (!seenDays.add(key)) return null;
      return d;
    }).toList();

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

    final dotPad = (actualMax - actualMin) * 0.07;
    final displayMinY = actualMin - dotPad;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: -0.5,
          maxX: (count - 1).toDouble() + 0.5,
          minY: displayMinY,
          maxY: actualMax,
          lineBarsData: bars,
          clipData: const FlClipData.all(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1.0,
                getTitlesWidget: (v, _) {
                  final idx = v.round();
                  if (idx < 0 || idx >= labelDates.length) return const SizedBox();
                  if (idx % showEvery != 0) return const SizedBox();
                  final labelDate = labelDates[idx];
                  if (labelDate == null) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('d/M').format(labelDate),
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
                  if (v <= displayMinY || v >= actualMax) return const SizedBox();
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
                  if (idx > 0) {
                    final prev = data[idx - 1].date;
                    final curr = data[idx].date;
                    if (prev.year == curr.year && prev.month == curr.month && prev.day == curr.day) {
                      return const SizedBox();
                    }
                  }
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

class _RangeLineChart extends StatelessWidget {
  final List<_RangePt> data;
  final Color color;
  final String? unit;
  final double? minY;
  final double? maxY;
  final double? yInterval;

  const _RangeLineChart({
    required this.data,
    required this.color,
    this.unit,
    this.minY,
    this.maxY,
    this.yInterval,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (data.isEmpty) return const SizedBox(height: 160);

    double actualMin = minY ?? data.map((p) => p.min).reduce(math.min);
    double actualMax = maxY ?? data.map((p) => p.max).reduce(math.max);
    if (actualMin == actualMax) { actualMin -= 1; actualMax += 1; }
    final vRange = actualMax - actualMin;
    if (minY == null) actualMin = math.max(0, actualMin - vRange * 0.15);
    if (maxY == null) actualMax = actualMax + vRange * 0.15;

    final count = data.length;
    final showEvery = count <= 4 ? 1 : count <= 8 ? 2 : 3;

            final bars = [
      LineChartBarData(
        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.avg)).toList(),
        color: color,
        barWidth: 2.5,
        isCurved: true,
        curveSmoothness: 0.3,
        preventCurveOverShooting: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, pct, barData, idx) => FlDotCirclePainter(
            radius: 4, color: color, strokeWidth: 1.5, strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(show: false),
      ),
      LineChartBarData(
        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.max)).toList(),
        color: Colors.transparent,
        barWidth: 0,
        isCurved: true,
        curveSmoothness: 0.3,
        preventCurveOverShooting: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
      LineChartBarData(
        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.min)).toList(),
        color: Colors.transparent,
        barWidth: 0,
        isCurved: true,
        curveSmoothness: 0.3,
        preventCurveOverShooting: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    ];

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: -0.5,
          maxX: (count - 1).toDouble() + 0.5,
          minY: actualMin,
          maxY: actualMax,
          lineBarsData: bars,
          betweenBarsData: [
            BetweenBarsData(
              fromIndex: 1,
              toIndex: 2,
              color: color.withValues(alpha: 0.18),
            ),
          ],
          clipData: const FlClipData.all(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1.0,
                getTitlesWidget: (v, _) {
                  final idx = v.round();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  if (idx % showEvery != 0) return const SizedBox();
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
                reservedSize: 34,
                interval: yInterval ?? ((actualMax - actualMin) / 4),
                getTitlesWidget: (v, meta) {
                  if (v <= actualMin || v >= actualMax) return const SizedBox();
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
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                if (s.barIndex != 0) return LineTooltipItem('', const TextStyle());
                final idx = s.spotIndex;
                if (idx >= data.length) return LineTooltipItem('', const TextStyle());
                final pt = data[idx];
                String fmt(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
                return LineTooltipItem(
                  '${fmt(pt.avg)}${unit ?? ''} (${fmt(pt.min)}–${fmt(pt.max)})\n${DateFormat('d MMM').format(pt.date)}',
                  TextStyle(color: cs.onInverseSurface, fontSize: 11, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

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
                  if (idx > 0) {
                    final prev = data[idx - 1].date;
                    final curr = data[idx].date;
                    if (prev.year == curr.year && prev.month == curr.month && prev.day == curr.day) {
                      return const SizedBox();
                    }
                  }
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

class _GlucoseLineChart extends StatelessWidget {
  final List<_Pt> data;
  final Color color;

  const _GlucoseLineChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (data.isEmpty) return const SizedBox(height: 200);

    final vals = data.map((p) => p.value);
    final dataMin = vals.reduce(math.min);
    final dataMax = vals.reduce(math.max);
    final minY = math.max(40.0, dataMin - 20);
    final maxY = math.max(dataMax + 20, 160.0);

    final count = data.length;
    final showEvery = count <= 4 ? 1 : count <= 8 ? 2 : 3;

    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: -0.5,
          maxX: (count - 1).toDouble() + 0.5,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: color,
              barWidth: 2.5,
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, data, idx) => FlDotCirclePainter(
                  radius: 4, color: color, strokeWidth: 1.5, strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 70,
                color: const Color(0xFF1E88E5).withValues(alpha: 0.6),
                strokeWidth: 1.5,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => '70',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF1E88E5), fontWeight: FontWeight.w600),
                ),
              ),
              HorizontalLine(
                y: 100,
                color: const Color(0xFF43A047).withValues(alpha: 0.6),
                strokeWidth: 1.5,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => '100',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF43A047), fontWeight: FontWeight.w600),
                ),
              ),
              HorizontalLine(
                y: 140,
                color: const Color(0xFFF57C00).withValues(alpha: 0.6),
                strokeWidth: 1.5,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => '140',
                  style: const TextStyle(fontSize: 9, color: Color(0xFFF57C00), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1.0,
                getTitlesWidget: (v, _) {
                  final idx = v.round();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  if (idx % showEvery != 0) return const SizedBox();
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
                reservedSize: 38,
                interval: 30,
                getTitlesWidget: (v, meta) {
                  if (v <= minY || v >= maxY) return const SizedBox();
                  return Text(
                    v.round().toString(),
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
            horizontalInterval: 30,
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
                final idx = s.spotIndex;
                final date = idx < data.length ? '\n${DateFormat('d MMM').format(data[idx].date)}' : '';
                final val = s.y.toStringAsFixed(1);
                return LineTooltipItem(
                  '$val mg/dL$date',
                  TextStyle(color: cs.onInverseSurface, fontSize: 11, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenstrualStrip extends StatelessWidget {
  final Map<String, bool?> days;
  final DateTime weekEnd;
  const _MenstrualStrip({required this.days, required this.weekEnd});

  static const _red = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = weekEnd.subtract(Duration(days: 6 - i));
        final k = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final onPeriod = days[k];
        final isToday = day == todayDate;

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

class _SubmissionCard extends StatefulWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onDelete;
  const _SubmissionCard({super.key, required this.entry, required this.onDelete});

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  bool _expanded = false;
  bool _showJson = false;
  bool _deleting = false;

  Future<void> _doDelete(BuildContext dialogCtx) async {
    Navigator.pop(dialogCtx);
    setState(() => _deleting = true);
    try {
      final id = (widget.entry['data'] as Map?)?['submission']?['id'] as String?;
      if (id != null) {
        await StorageService().deleteSubmission(id);
        await SupabaseService().deleteSubmission(id);
      }
      if (mounted) widget.onDelete();
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _showDeleteDialog() {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: cs.error, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(l.deleteConfirmTitle)),
          ],
        ),
        content: Text(l.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => _doDelete(ctx),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: Text(l.delete,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
    final forDate = rawTs != null ? DateTime.tryParse(rawTs)?.toLocal() : null;
    final locale = l.locale.languageCode;
    final forDateStr = forDate != null ? DateFormat('d MMM yyyy', locale).format(forDate) : '—';

    final rawCreatedAt = submission?['created_at_utc'] as String?;
    final createdAt = rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt)?.toLocal() : null;
    final createdAtStr = createdAt != null
        ? '${l.enteredAt}: ${DateFormat('d MMM, HH:mm', locale).format(createdAt)}'
        : null;

    final isPending = status == 'pending';
    final statusColor = isPending ? cs.error : Colors.green;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() { _expanded = !_expanded; if (!_expanded) _showJson = false; }),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(forDateStr,
                                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              if (createdAtStr != null) ...[
                                const SizedBox(height: 2),
                                Text(createdAtStr,
                                    style: tt.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant)),
                              ],
                            ],
                          ),
                        ),
                        if (onPeriod == true) ...[
                          const Icon(Icons.water_drop, color: Color(0xFFB71C1C), size: 16),
                          const SizedBox(width: 6),
                        ],
                        if (isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(l.statusPending,
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
                      const Spacer(),
                      Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_deleting)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    GestureDetector(
                      onTap: _showDeleteDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(l.delete,
                            style: tt.labelSmall?.copyWith(
                                color: cs.error, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
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
                  if (weightKg != null)
                    _DetailRow(Icons.monitor_weight_outlined, l.labelWeight, '${weightKg.toStringAsFixed(1)} kg'),
                  if (bmiVal != null)
                    _DetailRow(Icons.calculate_outlined, l.labelBmi, '${bmiVal.toStringAsFixed(1)} kg/m²'),
                  if ((selfReport?['blood_glucose_mgdl'] as num?) != null)
                    _DetailRow(Icons.bloodtype_rounded, l.labelBloodGlucose,
                        '${((selfReport!['blood_glucose_mgdl'] as num).toDouble()).toStringAsFixed(1)} mg/dL'),

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
                  if (metricMap['walking_step_length'] != null)
                    _DetailRow(Icons.straighten_rounded, l.labelStepLength,
                        '${((metricMap['walking_step_length']! as double) * 100).toStringAsFixed(1)} cm'),
                  if (metricMap['walking_asymmetry'] != null)
                    _DetailRow(Icons.swap_horiz_rounded, l.labelWalkingAsymmetry,
                        '${(metricMap['walking_asymmetry']! as double).toStringAsFixed(1)} %'),
                  if (metricMap['walking_double_support'] != null)
                    _DetailRow(Icons.directions_walk_rounded, l.labelDoubleSupport,
                        '${(metricMap['walking_double_support']! as double).toStringAsFixed(1)} %'),
                  if (metricMap['headphone_audio_exposure'] != null)
                    _DetailRow(Icons.headphones_rounded, l.labelHeadphoneAudio,
                        '${(metricMap['headphone_audio_exposure']! as double).toStringAsFixed(1)} dB'),

                  if (menstrual != null) ...[
                    const SizedBox(height: 4),
                    if (cycleDay != null && cyclePhase != null)
                      _DetailRow(
                        Icons.water_drop_rounded,
                        l.menstrualCycle,
                        '${onPeriod == true ? '${l.onPeriod} · ' : ''}${l.cycleDay} $cycleDay · ${_phaseLabel(cyclePhase, l)}',
                        valueColor: onPeriod == true ? const Color(0xFFB71C1C) : null,
                      )
                    else if (onPeriod == true)
                      _DetailRow(
                        Icons.water_drop_rounded,
                        l.menstrualCycle,
                        l.onPeriod,
                        valueColor: const Color(0xFFB71C1C),
                      ),
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
          ],
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

class _HistorySkeletonScreen extends StatefulWidget {
  const _HistorySkeletonScreen();
  @override
  State<_HistorySkeletonScreen> createState() => _HistorySkeletonScreenState();
}

class _HistorySkeletonScreenState extends State<_HistorySkeletonScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(l.historyTitle)),
      body: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final base = cs.onSurface.withValues(alpha: 0.06 + _anim.value * 0.06);
          final shimmer = cs.onSurface.withValues(alpha: 0.03 + _anim.value * 0.04);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SkeletonBox(height: 44, color: base, radius: 12),
              const SizedBox(height: 20),
              for (var i = 0; i < 3; i++) ...[
                _SkeletonBox(height: 120, color: base, radius: 16),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              _SkeletonBox(height: 180, color: shimmer, radius: 16),
              const SizedBox(height: 12),
              _SkeletonBox(height: 180, color: shimmer, radius: 16),
            ],
          );
        },
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final Color color;
  final double radius;
  const _SkeletonBox({required this.height, required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
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
