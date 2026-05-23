import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/health_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
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

  static const _ageRanges = ['18–24', '25–34', '35–44', '45–54', '55–64', '65+'];

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
      AppPageRoute(
        page: ReviewScreen(
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
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.formTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FadeSlideIn(
              child: Text(l.yourInformation,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: l.participantId,
                  hintText: l.participantIdHint,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.participantIdError : null,
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: DropdownButtonFormField<String>(
                initialValue: _ageRange,
                decoration: InputDecoration(
                  labelText: l.ageRange,
                  prefixIcon: const Icon(Icons.person_outlined),
                ),
                items: _ageRanges
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _ageRange = v),
                validator: (v) => v == null ? l.ageRangeError : null,
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Text(l.wellbeingRating,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Text(
                l.wellbeingQuestion,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: _RatingSelector(
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
                l: l,
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: Text(l.comments,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              child: TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: l.commentLabel,
                  hintText: l.commentHint,
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: FilledButton(
                onPressed: _onContinue,
                child: Text(l.reviewAndSubmit),
              ),
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
  final AppLocalizations l;

  const _RatingSelector({required this.value, required this.onChanged, required this.l});

  static const _colors = {
    1: Color(0xFFD32F2F),
    2: Color(0xFFF57C00),
    3: Color(0xFFFBC02D),
    4: Color(0xFF388E3C),
    5: Color(0xFF1B5E20),
  };

  String _label(int n) => switch (n) {
        1 => l.ratingVeryPoor,
        2 => l.ratingPoor,
        3 => l.ratingFair,
        4 => l.ratingGood,
        _ => l.ratingExcellent,
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
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: selected ? 58 : 52,
                height: selected ? 58 : 52,
                decoration: BoxDecoration(
                  color: selected ? color : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? color : color.withValues(alpha: 0.4),
                    width: selected ? 2.5 : 1.5,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _label(value),
            key: ValueKey(value),
            style: TextStyle(fontWeight: FontWeight.w600, color: _colors[value]),
          ),
        ),
      ],
    );
  }
}
