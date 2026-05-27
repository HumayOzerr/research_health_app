import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../l10n/app_localizations.dart';

const _kPrimary = PdfColor.fromInt(0xFF1565C0);
const _kDark    = PdfColor.fromInt(0xFF0D47A1);
const _kGreen   = PdfColor.fromInt(0xFF2E7D32);
const _kOrange  = PdfColor.fromInt(0xFFF57C00);
const _kRed     = PdfColor.fromInt(0xFFD32F2F);
const _kGrey    = PdfColor.fromInt(0xFF546E7A);
const _kBg      = PdfColor.fromInt(0xFFF5F7FA);
const _kBorder  = PdfColor.fromInt(0xFFDDE3EA);
const _kText    = PdfColor.fromInt(0xFF1A1A2E);
const _kMuted   = PdfColor.fromInt(0xFF607080);
const _kPink    = PdfColor.fromInt(0xFFD81B60);

Future<Uint8List> buildSubmissionPdf(
    Map<String, dynamic> data, AppLocalizations l) async {
  final doc = pw.Document(
    title: 'HeaLife Health Report',
    author: 'ETH Zurich - SCI & AI Lab',
  );

    final lang = l.locale.languageCode;
  pw.Font regular;
  pw.Font bold;
  pw.Font italic;
  try {
    if (lang == 'zh') {
      regular = await PdfGoogleFonts.notoSansSCRegular();
      bold    = await PdfGoogleFonts.notoSansSCBold();
      italic  = regular;
    } else if (lang == 'ja') {
      regular = await PdfGoogleFonts.notoSansJPRegular();
      bold    = await PdfGoogleFonts.notoSansJPBold();
      italic  = regular;
    } else if (lang == 'ko') {
      regular = await PdfGoogleFonts.notoSansKRRegular();
      bold    = await PdfGoogleFonts.notoSansKRBold();
      italic  = regular;
    } else if (lang == 'ar') {
      regular = await PdfGoogleFonts.notoSansArabicRegular();
      bold    = await PdfGoogleFonts.notoSansArabicBold();
      italic  = regular;
    } else {
            regular = await PdfGoogleFonts.notoSansRegular();
      bold    = await PdfGoogleFonts.notoSansBold();
      italic  = await PdfGoogleFonts.notoSansItalic();
    }
  } catch (_) {
    regular = pw.Font.helvetica();
    bold    = pw.Font.helveticaBold();
    italic  = pw.Font.helveticaOblique();
  }

    final submission  = data['submission']  as Map<String, dynamic>? ?? {};
  final participant = data['participant'] as Map<String, dynamic>? ?? {};
  final selfReport  = data['self_report'] as Map<String, dynamic>? ?? {};
  final metrics     = (data['health_metrics'] as List<dynamic>?) ?? [];

  final submissionId = submission['id']?.toString() ?? '-';
  final submittedAt  = submission['submitted_at']?.toString() ?? '';
  final participantId = participant['id']?.toString() ?? '-';
  final ageRange     = participant['age_range']?.toString() ?? '-';

  final wellbeingMap    = selfReport['wellbeing_rating'] as Map<String, dynamic>?;
  final sleepQMap       = selfReport['sleep_quality']    as Map<String, dynamic>?;
  final painMap         = selfReport['pain']             as Map<String, dynamic>?;
  final comment         = selfReport['comment']          as String?;
  final glucoseRaw      = selfReport['blood_glucose_mgdl'] as num?;

  final rating          = wellbeingMap?['value'] as int?;
  final sleepQuality    = sleepQMap?['value']    as int?;
  final neuropathic     = ((painMap?['neuropathic']    as Map?)?['value']) as int?;
  final musculoskeletal = ((painMap?['musculoskeletal'] as Map?)?['value']) as int?;
  final bloodGlucose    = glucoseRaw?.toDouble();

    String displayDate;
  try {
    final dt = DateTime.parse(submittedAt).toLocal();
    displayDate =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    final now = DateTime.now();
    displayDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

    final score = _computeScore(rating, sleepQuality, neuropathic, musculoskeletal);
  final String levelLabel;
  final PdfColor levelColor;
  if (score >= 0.78) {
    levelLabel = l.insightExcellent;
    levelColor = _kGreen;
  } else if (score >= 0.55) {
    levelLabel = l.insightGood;
    levelColor = _kPrimary;
  } else if (score >= 0.35) {
    levelLabel = l.insightFair;
    levelColor = _kOrange;
  } else {
    levelLabel = l.insightChallenging;
    levelColor = _kGrey;
  }

  final observations = _buildObservations(
    l, rating, sleepQuality, neuropathic, musculoskeletal,
    _stepCount(metrics), bloodGlucose,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      build: (ctx) => [
                _header(l, bold, regular, displayDate, participantId, ageRange),
        pw.SizedBox(height: 20),

                _sectionCard(
          title: _p(l.insightTitle),
          accentColor: levelColor,
          bold: bold, regular: regular, italic: italic,
          children: [
            pw.Row(children: [
              pw.Container(
                width: 10, height: 10,
                decoration: pw.BoxDecoration(
                  color: levelColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(_p(levelLabel),
                  style: pw.TextStyle(font: bold, fontSize: 13, color: levelColor)),
            ]),
            if (observations.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              ...observations.map((o) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 6, height: 6,
                          margin: const pw.EdgeInsets.only(top: 2, right: 6),
                          decoration: pw.BoxDecoration(
                            color: levelColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(o,
                              style: pw.TextStyle(
                                  font: regular, fontSize: 10, color: _kText)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        pw.SizedBox(height: 14),

                _sectionCard(
          title: _p(l.pdfWellbeingSelfReport),
          accentColor: _kPrimary,
          bold: bold, regular: regular, italic: italic,
          children: [
            if (rating != null) ...[
              _labelRow(l.pdfOverallWellbeing, bold),
              pw.SizedBox(height: 4),
              _ratingDots(rating, 5, _ratingColor(rating)),
              pw.SizedBox(height: 10),
            ],
            if (sleepQuality != null) ...[
              _labelRow(l.pdfSleepQuality, bold),
              pw.SizedBox(height: 4),
              _ratingDots(sleepQuality, 5, _kPrimary),
              pw.SizedBox(height: 10),
            ],
            if (neuropathic != null) ...[
              _labelRow(l.pdfNeuropathicPain, bold),
              pw.SizedBox(height: 4),
              _painBar(neuropathic, 10),
              pw.SizedBox(height: 10),
            ],
            if (musculoskeletal != null) ...[
              _labelRow(l.pdfMusculoskeletalPain, bold),
              pw.SizedBox(height: 4),
              _painBar(musculoskeletal, 10),
              pw.SizedBox(height: 10),
            ],
            if (bloodGlucose != null) ...[
              _dataRow(
                l.labelBloodGlucose,
                '${bloodGlucose.toStringAsFixed(1)} mg/dL  (${_glucoseLabel(l, bloodGlucose)})',
                bold, regular, valueColor: _kPink,
              ),
              pw.SizedBox(height: 6),
            ],
            if (comment != null && comment.isNotEmpty) ...[
              _labelRow(l.pdfNotesComment, bold),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: _kBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: _kBorder),
                ),
                child: pw.Text(_p(comment),
                    style: pw.TextStyle(
                        font: italic, fontSize: 10, color: _kText)),
              ),
            ],
          ],
        ),
        pw.SizedBox(height: 14),

                if (metrics.isNotEmpty)
          _sectionCard(
            title: _p(l.healthMetrics),
            accentColor: const PdfColor.fromInt(0xFF00796B),
            bold: bold, regular: regular, italic: italic,
            children: [
              _metricsTable(l, metrics, bold, regular),
            ],
          ),

        pw.SizedBox(height: 14),

                _footer(l, regular, submissionId),
      ],
    ),
  );

  return doc.save();
}

String _p(String s) => s
    .replaceAll('—', ' - ')      .replaceAll('–', '-')        .replaceAll('−', '-')        .replaceAll('’', '\'')       .replaceAll('‘', '\'')       .replaceAll('“', '"')        .replaceAll('”', '"')        .replaceAll('•', '-');
double _computeScore(int? rating, int? sleepQ, int? neuro, int? musculo) {
  double pts = 0, max = 0;
  if (rating != null)  { max += 4; pts += (rating - 1).clamp(0, 4).toDouble(); }
  if (sleepQ != null)  { max += 4; pts += (sleepQ - 1).clamp(0, 4).toDouble(); }
  if (neuro != null || musculo != null) {
    max += 10;
    final avg = ((neuro ?? 0) + (musculo ?? 0)) /
        ((neuro != null && musculo != null) ? 2 : 1);
    pts += (10 - avg).clamp(0, 10);
  }
  return max > 0 ? (pts / max).clamp(0.0, 1.0) : 0.5;
}

int? _stepCount(List<dynamic> metrics) {
  for (final m in metrics) {
    if ((m as Map)['type'] == 'step_count') {
      return (m['value'] as num?)?.toInt();
    }
  }
  return null;
}

List<String> _buildObservations(
  AppLocalizations l,
  int? rating, int? sleepQ, int? neuro, int? musculo,
  int? steps, double? glucose,
) {
  final obs = <String>[];
  if (rating != null) {
    if (rating >= 4) { obs.add(l.insightHighMood); }
    else if (rating <= 2) { obs.add(l.insightLowMood); }
  }
  if (sleepQ != null) {
    if (sleepQ >= 4) { obs.add(l.insightGoodSleepQ); }
    else if (sleepQ <= 2) { obs.add(l.insightPoorSleepQ); }
  }
  final avgPain = (neuro != null || musculo != null)
      ? ((neuro ?? 0) + (musculo ?? 0)) /
          ((neuro != null && musculo != null) ? 2 : 1)
      : null;
  if (avgPain != null) {
    if (avgPain <= 1) { obs.add(l.insightLowPain); }
    else if (avgPain >= 6) { obs.add(l.insightHighPain); }
  }
  if (steps != null) {
    if (steps >= 7500) { obs.add(l.insightHighActivity); }
    else if (steps < 2000) { obs.add(l.insightLowActivity); }
  }
  if (glucose != null) {
    if (glucose < 70) { obs.add(l.insightGlucoseLow); }
    else if (glucose <= 140) { obs.add(l.insightGlucoseNormal); }
    else { obs.add(l.insightGlucoseHigh); }
  }
  return obs.take(4).map(_p).toList();
}

String _glucoseLabel(AppLocalizations l, double v) {
  if (v < 70)   return l.pdfGlucoseLow;
  if (v <= 100) return l.pdfGlucoseNormal;
  if (v <= 140) return l.pdfGlucosePreMeal;
  return l.pdfGlucoseElevated;
}

PdfColor _ratingColor(int r) {
  if (r >= 5) return _kGreen;
  if (r == 4) return const PdfColor.fromInt(0xFF388E3C);
  if (r == 3) return const PdfColor.fromInt(0xFFFBC02D);
  if (r == 2) return _kOrange;
  return _kRed;
}

pw.Widget _header(
  AppLocalizations l,
  pw.Font bold, pw.Font regular,
  String date, String participantId, String ageRange,
) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      gradient: const pw.LinearGradient(
        colors: [_kDark, _kPrimary],
        begin: pw.Alignment.centerLeft,
        end: pw.Alignment.centerRight,
      ),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    padding: const pw.EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('HeaLife',
                    style: pw.TextStyle(
                        font: bold, fontSize: 22, color: PdfColors.white)),
                pw.Text(_p(l.pdfDailyReport),
                    style: pw.TextStyle(
                        font: regular, fontSize: 11,
                        color: const PdfColor(1, 1, 1, 0.75))),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('ETH Zurich',
                    style: pw.TextStyle(
                        font: bold, fontSize: 10, color: PdfColors.white)),
                pw.Text('SCI & AI Lab',
                    style: pw.TextStyle(
                        font: regular, fontSize: 9,
                        color: const PdfColor(1, 1, 1, 0.75))),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(height: 0.5, color: const PdfColor(1, 1, 1, 0.35)),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _headerChip(_p(l.participant), participantId, bold, regular),
            pw.SizedBox(width: 24),
            _headerChip(_p(l.ageRange), ageRange, bold, regular),
            pw.SizedBox(width: 24),
            _headerChip(_p(l.pdfDate), date, bold, regular),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _headerChip(String label, String value, pw.Font bold, pw.Font regular) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(_p(label),
          style: pw.TextStyle(
              font: regular, fontSize: 7,
              color: const PdfColor(1, 1, 1, 0.6), letterSpacing: 0.6)),
      pw.SizedBox(height: 2),
      pw.Text(value,
          style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white)),
    ],
  );
}

pw.Widget _sectionCard({
  required String title,
  required PdfColor accentColor,
  required pw.Font bold,
  required pw.Font regular,
  required pw.Font italic,
  required List<pw.Widget> children,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: _kBorder),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 4,
          decoration: pw.BoxDecoration(
            color: accentColor,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(6),
              bottomLeft: pw.Radius.circular(6),
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        font: bold, fontSize: 8,
                        color: accentColor, letterSpacing: 0.8)),
                pw.SizedBox(height: 10),
                ...children,
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _labelRow(String label, pw.Font bold) {
  return pw.Text(_p(label),
      style: pw.TextStyle(font: bold, fontSize: 10, color: _kMuted));
}

pw.Widget _dataRow(
  String label, String value,
  pw.Font bold, pw.Font regular, {
  PdfColor? valueColor,
}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(_p(label),
          style: pw.TextStyle(font: bold, fontSize: 10, color: _kMuted)),
      pw.Text(_p(value),
          style: pw.TextStyle(
              font: bold, fontSize: 10, color: valueColor ?? _kText)),
    ],
  );
}

pw.Widget _ratingDots(int value, int max, PdfColor color) {
  return pw.Row(
    children: [
      ...List.generate(max, (i) => pw.Padding(
            padding: const pw.EdgeInsets.only(right: 4),
            child: pw.Container(
              width: 12, height: 12,
              decoration: pw.BoxDecoration(
                color: i < value ? color : PdfColors.grey300,
                shape: pw.BoxShape.circle,
              ),
            ),
          )),
      pw.SizedBox(width: 8),
      pw.Text('$value / $max',
          style: pw.TextStyle(
              font: pw.Font.helveticaBold(), fontSize: 10, color: color)),
    ],
  );
}

pw.Widget _painBar(int? value, int max) {
  final v = value ?? 0;
  const barWidth = 200.0;
  final filled = (v / max * barWidth).clamp(0.0, barWidth);
  final barColor = v >= 7 ? _kRed : v >= 4 ? _kOrange : _kGreen;

  return pw.Row(
    children: [
      pw.Stack(
        children: [
          pw.Container(
            width: barWidth, height: 10,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
          ),
          pw.Container(
            width: filled, height: 10,
            decoration: pw.BoxDecoration(
              color: barColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
          ),
        ],
      ),
      pw.SizedBox(width: 8),
      pw.Text('$v / $max',
          style: pw.TextStyle(
              font: pw.Font.helveticaBold(), fontSize: 10, color: barColor)),
    ],
  );
}

pw.Widget _metricsTable(
    AppLocalizations l, List<dynamic> metrics, pw.Font bold, pw.Font regular) {
  final rows = <pw.TableRow>[];
  for (int i = 0; i < metrics.length; i++) {
    final m     = metrics[i] as Map;
    final type  = (m['type']  as String?) ?? '';
    final value = m['value'];
    final unit  = (m['unit']  as String?) ?? '';
    final label = _metricLabel(l, type);
    final formatted = _metricFormatted(l, type, value, unit);
    final bg = i.isEven ? _kBg : PdfColors.white;

    rows.add(pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: pw.Text(_p(label),
              style: pw.TextStyle(font: regular, fontSize: 9.5, color: _kText)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: pw.Text(_p(formatted),
              style: pw.TextStyle(font: bold, fontSize: 9.5, color: _kText)),
        ),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: _kBorder, width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(2),
    },
    children: rows,
  );
}

pw.Widget _footer(AppLocalizations l, pw.Font regular, String submissionId) {
  return pw.Container(
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _kBorder)),
    ),
    padding: const pw.EdgeInsets.only(top: 8),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(_p(l.pdfGeneratedBy),
            style: pw.TextStyle(font: regular, fontSize: 8, color: _kMuted)),
        pw.Text('ID: $submissionId',
            style: pw.TextStyle(font: regular, fontSize: 8, color: _kMuted)),
      ],
    ),
  );
}

String _metricLabel(AppLocalizations l, String type) => switch (type) {
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

String _metricFormatted(AppLocalizations l, String type, dynamic value, String unit) {
  if (value == null) return '-';
  switch (type) {
    case 'step_count':               return '${(value as num).round()} ${l.unitSteps}';
    case 'flights_climbed':          return '${(value as num).round()} ${l.unitFloors}';
    case 'heart_rate':
    case 'resting_heart_rate':       return '${(value as num).round()} bpm';
    case 'sleep_duration':           return '${(value as num).toStringAsFixed(1)} h';
    case 'active_energy_burned':     return '${(value as num).round()} kcal';
    case 'walking_speed':            return '${(value as num).toStringAsFixed(1)} km/h';
    case 'distance_walking_running': return '${(value as num).toStringAsFixed(2)} km';
    case 'walking_step_length':      return '${((value as num) * 100).toStringAsFixed(0)} cm';
    case 'walking_asymmetry':
    case 'walking_double_support':
    case 'walking_steadiness':       return '${(value as num).toStringAsFixed(1)} %';
    case 'headphone_audio_exposure': return '${(value as num).toStringAsFixed(1)} dB';
    default:                         return '$value $unit'.trim();
  }
}
