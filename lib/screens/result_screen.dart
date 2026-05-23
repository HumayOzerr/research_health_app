import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import 'welcome_screen.dart';

class ResultScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    final IconData icon;
    final Color iconColor;
    final String title;
    final String message;

    if (success) {
      icon = Icons.check_circle_rounded;
      iconColor = Colors.green;
      title = l.resultSuccessTitle;
      message = l.resultSuccessMessage;
    } else if (queued) {
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

    return Scaffold(
      appBar: AppBar(title: Text(l.resultTitle)),
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
          if (queued) ...[
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: cs.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      l.resultQueuedNote,
                      style: tt.labelSmall?.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.jsonPayload,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: l.copyToClipboard,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: payload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.copied)),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: Container(
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
          ),
          const SizedBox(height: 32),
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
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
