import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'welcome_screen.dart';

class ResultScreen extends StatelessWidget {
  final bool success;
  final String payload;

  const ResultScreen({super.key, required this.success, required this.payload});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Submission')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 72,
            color: success ? Colors.green : cs.error,
          ),
          const SizedBox(height: 16),
          Text(
            success ? 'Data Submitted' : 'Submission Failed',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            success
                ? 'Your data was successfully sent to the research endpoint.'
                : 'Could not reach the endpoint. Check your connection and try again.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('JSON Payload', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy to clipboard',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payload));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              payload,
              style: tt.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (_) => false,
            ),
            child: const Text('Start Over'),
          ),
        ],
      ),
    );
  }
}
