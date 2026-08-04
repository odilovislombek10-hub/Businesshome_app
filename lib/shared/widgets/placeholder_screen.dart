import 'package:flutter/material.dart';

/// Stand-in for a route that exists on businesshome.uz but has not been ported yet.
///
/// Every website route is wired into the router from the start so navigation, deep links and the
/// URL scheme match the site immediately; screens then replace these one by one. Keeping the route
/// live (instead of omitting it) means a link from an already-ported screen never dead-ends.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.note});

  final String title;

  /// What the corresponding page does on the site — shown so the gap is self-documenting.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_outlined, size: 44, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Tayyorlanmoqda', style: theme.textTheme.titleMedium),
              if (note != null) ...[
                const SizedBox(height: 8),
                Text(
                  note!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
