import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../l10n/app_localizations.dart';
import '../services/pdf_export_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_bar_title.dart';
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
  bool _pdfLoading = false;

  Map<String, dynamic> get _data =>
      jsonDecode(widget.payload) as Map<String, dynamic>;

  Future<void> _downloadPdf() async {
    setState(() => _pdfLoading = true);
    try {
      final bytes = await buildSubmissionPdf(_data, AppLocalizations.of(context));
      final data = _data;
      final submission = data['submission'] as Map<String, dynamic>?;
      final rawDate = submission?['submitted_at']?.toString() ?? '';
      String dateTag = 'report';
      try {
        final dt = DateTime.parse(rawDate).toLocal();
        dateTag =
            '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {}
      await Printing.sharePdf(bytes: bytes, filename: 'heaLife_$dateTag.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

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
    final sleepQMap = selfReport?['sleep_quality'] as Map<String, dynamic>?;
    final painMap = selfReport?['pain'] as Map<String, dynamic>?;
    final rating = wellbeing?['value'] as int?;
    final sleepQuality = (sleepQMap?['value'] as int?);
    final neuropathic = (((painMap?['neuropathic'] as Map?)?['value']) as int?);
    final musculoskeletal = (((painMap?['musculoskeletal'] as Map?)?['value']) as int?);
    final comment = selfReport?['comment'] as String?;
    final bloodGlucose = (selfReport?['blood_glucose_mgdl'] as num?)?.toDouble();
    final metrics = data['health_metrics'] as List<dynamic>?;
    final metricCount = metrics?.length ?? 0;
    final metricMap = <String, num>{};
    for (final m in metrics ?? []) {
      final t = (m as Map)['type'] as String?;
      final v = m['value'] as num?;
      if (t != null && v != null) metricMap[t] = v;
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        title: AppBarTitle(l.resultTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
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

          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            child: _InsightCard(
              rating: rating,
              sleepQuality: sleepQuality,
              neuropathic: neuropathic,
              musculoskeletal: musculoskeletal,
              steps: (metricMap['step_count'] as int?),
              bloodGlucose: bloodGlucose,
              l: l,
            ),
          ),

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
                    if (bloodGlucose != null) ...[
                      const SizedBox(height: 10),
                      _SummaryRow(
                        icon: Icons.bloodtype_rounded,
                        label: l.labelBloodGlucose,
                        value: '${bloodGlucose.toStringAsFixed(1)} mg/dL',
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

          const SizedBox(height: 24),
          FadeSlideIn(
            delay: const Duration(milliseconds: 360),
            child: ElevatedButton.icon(
              onPressed: _pdfLoading ? null : _downloadPdf,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              icon: _pdfLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: Text(_pdfLoading ? l.pdfGenerating : l.downloadPdf),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 400),
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
    ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final int? rating;
  final int? sleepQuality;
  final int? neuropathic;
  final int? musculoskeletal;
  final int? steps;
  final double? bloodGlucose;
  final AppLocalizations l;

  const _InsightCard({
    required this.rating,
    required this.sleepQuality,
    required this.neuropathic,
    required this.musculoskeletal,
    required this.steps,
    required this.bloodGlucose,
    required this.l,
  });

    double _score() {
    double points = 0;
    double max = 0;
    if (rating != null) {
      max += 4;
      points += (rating! - 1).clamp(0, 4).toDouble();
    }
    if (sleepQuality != null) {
      max += 4;
      points += (sleepQuality! - 1).clamp(0, 4).toDouble();
    }
    if (neuropathic != null || musculoskeletal != null) {
      max += 10;
      final avg = ((neuropathic ?? 0) + (musculoskeletal ?? 0)) /
          ((neuropathic != null && musculoskeletal != null) ? 2 : 1);
      points += (10 - avg).clamp(0, 10);
    }
    return max > 0 ? (points / max).clamp(0.0, 1.0) : 0.5;
  }

  List<String> _observations() {
    final obs = <String>[];
    if (rating != null) {
      if (rating! >= 4) { obs.add(l.insightHighMood); }
      else if (rating! <= 2) { obs.add(l.insightLowMood); }
    }
    if (sleepQuality != null) {
      if (sleepQuality! >= 4) { obs.add(l.insightGoodSleepQ); }
      else if (sleepQuality! <= 2) { obs.add(l.insightPoorSleepQ); }
    }
    final avgPain = neuropathic != null || musculoskeletal != null
        ? ((neuropathic ?? 0) + (musculoskeletal ?? 0)) /
            ((neuropathic != null && musculoskeletal != null) ? 2 : 1)
        : null;
    if (avgPain != null) {
      if (avgPain <= 1) { obs.add(l.insightLowPain); }
      else if (avgPain >= 6) { obs.add(l.insightHighPain); }
    }
    if (steps != null) {
      if (steps! >= 7500) { obs.add(l.insightHighActivity); }
      else if (steps! < 2000) { obs.add(l.insightLowActivity); }
    }
    if (bloodGlucose != null) {
      if (bloodGlucose! < 70) { obs.add(l.insightGlucoseLow); }
      else if (bloodGlucose! <= 140) { obs.add(l.insightGlucoseNormal); }
      else { obs.add(l.insightGlucoseHigh); }
    }
    return obs.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final score = _score();
    final observations = _observations();

    final String levelLabel;
    final String subLabel;
    final Color levelColor;
    final IconData levelIcon;

    if (score >= 0.78) {
      levelLabel = l.insightExcellent;
      subLabel = l.insightExcellentSub;
      levelColor = const Color(0xFF2E7D32);
      levelIcon = Icons.star_rounded;
    } else if (score >= 0.55) {
      levelLabel = l.insightGood;
      subLabel = l.insightGoodSub;
      levelColor = const Color(0xFF1565C0);
      levelIcon = Icons.thumb_up_rounded;
    } else if (score >= 0.35) {
      levelLabel = l.insightFair;
      subLabel = l.insightFairSub;
      levelColor = const Color(0xFFF57C00);
      levelIcon = Icons.sentiment_neutral_rounded;
    } else {
      levelLabel = l.insightChallenging;
      subLabel = l.insightChallengingSub;
      levelColor = const Color(0xFF546E7A);
      levelIcon = Icons.favorite_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: levelColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(levelIcon, size: 20, color: levelColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.insightTitle,
                        style: tt.labelSmall?.copyWith(
                          color: levelColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        levelLabel,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: levelColor.withValues(alpha: 0.18)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subLabel,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (observations.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...observations.map((obs) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 5, right: 8),
                              decoration: BoxDecoration(
                                color: levelColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                obs,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    'step_count':               Icons.directions_walk_rounded,
    'heart_rate':               Icons.favorite_rounded,
    'resting_heart_rate':       Icons.monitor_heart_outlined,
    'sleep_duration':           Icons.bedtime_rounded,
    'active_energy_burned':     Icons.local_fire_department_rounded,
    'walking_speed':            Icons.speed_rounded,
    'flights_climbed':          Icons.stairs_rounded,
    'distance_walking_running': Icons.straighten_rounded,
    'walking_step_length':      Icons.swap_horiz_rounded,
    'walking_asymmetry':        Icons.compare_arrows_rounded,
    'walking_double_support':   Icons.accessibility_new_rounded,
    'walking_steadiness':       Icons.balance_rounded,
    'headphone_audio_exposure': Icons.headphones_rounded,
  };

  String _label(String type) => switch (type) {
        'step_count'               => l.labelStepsToday,
        'heart_rate'               => l.labelHeartRate,
        'resting_heart_rate'       => l.labelRestingHeartRate,
        'sleep_duration'           => l.labelSleep,
        'active_energy_burned'     => l.labelActiveEnergy,
        'walking_speed'            => l.labelWalkingSpeed,
        'flights_climbed'          => l.labelFlightsClimbed,
        'distance_walking_running' => l.labelDistance,
        'walking_step_length'      => l.labelStepLength,
        'walking_asymmetry'        => l.labelWalkingAsymmetry,
        'walking_double_support'   => l.labelDoubleSupport,
        'walking_steadiness'       => l.labelWalkingSteadiness,
        'headphone_audio_exposure' => l.labelHeadphoneAudio,
        _                          => type,
      };

  String _formatted(String type, dynamic value, String unit) {
    if (value == null) return l.noData;
    switch (type) {
      case 'step_count':
        return '${(value as num).round()} ${l.unitSteps}';
      case 'flights_climbed':
        return '${(value as num).round()} ${l.unitFloors}';
      case 'heart_rate':
      case 'resting_heart_rate':
        return '${(value as num).round()} bpm';
      case 'sleep_duration':
        return '${(value as num).toStringAsFixed(1)} h';
      case 'active_energy_burned':
        return '${(value as num).round()} kcal';
      case 'walking_speed':
        return '${(value as num).toStringAsFixed(1)} km/h';
      case 'distance_walking_running':
        return '${(value as num).toStringAsFixed(2)} km';
      case 'walking_step_length':
        return '${((value as num) * 100).toStringAsFixed(0)} cm';
      case 'walking_asymmetry':
      case 'walking_double_support':
      case 'walking_steadiness':
        return '${(value as num).toStringAsFixed(1)} %';
      case 'headphone_audio_exposure':
        return '${(value as num).toStringAsFixed(1)} dB';
      default:
        return '$value $unit';
    }
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
          Text(_formatted(type, value, unit),
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
