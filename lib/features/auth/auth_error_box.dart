import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Inline error banner used across the auth screens.
///
/// It prints the backend's own `detail` string rather than a generic message — those texts
/// ("Telefon yoki parol noto'g'ri", "Kod noto'g'ri yoki muddati o'tgan") are already written for
/// the end user, and replacing them would lose the reason.
class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          message!,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}
