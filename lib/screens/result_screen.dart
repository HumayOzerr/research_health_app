import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import 'welcome_screen.dart';

class ResultScreen extends StatefulWidget {
  final bool success;
  final bool queued;
  final String payload;

  const ResultScreen({
    super.key,
    required this.success,
    required this.queued,
    required this.payload,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showJson = false;

  Map<String, dynamic> get _data =>
      jsonDecode(widget.payload) as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    final IconData icon;
    final Color iconColor;
    final String title;
    final String message;

    if (widget.success) {
      icon = Icons.check_circle_rounded;
      iconColor = Colors.green;
      title = l.resultSuccessTitle;
      message = l.resultSuccessMessage;
    } else if (widget.queued) {
      icon = Icons.cloud_upload_outlined;
      iconColor = cs.primary;
      title = l.resultQueuedTitle;
      message = l.resultQueuedMessage;
    } else {
      icon = Icons.error_rounded;
      iconColor = cs.error;
      title = l.resultFailedTitle;
      message = l.resultFailedMessage;
    }

    final data = _data;
    final participant = data['participant'] as Map<String, dynamic>?;
    final selfReport = data['self_report'] as Map<String, dynamic>?;
    final wellbeing = selfReport?['wellbeing_rating'] as Map<String, dynamic>?;
    final rating = wellbeing?['value'] as int?;
    final comment = selfReport?['comment'] as String?;
    final metrics = data['health_metrics'] as List<dynamic>?;
    final metricCount = metrics?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l.resultTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Status ────────────────────────────────────────────────────
          FadeSlideIn(
            child: Icon(icon, size: 72, color: iconColor),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: Text(
              title,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(
              message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.queued) ...[
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 130),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: cs.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l.resultQueuedNote,
                        style: tt.labelSmall?.copyWith(color: cs.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Summary cards ─────────────────────────────────────────────
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: Text(l.participant,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 190),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SummaryRow(
                      icon: Icons.badge_outlined,
                      label: l.labelId,
                      value: participant?['id']?.toString() ?? '—',
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      icon: Icons.person_outlined,
                      label: l.ageRange,
                      value: participant?['age_range']?.toString() ?? '—',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: Text(l.wellbeing,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 250),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (rating != null)
                      _RatingDisplay(rating: rating, cs: cs, tt: tt),
                    if (comment != null && comment.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _SummaryRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: l.labelComment,
                        value: comment,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            child: Text(l.healthMetrics,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 310),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: metricCount == 0
                    ? Text(l.permissionNotGranted,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                    : Column(
                        children: [
                          for (final m in metrics!)
                            _MetricRow(metric: m as Map<String, dynamic>, l: l),
                        ],
                      ),
              ),
            ),
          ),

          // ── Technical details ─────────────────────────────────────────
          const SizedBox(height: 24),
          FadeSlideIn(
            delay: const Duration(milliseconds: 340),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _showJson = !_showJson),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showJson
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.jsonPayload,
                      style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showJson) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: l.copyToClipboard,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.payload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.copied)),
                    );
                  },
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.payload,
                style: tt.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],

          // ── Start over ────────────────────────────────────────────────
          const SizedBox(height: 32),
          FadeSlideIn(
            delay: const Duration(milliseconds: 380),
            child: OutlinedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                AppPageRoute(
                  page: WelcomeScreen(settings: SettingsService()),
                ),
                (_) => false,
              ),
              child: Text(l.startOver),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Text(label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  final int rating;
  final ColorScheme cs;
  final TextTheme tt;

  const _RatingDisplay({required this.rating, required this.cs, required this.tt});

  static const _colors = {
    1: Color(0xFFD32F2F),
    2: Color(0xFFF57C00),
    3: Color(0xFFFBC02D),
    4: Color(0xFF388E3C),
    5: Color(0xFF1B5E20),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[rating] ?? cs.primary;
    return Row(
      children: [
        Icon(Icons.favorite_rounded, size: 18, color: color),
        const SizedBox(width: 10),
        Text(AppLocalizations.of(context).labelRating,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const Spacer(),
        Row(
          children: List.generate(5, (i) {
            return Icon(
              i < rating ? Icons.circle : Icons.circle_outlined,
              size: 14,
              color: i < rating ? color : cs.outlineVariant,
            );
          }),
        ),
        const SizedBox(width: 6),
        Text('$rating / 5',
            style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final Map<String, dynamic> metric;
  final AppLocalizations l;

  const _MetricRow({required this.metric, required this.l});

  static const _icons = {
    'step_count': Icons.directions_walk_rounded,
    'heart_rate': Icons.favorite_rounded,
    'sleep_duration': Icons.bedtime_rounded,
    'active_energy': Icons.local_fire_department_rounded,
  };

  String _label(String type) => switch (type) {
        'step_count' => l.labelStepsToday,
        'heart_rate' => l.labelHeartRate,
        'sleep_duration' => l.labelSleep,
        'active_energy' => l.labelActiveEnergy,
        _ => type,
      };

  String _formatted(dynamic value, String unit) {
    if (value == null) return l.noData;
    if (unit == 'count') return '$value steps';
    if (unit == 'bpm') return '$value bpm';
    if (unit == 'hours') return '${(value as num).toStringAsFixed(1)} h';
    if (unit == 'kcal') return '${(value as num).round()} kcal';
    return '$value $unit';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final type = metric['type'] as String? ?? '';
    final value = metric['value'];
    final unit = metric['unit'] as String? ?? '';
    final icon = _icons[type] ?? Icons.monitor_heart_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_label(type),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Text(_formatted(value, unit),
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
