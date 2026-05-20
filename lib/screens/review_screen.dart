import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/submission.dart';
import '../services/api_service.dart';
import '../services/health_service.dart';
import 'result_screen.dart';

class ReviewScreen extends StatefulWidget {
  final HealthService healthService;
  final bool healthGranted;
  final String participantId;
  final String ageRange;
  final int wellbeingRating;
  final String comment;

  const ReviewScreen({
    super.key,
    required this.healthService,
    required this.healthGranted,
    required this.participantId,
    required this.ageRange,
    required this.wellbeingRating,
    required this.comment,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int? _steps;
  bool _loadingSteps = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSteps();
  }

  Future<void> _fetchSteps() async {
    if (widget.healthGranted) {
      final steps = await widget.healthService.getTodaySteps();
      if (mounted) setState(() => _steps = steps);
    }
    if (mounted) setState(() => _loadingSteps = false);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final submission = Submission(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      participantId: widget.participantId,
      ageRange: widget.ageRange,
      wellbeingRating: widget.wellbeingRating,
      comment: widget.comment,
      stepCount: _steps,
    );

    final payload = const JsonEncoder.withIndent('  ').convert(submission.toJson());
    final success = await ApiService().submit(submission);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(success: success, payload: payload),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Please confirm your data before submitting.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Participant',
            icon: Icons.badge_outlined,
            children: [
              _Row('ID', widget.participantId),
              _Row('Age Range', widget.ageRange),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Wellbeing',
            icon: Icons.self_improvement_rounded,
            children: [
              _Row('Rating', '${widget.wellbeingRating} / 5'),
              if (widget.comment.isNotEmpty) _Row('Comment', widget.comment),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Health Metrics',
            icon: Icons.directions_walk_rounded,
            children: [
              if (_loadingSteps)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (!widget.healthGranted)
                _Row('Steps today', 'Permission not granted')
              else
                _Row('Steps today', _steps != null ? '$_steps steps' : 'No data available'),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: (_submitting || _loadingSteps) ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit'),
          ),
          const SizedBox(height: 12),
          Text(
            'Data will be sent to a mock research endpoint (httpbin.org).',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: tt.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ),
          Expanded(child: Text(value, style: tt.bodyMedium)),
        ],
      ),
    );
  }
}
