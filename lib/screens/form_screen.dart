import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'review_screen.dart';

class FormScreen extends StatefulWidget {
  final HealthService healthService;
  final bool healthGranted;

  const FormScreen({
    super.key,
    required this.healthService,
    required this.healthGranted,
  });

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _commentController = TextEditingController();

  String? _ageRange;
  int _rating = 3;

  static const _ageRanges = [
    '18–24', '25–34', '35–44', '45–54', '55–64', '65+'
  ];

  @override
  void dispose() {
    _idController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          healthService: widget.healthService,
          healthGranted: widget.healthGranted,
          participantId: _idController.text.trim(),
          ageRange: _ageRange!,
          wellbeingRating: _rating,
          comment: _commentController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaire')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Your Information', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Participant ID',
                hintText: 'e.g. P-001',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your participant ID' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _ageRange,
              decoration: const InputDecoration(
                labelText: 'Age Range',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              items: _ageRanges
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _ageRange = v),
              validator: (v) => v == null ? 'Please select your age range' : null,
            ),
            const SizedBox(height: 28),
            Text('Wellbeing Rating', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'How do you feel today overall? (1 = very poor, 5 = excellent)',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _RatingSelector(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 28),
            Text('Comments', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Short comment (optional)',
                hintText: 'e.g. Felt energetic in the morning.',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _onContinue,
              child: const Text('Review & Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingSelector({required this.value, required this.onChanged});

  static const _labels = {1: 'Very Poor', 2: 'Poor', 3: 'Fair', 4: 'Good', 5: 'Excellent'};
  static const _colors = {
    1: Color(0xFFD32F2F),
    2: Color(0xFFF57C00),
    3: Color(0xFFFBC02D),
    4: Color(0xFF388E3C),
    5: Color(0xFF1B5E20),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final n = i + 1;
            final selected = n == value;
            final color = _colors[n]!;
            return GestureDetector(
              onTap: () => onChanged(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? color : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? color : color.withValues(alpha: 0.4),
                    width: selected ? 2.5 : 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _labels[value]!,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _colors[value],
          ),
        ),
      ],
    );
  }
}
