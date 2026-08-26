import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';

/// Empty/failed state with a retry action — the site shows the same pattern when a section's
/// request fails, and printing the real reason is what makes network and API-shape problems
/// diagnosable instead of a generic "something went wrong".
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: Text(t('panorama.retry'))),
          ],
        ),
      ),
    );
  }
}
